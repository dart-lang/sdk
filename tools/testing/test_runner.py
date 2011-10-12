# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
"""Classes and methods for executing tasks for the test.py framework.

This module includes:
  - Managing parallel execution of tests using threads
  - Windows and Unix specific code for spawning tasks and retrieving results
  - Evaluating the output of each test as  pass/fail/crash/timeout
"""

import ctypes
import os
import Queue
import signal
import subprocess
import sys
import tempfile
import threading
import time
import traceback

import testing
import utils


class Error(Exception):
  pass


class CommandOutput(object):
  """Represents the output of running a command."""

  def __init__(self, pid, exit_code, timed_out, stdout, stderr):
    self.pid = pid
    self.exit_code = exit_code
    self.timed_out = timed_out
    self.stdout = stdout
    self.stderr = stderr
    self.failed = None


class TestOutput(object):
  """Represents the output of running a TestCase."""

  def __init__(self, test, command, output):
    """Represents the output of running a TestCase.

    Args:
      test: A TestCase instance.
      command: the command line that was run
      output: A CommandOutput instance.
    """
    self.test = test
    self.command = command
    self.output = output

  def UnexpectedOutput(self):
    """Compare the result of running the expected from the TestConfiguration.

    Returns:
      True if the test had an unexpected output.
    """
    if self.HasCrashed():
      outcome = testing.CRASH
    elif self.HasTimedOut():
      outcome = testing.TIMEOUT
    elif self.HasFailed():
      outcome = testing.FAIL
    else:
      outcome = testing.PASS
    return not outcome in self.test.outcomes

  def HasCrashed(self):
    """Returns True if the test should be considered testing.CRASH."""
    if utils.IsWindows():
      if self.output.exit_code == 3:
        # The VM uses std::abort to terminate on asserts.
        # std::abort terminates with exit code 3 on Windows.
        return True
      return (0x80000000 & self.output.exit_code
              and not 0x3FFFFF00 & self.output.exit_code)
    else:
      # Timed out tests will have exit_code -signal.SIGTERM.
      if self.output.timed_out:
        return False
      if self.output.exit_code == 253:
        # The Java dartc runners exit 253 in case of unhandled exceptions.
        return True
      return self.output.exit_code < 0

  def HasTimedOut(self):
    """Returns True if the test should be considered as testing.TIMEOUT."""
    return self.output.timed_out

  def HasFailed(self):
    """Returns True if the test should be considered as testing.FAIL."""
    execution_failed = self.test.DidFail(self.output)
    if self.test.IsNegative():
      return not execution_failed
    else:
      return execution_failed


def Execute(args, context, timeout=None, cwd=None):
  """Executes the specified command.

  Args:
    args: sequence of the executable name + arguments.
    context: An instance of Context object with global settings for test.py.
    timeout: optional timeout to wait for results in seconds.
    cwd: optionally change to this working directory.

  Returns:
    An instance of CommandOutput with the collected results.
  """
  (fd_out, outname) = tempfile.mkstemp()
  (fd_err, errname) = tempfile.mkstemp()
  (process, exit_code, timed_out) = RunProcess(context, timeout, args=args,
                                               stdout=fd_out, stderr=fd_err,
                                               cwd=cwd)
  os.close(fd_out)
  os.close(fd_err)
  output = file(outname).read()
  errors = file(errname).read()
  utils.CheckedUnlink(outname)
  utils.CheckedUnlink(errname)
  result = CommandOutput(process.pid, exit_code, timed_out,
                         output, errors)
  return result


def KillProcessWithID(pid):
  """Stop a process (with SIGTERM on Unix)."""
  if utils.IsWindows():
    os.popen('taskkill /T /F /PID %d' % pid)
  else:
    os.kill(pid, signal.SIGTERM)


MAX_SLEEP_TIME = 0.1
INITIAL_SLEEP_TIME = 0.0001
SLEEP_TIME_FACTOR = 1.25
SEM_INVALID_VALUE = -1
SEM_NOGPFAULTERRORBOX = 0x0002  # Microsoft Platform SDK WinBase.h


def Win32SetErrorMode(mode):
  """Some weird Windows stuff you just have to do."""
  prev_error_mode = SEM_INVALID_VALUE
  try:
    prev_error_mode = ctypes.windll.kernel32.SetErrorMode(mode)
  except ImportError:
    pass
  return prev_error_mode


