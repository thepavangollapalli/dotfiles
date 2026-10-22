"""Exercise the real status formats on an isolated tmux server (tmux 3.8+)."""

import fcntl
import os
from pathlib import Path
import pty
import re
import select
import shlex
import shutil
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest

DONE_CHIP = '#[bg=#3e4452]'
REQUEST_CHIP = '#[bg=#e5c07b]'
SPINNER_FRAMES = '⣾⣽⣻⢿⡿⣟⣯⣷'


@unittest.skipUnless(shutil.which('tmux'), 'tmux is required')
class AgentStatusTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='tmux-status-')
        self.addCleanup(self.temporary.cleanup)
        directory = Path(self.temporary.name)
        self.socket = str(directory / 'socket')
        self.environment = dict(os.environ, HOME=str(directory), TERM='xterm-256color')
        self.environment.pop('TMUX', None)
        self.environment.pop('TMUX_PANE', None)
        # The full config loads TPM. Stub it in the isolated home so tests never
        # run the real user's plugins or session restoration.
        plugin = directory / '.tmux/plugins/tpm/tpm'
        plugin.parent.mkdir(parents=True)
        plugin.write_text('#!/bin/sh\nexit 0\n')
        plugin.chmod(0o755)
        config = Path(__file__).resolve().parents[1] / 'home/.tmux.conf'
        self.tmux('-f', str(config), 'new-session', '-d', '-s', 'test', '-n', 'window naming', 'sleep 120')
        self.addCleanup(self.tmux, 'kill-server')
        self.pane = self.tmux('display-message', '-p', '#{pane_id}').strip()

    def tmux(self, *arguments):
        return subprocess.check_output(['tmux', '-S', self.socket, *arguments],
                                       env=self.environment, text=True, stderr=subprocess.PIPE, timeout=5)

    def label(self):
        return self.tmux('display-message', '-p', '#{E:window-status-current-format}')

    def test_done_color_and_return_to_normal_preserve_topic(self):
        self.assertIn('window naming', self.label())
        self.assertNotIn(DONE_CHIP, self.label())
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'done')
        self.assertIn(DONE_CHIP, self.label())
        self.assertIn('window naming', self.label())
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
        self.assertNotIn(DONE_CHIP, self.label())
        self.tmux('set-option', '-pu', '-t', self.pane, '@agent_state')
        self.assertNotIn(DONE_CHIP, self.label())
        self.assertEqual(self.tmux('display-message', '-p', '#W').strip(), 'window naming')

    def test_done_sibling_is_visible_and_state_moves_with_its_pane(self):
        sibling = self.tmux('split-window', '-d', '-P', '-F', '#{pane_id}', 'sleep 120').strip()
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
        self.tmux('set-option', '-p', '-t', sibling, '@agent_state', 'done')
        self.assertIn(DONE_CHIP, self.label())
        target = self.tmux('new-window', '-d', '-P', '-F', '#{window_id}', '-n', 'other work', 'sleep 120').strip()
        self.tmux('join-pane', '-d', '-s', sibling, '-t', target)
        self.assertNotIn(DONE_CHIP, self.label())
        other = self.tmux('display-message', '-p', '-t', target, '#{E:window-status-format}')
        self.assertIn(DONE_CHIP, other)
        self.assertIn('other work', other)

    def test_request_outranks_done_and_survives_viewing(self):
        sibling = self.tmux('split-window', '-d', '-P', '-F', '#{pane_id}', 'sleep 120').strip()
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'done')
        self.tmux('set-option', '-p', '-t', sibling, '@agent_state', 'needs_input')
        self.assertIn(REQUEST_CHIP, self.label())
        self.assertNotIn(DONE_CHIP, self.label())
        self.tmux('select-pane', '-t', sibling)
        self.assertEqual(self.tmux('display-message', '-p', '-t', self.pane, '#{@agent_state}').strip(), '')
        self.assertEqual(self.tmux('display-message', '-p', '-t', sibling, '#{@agent_state}').strip(), 'needs_input')
        self.assertIn(REQUEST_CHIP, self.label())
        self.tmux('set-option', '-p', '-t', sibling, '@agent_state', 'running')
        self.assertNotIn(REQUEST_CHIP, self.label())

    def test_windows_take_accents_from_their_index(self):
        self.assertIn('#[bg=#c678dd]', self.label())
        target = self.tmux('new-window', '-d', '-P', '-F', '#{window_id}', '-n', 'other work', 'sleep 120').strip()
        other = self.tmux('display-message', '-p', '-t', target, '#{E:window-status-format}')
        self.assertIn('#[fg=#98c379]other work', other)

    def test_window_accents_stay_distinct_from_notice_amber(self):
        for index in range(2, 7):
            self.tmux('new-window', '-d', '-t', f':{index}', 'sleep 120')
            label = self.tmux('display-message', '-p', '-t', f':{index}', '#{E:window-status-format}')
            # Notice amber, its dim index color, and One Dark orange all read as one hue.
            self.assertNotRegex(label, '#e5c07b|#d19a66|#b8975a')

    def test_agent_indicators_animate_in_an_attached_status_bar(self):
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 140, 0, 0))
        client = subprocess.Popen(['tmux', '-S', self.socket, 'attach-session', '-t', 'test'],
                                  stdin=slave, stdout=slave, stderr=slave, env=self.environment)
        os.close(slave)

        def read_terminal():
            captured = b''
            deadline = time.monotonic() + 2.5
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.2)[0]:
                    captured += os.read(master, 65536)
            return captured.decode(errors='replace')

        def glyph_colors(glyphs, text):
            return set(re.findall(r'\x1b\[38;2;([0-9;]+)m[%s]' % glyphs, text))

        try:
            # A background spinner takes its window's green accent. A request pulses,
            # and a finished turn holds one still check.
            other = self.tmux('new-window', '-d', '-P', '-F', '#{pane_id}', 'sleep 120').strip()
            self.tmux('set-option', '-p', '-t', other, '@agent_state', 'running')
            self.assertIn('152;195;121', glyph_colors(SPINNER_FRAMES, read_terminal()))
            self.tmux('set-option', '-p', '-t', other, '@agent_state', 'done')
            text = read_terminal()
            self.assertIn('\x1b[38;2;152;195;121m\x1b[1m✓', text)
            self.assertNotIn('●', text)
            self.tmux('set-option', '-p', '-t', other, '@agent_state', 'needs_input')
            self.assertGreaterEqual(len(glyph_colors('●', read_terminal())), 2)
            # Click the selected status label, then the pane itself.
            for column, row in ((8, 24), (1, 1)):
                self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
                text = read_terminal()
                self.assertGreaterEqual(len(set(SPINNER_FRAMES) & set(text)), 2, text)
                self.assertIn('window naming', self.label())
                self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'done')
                self.assertIn(DONE_CHIP, self.label())
                os.write(master, f'\x1b[<0;{column};{row}M\x1b[<0;{column};{row}m'.encode())
                deadline = time.monotonic() + 2
                while DONE_CHIP in self.label() and time.monotonic() < deadline:
                    time.sleep(0.05)
                self.assertNotIn(DONE_CHIP, self.label())
        finally:
            client.terminate()
            client.wait(timeout=5)
            os.close(master)

    def test_viewing_window_clears_done_panes_and_preserves_running_panes(self):
        done = self.tmux('split-window', '-d', '-P', '-F', '#{pane_id}', 'sleep 120').strip()
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
        self.tmux('set-option', '-p', '-t', done, '@agent_state', 'done')
        other = self.tmux('new-window', '-d', '-P', '-F', '#{window_id}', 'sleep 120').strip()
        self.tmux('set-option', '-p', '-t', other, '@agent_state', 'done')
        self.tmux('select-window', '-t', other)
        self.tmux('set-option', '-p', '-t', other, '@agent_state', 'done')
        self.tmux('select-window', '-t', self.pane)
        self.assertEqual(self.tmux('display-message', '-p', '-t', done, '#{@agent_state}').strip(), '')
        self.assertEqual(self.tmux('display-message', '-p', '-t', self.pane, '#{@agent_state}').strip(), 'running')
        self.assertEqual(self.tmux('display-message', '-p', '-t', other, '#{@agent_state}').strip(), 'done')
        self.assertNotIn(DONE_CHIP, self.label())
        # Switching panes also acknowledges a later notice in the same window.
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'done')
        self.tmux('select-pane', '-t', done)
        self.assertEqual(self.tmux('display-message', '-p', '-t', self.pane, '#{@agent_state}').strip(), '')

    def test_mouse_input_reaches_app_unless_copy_mode_is_explicitly_opened(self):
        directory = Path(self.temporary.name)
        received = directory / 'input'
        application = directory / 'mouse_app.py'
        application.write_text('''import os, sys, tty
tty.setraw(sys.stdin.fileno())
os.write(1, b"history line\\r\\n" * 100)
os.write(1, b"\\x1b[?1002h\\x1b[?1006h")
with open(sys.argv[1], "wb", buffering=0) as received:
    while True:
        received.write(os.read(0, 4096))
''')
        self.tmux('respawn-pane', '-k', '-t', self.pane,
                  shlex.join([sys.executable, str(application), str(received)]))

        def pane_format(value):
            return self.tmux('display-message', '-p', '-t', self.pane, value).strip()

        def wait_for(predicate):
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline:
                if predicate():
                    return
                time.sleep(0.02)
            self.fail('Timed out waiting for mouse input or pane state')

        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 100, 0, 0))
        client = subprocess.Popen(['tmux', '-S', self.socket, 'attach-session', '-t', 'test'],
                                  stdin=slave, stdout=slave, stderr=slave, env=self.environment)
        os.close(slave)
        try:
            wait_for(lambda: pane_format('#{mouse_any_flag}') == '1' and received.exists())
            # Real terminal events exercise dispatch, including drag start/end.
            events = [b'\x1b[<64;10;5M', b'\x1b[<65;10;5M', b'\x1b[<0;3;5M',
                      b'\x1b[<32;15;5M', b'\x1b[<0;15;5m', b'hello']
            for event in events:
                os.write(master, event)
                wait_for(lambda: event in received.read_bytes())
                self.assertEqual(pane_format('#{pane_in_mode}'), '0')

            # Explicit tmux history retains priority until the user leaves it.
            os.write(master, b'\x01[')
            wait_for(lambda: pane_format('#{pane_in_mode}') == '1')
            os.write(master, b'\x1b[<64;10;5M')
            wait_for(lambda: int(pane_format('#{scroll_position}')) > 0)
            self.tmux('send-keys', '-X', '-t', self.pane, 'cancel')

            # Once the app exits, ordinary shell-style selection still works.
            self.tmux('respawn-pane', '-k', '-t', self.pane, 'sleep 120')
            wait_for(lambda: pane_format('#{mouse_any_flag}') == '0')
            os.write(master, b'\x1b[<0;3;5M\x1b[<32;15;5M')
            wait_for(lambda: pane_format('#{selection_present}') == '1')
            self.assertEqual(pane_format('#{pane_in_mode}'), '1')
            os.write(master, b'\x1b[<0;15;5m')
        finally:
            client.terminate()
            client.wait(timeout=5)
            os.close(master)


if __name__ == '__main__':
    unittest.main()
