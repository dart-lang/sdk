#!/usr/bin/env python3
#
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code == governed by a
# BSD-style license that can be found in the LICENSE file.

import abc
import argparse
import os
import shutil
import subprocess
import sys

from enum import Enum
from enum import unique

from subprocess import DEVNULL
from subprocess import PIPE
from subprocess import Popen
from subprocess import STDOUT
from subprocess import TimeoutExpired

from tempfile import mkdtemp

#
# Helper methods to run commands.
#

@unique
class RetCode(Enum):
  """Enum representing return codes."""
  SUCCESS = 0
  TIMEOUT = 1
  ERROR = 2

class FatalError(Exception):
  """Fatal error in script."""

def RunCommandWithOutput(cmd, env, stdout, stderr, timeout=30):
  """Runs command piping output to files, stderr, or stdout.

  Args:
    cmd: list of strings, command to run.
    env: shell environment for command.
    stdout: file handle for stdout.
    stderr: file handle for stderr.
    timeout: int, timeout in seconds.

  Returns:
    tuple (string, string, RetCode) out, err, return code.
  """
  proc = Popen(cmd, stdout=stdout, stderr=stderr, env=env,
               universal_newlines=True, start_new_session=True)
  try:
    (out, err) = proc.communicate(timeout=timeout)
    if proc.returncode == 0:
      retcode = RetCode.SUCCESS
    else:
      retcode = RetCode.ERROR
  except TimeoutExpired:
    os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
    (out, err) = proc.communicate()
    retcode = RetCode.TIMEOUT
  return (out, err, retcode)

def RunCommand(cmd, out=None, err=None, timeout=30):
  """Executes a command, and returns its return code.

  Args:
    cmd: list of strings, a command to execute.
    out: string, file name to open for stdout (or None).
    err: string, file name to open for stderr (or None).
    timeout: int, time out in seconds.
  Returns:
    RetCode, return code of running command.
  """
  if out is not None:
    outf = open(out, mode='w')
  else:
    outf = DEVNULL
  if err is not None:
    errf = open(err, mode='w')
  else:
    errf = DEVNULL
  (_, _, retcode) = RunCommandWithOutput(cmd, None, outf, errf, timeout)
  if outf != DEVNULL:
    outf.close()
  if errf != DEVNULL:
    errf.close()
  return retcode

#
# Execution modes.
#

class TestRunner(object):
  """Abstraction for running a test in a particular execution mode."""
  __meta_class__ = abc.ABCMeta

  @abc.abstractproperty
  def description(self):
    """Returns a description string of the execution mode."""

  @abc.abstractmethod
  def RunTest(self):
    """Run the generated test.

    Ensures that the current fuzz.dart in the temporary directory is executed
    under the current execution mode.

    Most nonzero return codes are assumed non-divergent, since systems may
    exit in different ways. This is enforced by normalizing return codes.

    Returns:
      tuple (string, string, RetCode) stdout-output, stderr-output, return code.
    """

class TestRunnerDartJIT(TestRunner):
  """Concrete test runner of Dart JIT."""

  @property
  def description(self):
    return 'Dart JIT'

  def RunTest(self):
    return RunCommandWithOutput(['dart', 'fuzz.dart'], None, PIPE, STDOUT)

class TestRunnerDartAOT(TestRunner):
  """Concrete test runner of Dart AOT."""

  @property
  def description(self):
    return 'Dart AOT'

  def RunTest(self):
    (out, err, retcode) = RunCommandWithOutput(
        ['precompiler2', 'fuzz.dart', 'snap'], None, PIPE, STDOUT)
    if retcode != RetCode.SUCCESS:
      return (out, err, retcode)
    return RunCommandWithOutput(['dart_precompiled_runtime2', 'snap'], None, PIPE, STDOUT)

class TestRunnerDart2JS(TestRunner):
  """Concrete test runner of Dart through dart2js and JS."""

  @property
  def description(self):
    return 'Dart as JS'

  def RunTest(self):
    (out, err, retcode) = RunCommandWithOutput(['dart2js', 'fuzz.dart'], None, PIPE, STDOUT)
    if retcode != RetCode.SUCCESS:
      return (out, err, retcode)
    return RunCommandWithOutput(['nodejs', 'out.js'], None, PIPE, STDOUT)

def GetExecutionModeRunner(mode):
  """Returns a runner for the given execution mode.

  Args:
    mode: string, execution mode
  Returns:
    TestRunner with given execution mode
  Raises:
    FatalError: error for unknown execution mode
  """
  if mode == 'jit':
    return TestRunnerDartJIT()
  if mode == 'aot':
    return TestRunnerDartAOT()
  if mode == 'js':
    return TestRunnerDart2JS()
  raise FatalError('Unknown execution mode')

#
# DartFuzzTester class.
#