def RunProcess(context, timeout, args, **rest):
  """Handles the OS specific details of running a task and saving results."""
  if context.verbose: print '#', ' '.join(args)
  popen_args = args
  prev_error_mode = SEM_INVALID_VALUE
  if utils.IsWindows():
    popen_args = '"' + subprocess.list2cmdline(args) + '"'
    if context.suppress_dialogs:
      # Try to change the error mode to avoid dialogs on fatal errors. Don't
      # touch any existing error mode flags by merging the existing error mode.
      # See http://blogs.msdn.com/oldnewthing/archive/2004/07/27/198410.aspx.
      error_mode = SEM_NOGPFAULTERRORBOX
      prev_error_mode = Win32SetErrorMode(error_mode)
      Win32SetErrorMode(error_mode | prev_error_mode)
  process = subprocess.Popen(shell=utils.IsWindows(),
                             args=popen_args,
                             **rest)
  if (utils.IsWindows() and context.suppress_dialogs
      and prev_error_mode != SEM_INVALID_VALUE):
    Win32SetErrorMode(prev_error_mode)
  # Compute the end time - if the process crosses this limit we
  # consider it timed out.
  if timeout is None: end_time = None
  else: end_time = time.time() + timeout
  timed_out = False
  # Repeatedly check the exit code from the process in a
  # loop and keep track of whether or not it times out.
  exit_code = None
  sleep_time = INITIAL_SLEEP_TIME
  while exit_code is None:
    if (not end_time is None) and (time.time() >= end_time):
      # Kill the process and wait for it to exit.
      KillProcessWithID(process.pid)
      # Drain the output pipe from the process to avoid deadlock
      process.communicate()
      exit_code = process.wait()
      timed_out = True
    else:
      exit_code = process.poll()
      time.sleep(sleep_time)
      sleep_time *= SLEEP_TIME_FACTOR
      if sleep_time > MAX_SLEEP_TIME:
        sleep_time = MAX_SLEEP_TIME
  return (process, exit_code, timed_out)


class TestRunner(object):
  """Base class for runners."""

  def __init__(self, work_queue, tasks, progress):
    self.work_queue = work_queue
    self.tasks = tasks
    self.terminate = False
    self.progress = progress
    self.threads = []
    self.shutdown_lock = threading.Lock()


