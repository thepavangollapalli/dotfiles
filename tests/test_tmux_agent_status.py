"""Exercise the real status formats on an isolated tmux server (tmux 3.8+)."""

import fcntl
import os
from pathlib import Path
import pty
import select
import shutil
import struct
import subprocess
import tempfile
import termios
import time
import unittest


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

    def test_waiting_color_and_return_to_normal_preserve_topic(self):
        self.assertIn('1:window naming', self.label())
        self.assertNotIn('colour214', self.label())
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'waiting')
        self.assertIn('#[fg=colour214]', self.label())
        self.assertIn('ℹ 1:window naming', self.label())
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
        self.assertNotIn('colour214', self.label())
        self.assertIn('#[fg=colour81]', self.label())
        self.tmux('set-option', '-pu', '-t', self.pane, '@agent_state')
        self.assertNotIn('colour81', self.label())
        self.assertEqual(self.tmux('display-message', '-p', '#W').strip(), 'window naming')

    def test_waiting_sibling_is_visible_and_state_moves_with_its_pane(self):
        sibling = self.tmux('split-window', '-d', '-P', '-F', '#{pane_id}', 'sleep 120').strip()
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
        self.tmux('set-option', '-p', '-t', sibling, '@agent_state', 'waiting')
        self.assertIn('colour214', self.label())
        target = self.tmux('new-window', '-d', '-P', '-F', '#{window_id}', '-n', 'other work', 'sleep 120').strip()
        self.tmux('join-pane', '-d', '-s', sibling, '-t', target)
        self.assertNotIn('colour214', self.label())
        other = self.tmux('display-message', '-p', '-t', target, '#{E:window-status-format}')
        self.assertIn('colour214', other)
        self.assertIn('other work', other)

    def test_running_indicator_animates_in_an_attached_status_bar(self):
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
        master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 140, 0, 0))
        client = subprocess.Popen(['tmux', '-S', self.socket, 'attach-session', '-t', 'test'],
                                  stdin=slave, stdout=slave, stderr=slave, env=self.environment)
        os.close(slave)
        try:
            for turn in range(2):
                self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
                captured = b''
                deadline = time.monotonic() + 2
                while time.monotonic() < deadline:
                    if select.select([master], [], [], 0.2)[0]:
                        captured += os.read(master, 65536)
                frames = set('⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏') & set(captured.decode(errors='replace'))
                self.assertGreaterEqual(len(frames), 2, captured.decode(errors='replace'))
                self.assertIn('window naming', self.label())
                self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'waiting')
                self.assertIn('ℹ', self.label())
                # Click the already selected status label, then the pane itself.
                column, row = (8, 24) if turn == 0 else (1, 1)
                os.write(master, f'\x1b[<0;{column};{row}M\x1b[<0;{column};{row}m'.encode())
                deadline = time.monotonic() + 2
                while 'ℹ' in self.label() and time.monotonic() < deadline:
                    time.sleep(0.05)
                self.assertNotIn('ℹ', self.label())
        finally:
            client.terminate()
            client.wait(timeout=5)
            os.close(master)

    def test_viewing_window_clears_waiting_panes_and_preserves_running_panes(self):
        waiting = self.tmux('split-window', '-d', '-P', '-F', '#{pane_id}', 'sleep 120').strip()
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'running')
        self.tmux('set-option', '-p', '-t', waiting, '@agent_state', 'waiting')
        other = self.tmux('new-window', '-d', '-P', '-F', '#{window_id}', 'sleep 120').strip()
        self.tmux('set-option', '-p', '-t', other, '@agent_state', 'waiting')
        self.tmux('select-window', '-t', other)
        self.tmux('set-option', '-p', '-t', other, '@agent_state', 'waiting')
        self.tmux('select-window', '-t', self.pane)
        self.assertEqual(self.tmux('display-message', '-p', '-t', waiting, '#{@agent_state}').strip(), '')
        self.assertEqual(self.tmux('display-message', '-p', '-t', self.pane, '#{@agent_state}').strip(), 'running')
        self.assertEqual(self.tmux('display-message', '-p', '-t', other, '#{@agent_state}').strip(), 'waiting')
        self.assertNotIn('colour214', self.label())
        # Switching panes also acknowledges a later notice in the same window.
        self.tmux('set-option', '-p', '-t', self.pane, '@agent_state', 'waiting')
        self.tmux('select-pane', '-t', waiting)
        self.assertEqual(self.tmux('display-message', '-p', '-t', self.pane, '#{@agent_state}').strip(), '')


if __name__ == '__main__':
    unittest.main()