class DartFuzzTester(object):
  """Tester that runs DartFuzz many times and report divergences."""

  def  __init__(self, repeat, true_divergence, mode1, mode2):
    """Constructor for the tester.

    Args:
      repeat: int, number of tests to run.
      true_divergence: boolean, report true divergences only.
      mode1: string, execution mode for first runner.
      mode2: string, execution mode for second runner.
    """
    self._repeat = repeat
    self._true_divergence = true_divergence
    self._runner1 = GetExecutionModeRunner(mode1)
    self._runner2 = GetExecutionModeRunner(mode2)

  def __enter__(self):
    """On entry, enters new temp directory after saving current directory.

    Raises:
      FatalError: error when temp directory cannot be constructed.
    """
    self._save_dir = os.getcwd()
    self._tmp_dir = mkdtemp(dir='/tmp/')
    if self._tmp_dir == None:
      raise FatalError('Cannot obtain temp directory')
    os.chdir(self._tmp_dir)
    return self

  def __exit__(self, etype, evalue, etraceback):
    """On exit, re-enters previously saved current directory and cleans up."""
    os.chdir(self._save_dir)
    if self._num_divergences == 0:
      shutil.rmtree(self._tmp_dir)
      print('\n\nsuccess (no divergences)\n')
    else:
      print('\n\nfailure (divergences):', self._tmp_dir, '\n')

  def Run(self):
    """Runs DartFuzz many times and report divergences."""
    self.Setup()
    print()
    print('**\n**** Dart Fuzz Testing\n**')
    print()
    print('#Tests      :', self._repeat)
    print('Exec-Mode 1 :', self._runner1.description)
    print('Exec-Mode 2 :', self._runner2.description)
    print()
    self.ShowStats()  # show all zeros on start
    for self._test in range(1, self._repeat + 1):
      self.RunTest()
      self.ShowStats()

  def Setup(self):
    """Initial setup of the testing environment."""
    # Fuzzer command.
    self._dartfuzz = self._save_dir + '/dartfuzz.py'
    # Statistics.
    self._test = 0
    self._num_success = 0
    self._num_not_run = 0
    self._num_timed_out = 0
    self._num_divergences = 0

  def ShowStats(self):
    """Shows current statistics (on same line) while tester is running."""
    print('\rTests:', self._test,
          'Success:', self._num_success,
          'Not-run:', self._num_not_run,
          'Timed-out:', self._num_timed_out,
          'Divergences:', self._num_divergences,
          end='')
    sys.stdout.flush()

  def RunTest(self):
    """Runs a single fuzz test, comparing two execution modes."""
    self.ConstructTest()
    (out1, _, retcode1) = self._runner1.RunTest()
    (out2, _, retcode2) = self._runner2.RunTest()
    self.CheckForDivergence(out1, retcode1, out2, retcode2)
    self.CleanupTest()

  def ConstructTest(self):
    """Use DartFuzz to generate next fuzz.dart test.

    Raises:
      FatalError: error when DartFuzz fails.
    """
    # Invoke dartfuzz script on command line rather than calling py code.
    if (RunCommand([self._dartfuzz], out='fuzz.dart') != RetCode.SUCCESS):
      raise FatalError('Unexpected error while running DartFuzz')

  def CheckForDivergence(self, out1, retcode1, out2, retcode2):
    """Checks for divergences and updates statistics.

    Args:
      out1: string, output for first runner.
      retcode1: int, normalized return code of first runner.
      out2: string, output for second runner.
      retcode2: int, normalized return code of second runner.
    """
    if retcode1 == retcode2:
      # No divergence in return code.
      if retcode1 == RetCode.SUCCESS:
        # Both compilations and runs were successful, inspect generated output.
        if out1 == out2:
          # No divergence in output.
          self._num_success += 1
        else:
          # Divergence in output.
          self.ReportDivergence(out1, retcode1, out2, retcode2, True)
      elif retcode1 == RetCode.ERROR:
        # Both did not run.
        self._num_not_run += 1
      elif retcode1 == RetCode.TIMEOUT:
        # Both timed out.
        self._num_timed_out += 1
      else:
       raise FatalError('Unknown return code')
    else:
      # Divergence in return code.
      if self._true_divergence:
        # When only true divergences are requested, any divergence in return
        # code where one is a time out is treated as a regular time out.
        if RetCode.TIMEOUT in (retcode1, retcode2):
          self._num_timed_out += 1
          return
      self.ReportDivergence(out1, retcode1, out2, retcode2, False)

  def ReportDivergence(self, out1, retcode1, out2, retcode2, is_output_divergence):
    """Reports and saves a divergence.

    Args:
      out1: string, output for first runner.
      retcode1: int, normalized return code of first runner.
      out2: string, output for second runner.
      retcode2: int, normalized return code of second runner.
      is_output_divergence, boolean, denotes output divergence.
      """
    self._num_divergences += 1
    print('\n#' + str(self._num_divergences), end='')
    if is_output_divergence:
      print(' divergence in output')
    else:
      print(' divergence in return code: '
            + retcode1.name + ' vs. ' + retcode2.name)
    print('->')
    print(out1, end='')
    print('<-')
    print(out2, end='')
    print('--')
    # Save.
    ddir = self._tmp_dir + '/divergence' + str(self._num_divergences)
    os.mkdir(ddir)
    shutil.copy('fuzz.dart', ddir)
    # TODO: file bug report

  def CleanupTest(self):
    """Cleans up after a single test run."""
    for file_name in os.listdir(self._tmp_dir):
      file_path = os.path.join(self._tmp_dir, file_name)
      if os.path.isfile(file_path):
        os.unlink(file_path)
      elif os.path.isdir(file_path):
        pass  # keep the divergences directories

#
# Main driver.
#

def main():
  # Handle arguments.
  parser = argparse.ArgumentParser()
  parser.add_argument('--repeat', default=1000, type=int,
                      help='number of tests to run (default: 1000)')
  parser.add_argument('--true_divergence', default=False, action='store_true',
                      help='only report true divergences')
  parser.add_argument('--mode1', default='jit',
                      help='execution mode 1 (default: jit)')
  parser.add_argument('--mode2', default='aot',
                      help='execution mode 2 (default: aot)')
  args = parser.parse_args()

  # Run DartFuzz tester.
  with DartFuzzTester(args.repeat,
                      args.true_divergence,
                      args.mode1,
                      args.mode2) as fuzzer:
    fuzzer.Run()

if __name__ == '__main__':
  main()