class BatchRunner(TestRunner):
  """Implements communication with a set of subprocesses using threads."""

  def __init__(self, work_queue, tasks, progress, batch_cmd):
    super(BatchRunner, self).__init__(work_queue, tasks, progress)
    self.runners = {}
    self.last_activity = {}
    self.context = progress.context

    # Scale the number of tasks to the nubmer of CPUs on the machine
    # 1:1 is too much of an overload on many machines in batch mode,
    # so scale the ratio of threads to CPUs back.
    if tasks == testing.USE_DEFAULT_CPUS:
      tasks = .75 * testing.HOST_CPUS

    # Start threads
    for i in xrange(tasks):
      thread = threading.Thread(target=self.RunThread, args=[batch_cmd, i])
      self.threads.append(thread)
      thread.daemon = True
      thread.start()

  def RunThread(self, batch_cmd, thread_number):
    """A thread started to feed a single TestRunner."""
    try:
      runner = None
      while not self.terminate and not self.work_queue.empty():
        runner = subprocess.Popen(batch_cmd,
                                  stdin=subprocess.PIPE,
                                  stderr=subprocess.STDOUT,
                                  stdout=subprocess.PIPE)
        self.runners[thread_number] = runner
        self.FeedTestRunner(runner, thread_number)
        if thread_number in self.last_activity:
          del self.last_activity[thread_number]

        # Cleanup
        self.EndRunner(runner)

    except:
      self.Shutdown()
      raise
    finally:
      if thread_number in self.last_activity:
        del self.last_activity[thread_number]
      if runner: self.EndRunner(runner)

  def EndRunner(self, runner):
    """Cleans up a single runner, killing the child if necessary."""
    with self.shutdown_lock:
      if runner:
        returncode = runner.poll()
        if returncode is None:
          runner.kill()
      for (found_runner, thread_number) in self.runners.items():
        if runner == found_runner:
          del self.runners[thread_number]
          break
    try:
      runner.communicate()
    except ValueError:
      pass

  def CheckForTimeouts(self):
    now = time.time()
    for (thread_number, start_time) in self.last_activity.items():
      if now - start_time > self.context.timeout:
        self.runners[thread_number].kill()

  def WaitForCompletion(self):
    """Wait for threads to finish, and monitor test runners for timeouts."""
    for t in self.threads:
      while True:
        self.CheckForTimeouts()
        t.join(timeout=5)
        if not t.isAlive():
          break

  def FeedTestRunner(self, runner, thread_number):
    """Feed commands to the fork'ed TestRunner through a Popen object."""

    last_case = {}
    last_buf = ''

    while not self.terminate:
      # Is the runner still alive?
      returninfo = runner.poll()
      if returninfo is not None:
        buf = last_buf + '\n' + runner.stdout.read()
        if last_case:
          self.RecordPassFail(last_case, buf, testing.CRASH)
        else:
          with self.progress.lock:
            print >>sys. stderr, ('%s: runner unexpectedly exited: %d'
                                  % (threading.currentThread().name,
                                     returninfo))
            print 'Crash Output: '
            print
            print buf
        return

      try:
        case = self.work_queue.get_nowait()
        with self.progress.lock:
          self.progress.AboutToRun(case.case)

      except Queue.Empty:
        return
      test_case = case.case
      cmd = ' '.join(test_case.GetCommand()[1:])

      try:
        print >>runner.stdin, cmd
      except IOError:
        with self.progress.lock:
          traceback.print_exc()

        # Child exited before starting the next command.
        buf = last_buf + '\n' + runner.stdout.read()
        self.RecordPassFail(last_case, buf, testing.CRASH)

        # We never got a chance to run this command - queue it back up.
        self.work_queue.put(case)
        return

      buf = ''
      self.last_activity[thread_number] = time.time()
      while not self.terminate:
        line = runner.stdout.readline()
        if self.terminate:
          break
        case.case.duration = time.time() - self.last_activity[thread_number]
        if not line:
          # EOF. Child has exited.
          if case.case.duration > self.context.timeout:
            with self.progress.lock:
              print 'Child timed out after %d seconds' % self.context.timeout
            self.RecordPassFail(case, buf, testing.TIMEOUT)
          elif buf:
            self.RecordPassFail(case, buf, testing.CRASH)
          return

        # Look for TestRunner batch status escape sequence.  e.g.
        # >>> TEST PASS
        if line.startswith('>>> '):
          result = line.split()
          if result[1] == 'TEST':
            outcome = result[2].lower()

            # Read the rest of the output buffer (possible crash output)
            if outcome == testing.CRASH:
              buf += runner.stdout.read()

            self.RecordPassFail(case, buf, outcome)

            # Always handle crashes by restarting the runner.
            if outcome == testing.CRASH:
              return
            break
          elif result[1] == 'BATCH':
            pass
          else:
            print 'Unknown cmd from batch runner: %s' % line
        else:
          buf += line

      # If the process crashes before the next command is executed,
      # save info to report diagnostics.
      last_buf = buf
      last_case = case

  def RecordPassFail(self, case, stdout_buf, outcome):
    """An unexpected failure occurred."""
    if outcome == testing.PASS or outcome == testing.OKAY:
      exit_code = 0
    elif outcome == testing.CRASH:
      exit_code = -1
    elif outcome == testing.FAIL or outcome == testing.TIMEOUT:
      exit_code = 1
    else:
      assert False, 'Unexpected outcome: %s' % outcome

    cmd_output = CommandOutput(0, exit_code,
                               outcome == testing.TIMEOUT, stdout_buf, '')
    test_output = TestOutput(case.case,
                             case.case.GetCommand(),
                             cmd_output)
    with self.progress.lock:
      if test_output.UnexpectedOutput():
        self.progress.failed.append(test_output)
      else:
        self.progress.succeeded += 1
      if outcome == testing.CRASH:
        self.progress.crashed += 1
      self.progress.remaining -= 1
      self.progress.HasRun(test_output)

  def Shutdown(self):
    """Kill all active runners."""
    print 'Shutting down remaining runners.'
    self.terminate = True
    for runner in self.runners.values():
      runner.kill()
    # Give threads a chance to exit gracefully
    time.sleep(2)
    for runner in self.runners.values():
      self.EndRunner(runner)
