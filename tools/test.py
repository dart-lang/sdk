#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

import imp
import optparse
import os
from os.path import join, dirname, abspath, basename, isdir, exists, realpath
import platform
import re
import run
import select
import signal
import subprocess
import sys
import tempfile
import time
import threading
import traceback
from Queue import Queue, Empty

import utils

TIMEOUT_SECS = 60
VERBOSE = False
ARCH_GUESS = utils.GuessArchitecture()
OS_GUESS = utils.GuessOS()
HOST_CPUS = utils.GuessCpus()
USE_DEFAULT_CPUS = -1
BUILT_IN_TESTS = ['dartc', 'vm', 'dart', 'corelib', 'language', 'co19',
                  'samples', 'isolate', 'stub-generator', 'client']

# Patterns for matching test options in .dart files.
VM_OPTIONS_PATTERN = re.compile(r"// VMOptions=(.*)")
DART_OPTIONS_PATTERN = re.compile(r"// DartOptions=(.*)")
ISOLATE_STUB_PATTERN = re.compile(r"// IsolateStubs=(.*)")

# ---------------------------------------------
# --- P r o g r e s s   I n d i c a t o r s ---
# ---------------------------------------------


class ProgressIndicator(object):

  def __init__(self, cases, context):
    self.abort = False
    self.terminate = False
    self.cases = cases
    self.queue = Queue(len(cases))
    self.batch_queues = {};
    self.context = context

    # Extract batchable cases.
    found_cmds = {}
    batch_cases = []
    for case in cases:
      cmd = case.case.GetCommand()[0]
      if not utils.IsWindows():
        # Diagnostic check for executable (if an absolute pathname)
        if not cmd in found_cmds:
          if os.path.isabs(cmd) and not os.path.isfile(cmd):
            msg = "Can't find command %s\n" % cmd \
                  + "(Did you build first?  " \
                  + "Are you running in the correct directory?)"
            raise Exception(msg)
          else:
            found_cmds[cmd] = 1

      if case.case.IsBatchable():
        if not self.batch_queues.has_key(cmd):
          self.batch_queues[cmd] = Queue(len(cases))
        self.batch_queues[cmd].put(case)
      else:
        self.queue.put_nowait(case)

    self.succeeded = 0
    self.remaining = len(cases)
    self.total = len(cases)
    self.failed = [ ]
    self.crashed = 0
    self.lock = threading.Lock()

  def PrintFailureHeader(self, test):
    if test.IsNegative():
      negative_marker = '[negative] '
    else:
      negative_marker = ''
    print "=== %(label)s %(negative)s===" % {
      'label': test.GetLabel(),
      'negative': negative_marker
    }
    print "Path: %s" % "/".join(test.path)

  def Run(self, tasks):
    self.Starting()

    # Scale the number of tasks to the nubmer of CPUs on the machine
    if tasks == USE_DEFAULT_CPUS:
      tasks = HOST_CPUS

    # TODO(zundel): Refactor BatchSingle method and TestRunner to
    # share code and simplify this method.

    # Start the non-batchable items first - there are some long running
    # jobs we don't want to wait on at the end.
    threads = []
    # Spawn N-1 threads and then use this thread as the last one.
    # That way -j1 avoids threading altogether which is a nice fallback
    # in case of threading problems.
    for i in xrange(tasks - 1):
      thread = threading.Thread(target=self.RunSingle, args=[])
      threads.append(thread)
      thread.start()


    # Next, crank up the batchable tasks.  Note that this will start
    # 'tasks' more threads, but the assumption is that if batching is
    # enabled that almost all tests are batchable.
    for (cmd, queue) in self.batch_queues.items():
      if not queue.empty():
        batch_len = queue.qsize();
        try:
          batch_tester = BatchTester(queue, tasks, self,
                                     [cmd, '-batch'])
        except Exception, e:
          print "Aborting batch test for " + cmd + ". Problem on startup."
          batch_tester.Shutdown()
          raise

        try:
          batch_tester.WaitForCompletion()
        except:
          print "Aborting batch cmd " + cmd + "while waiting for completion."
          batch_tester.Shutdown()
          raise

    try:
      self.RunSingle()
      if self.abort:
        raise Exception("Aborted")
      # Wait for the remaining non-batched threads.
      for thread in threads:
        # Use a timeout so that signals (ctrl-c) will be processed.
        thread.join(timeout=10000000)
        if self.abort:
          raise Exception("Aborted")
    except Exception, e:
      # If there's an exception we schedule an interruption for any
      # remaining threads.
      self.terminate = True
      # ...and then reraise the exception to bail out
      raise

    self.Done()
    return not self.failed

  def RunSingle(self):
    while not self.terminate:
      try:
        test = self.queue.get_nowait()
      except Empty:
        return
      case = test.case
      with self.lock:
        self.AboutToRun(case)
      try:
        start = time.time()
        output = case.Run()
        case.duration = (time.time() - start)
      except KeyboardInterrupt:
        self.abort = True
        self.terminate = True
        raise
      except IOError, e:
        self.abort = True
        self.terminate = True
        raise
      if self.terminate:
        return
      with self.lock:
        if output.UnexpectedOutput():
          self.failed.append(output)
          if output.HasCrashed():
            self.crashed += 1
        else:
          self.succeeded += 1
        self.remaining -= 1
        self.HasRun(output)


class BatchTester(object):
  """Implements communication with a set of subprocesses using threads."""

  def __init__(self, work_queue, tasks, progress, batch_cmd):
    self.work_queue = work_queue
    self.terminate = False
    self.progress = progress
    self.threads = []
    self.runners = {}
    self.last_activity = {}
    self.context = progress.context
    self.shutdown_lock = threading.Lock()

    # Scale the number of tasks to the nubmer of CPUs on the machine
    # 1:1 is too much of an overload on many machines in batch mode,
    # so scale the ratio of threads to CPUs back.
    if tasks == USE_DEFAULT_CPUS:
      tasks = .75 * HOST_CPUS

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
        if self.last_activity.has_key(thread_number):
          del self.last_activity[thread_number]

        # cleanup
        self.EndRunner(runner)

    except:
      self.Shutdown()
      raise
    finally:
      if self.last_activity.has_key(thread_number):
        del self.last_activity[thread_number]
      if runner: self.EndRunner(runner)

  def EndRunner(self, runner):
    """ Cleans up a single runner, killing the child if necessary"""
    with self.shutdown_lock:
      if runner:
        returncode = runner.poll()
        if returncode == None:
          runner.kill()
      for (found_runner, thread_number) in self.runners.items():
        if runner == found_runner:
          del self.runners[thread_number]
          break
    try:
      runner.communicate();
    except ValueError:
      pass



  def CheckForTimeouts(self):
    now = time.time()
    for (thread_number, start_time) in self.last_activity.items():
      if now - start_time > self.context.timeout:
        self.runners[thread_number].kill()

  def WaitForCompletion(self):
    """ Wait for threads to finish, and monitor test runners for timeouts."""
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
          self.RecordPassFail(last_case, buf, CRASH)
        else:
          with self.progress.lock:
            print >>sys. stderr, ("%s: runner unexpectedly exited: %d"
                   % (threading.currentThread().name, returninfo))
            print 'Crash Output: '
            print
            print buf
        return

      try:
        case = self.work_queue.get_nowait()
        with self.progress.lock:
          self.progress.AboutToRun(case.case)

      except Empty:
        return
      test_case = case.case
      cmd = " ".join(test_case.GetCommand()[1:])

      try:
        print >>runner.stdin, cmd
      except IOError:
        with self.progress.lock:
          traceback.print_exc()

        # Child exited before starting the next command.
        buf = last_buf + '\n' + runner.stdout.read()
        self.RecordPassFail(last_case, buf, CRASH)

        # We never got a chance to run this command - queue it back up.
        self.work_queue.put(case)
        return

      buf = ""
      self.last_activity[thread_number] = time.time()
      while not self.terminate:
        line = runner.stdout.readline()
        if self.terminate:
          break;
        case.case.duration = time.time() - self.last_activity[thread_number];
        if not line:
         # EOF. Child has exited.
         if case.case.duration > self.context.timeout:
           with self.progress.lock:
             print "Child timed out after %d seconds" % self.context.timeout
           self.RecordPassFail(case, buf, TIMEOUT)
         elif buf:
           self.RecordPassFail(case, buf, CRASH)
         return

        # Look for TestRunner batch status escape sequence.  e.g.
        # >>> TEST PASS
        if line.startswith('>>> '):
          result = line.split()
          if result[1] == 'TEST':
            outcome = result[2].lower()

            # Read the rest of the output buffer (possible crash output)
            if outcome == CRASH:
              buf += runner.stdout.read()

            self.RecordPassFail(case, buf, outcome)

            # Always handle crashes by restarting the runner.
            if outcome == CRASH:
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
    if outcome == PASS or outcome == OKAY:
      exit_code = 0
    elif outcome == CRASH:
      exit_code = -1
    elif outcome == FAIL or outcome == TIMEOUT:
      exit_code = 1
    else:
      assert false, "Unexpected outcome: %s" % outcome

    cmd_output = CommandOutput(0, exit_code,
                               outcome == TIMEOUT, stdout_buf, "")
    test_output = TestOutput(case.case,
                             case.case.GetCommand(),
                             cmd_output)
    with self.progress.lock:
      if test_output.UnexpectedOutput():
        self.progress.failed.append(test_output)
      else:
        self.progress.succeeded += 1
      if outcome == CRASH:
        self.progress.crashed += 1
      self.progress.remaining -= 1
      self.progress.HasRun(test_output)

  def Shutdown(self):
    """Kill all active runners"""
    print "Shutting down remaining runners"
    self.terminate = True;
    for runner in self.runners.values():
      runner.kill()
    # Give threads a chance to exit gracefully
    time.sleep(2)
    for runner in self.runners.values():
      self.EndRunner(runner)


def EscapeCommand(command):
  parts = []
  for part in command:
    if ' ' in part:
      # Escape spaces.  We may need to escape more characters for this
      # to work properly.
      parts.append('"%s"' % part)
    else:
      parts.append(part)
  return " ".join(parts)


class SimpleProgressIndicator(ProgressIndicator):

  def Starting(self):
    print 'Running %i tests' % len(self.cases)

  def Done(self):
    print
    for failed in self.failed:
      self.PrintFailureHeader(failed.test)
      if failed.output.stderr:
        print "--- stderr ---"
        print failed.output.stderr.strip()
      if failed.output.stdout:
        print "--- stdout ---"
        print failed.output.stdout.strip()
      print "Command: %s" % EscapeCommand(failed.command)
      if failed.HasCrashed():
        print "--- CRASHED ---"
      if failed.HasTimedOut():
        print "--- TIMEOUT ---"
    if len(self.failed) == 0:
      print "==="
      print "=== All tests succeeded"
      print "==="
    else:
      print
      print "==="
      if len(self.failed) == 1:
        print "=== 1 test failed"
      else:
        print "=== %i tests failed" % len(self.failed)
      if self.crashed > 0:
        if self.crashed == 1:
          print "=== 1 test CRASHED"
        else:
          print "=== %i tests CRASHED" % self.crashed
      print "==="


class VerboseProgressIndicator(SimpleProgressIndicator):

  def AboutToRun(self, case):
    print 'Starting %s...' % case.GetLabel()
    sys.stdout.flush()

  def HasRun(self, output):
    if output.UnexpectedOutput():
      if output.HasCrashed():
        outcome = 'CRASH'
      else:
        outcome = 'FAIL'
    else:
      outcome = 'PASS'
    print 'Done running %s: %s' % (output.test.GetLabel(), outcome)


class OneLineProgressIndicator(SimpleProgressIndicator):

  def AboutToRun(self, case):
    pass

  def HasRun(self, output):
    if output.UnexpectedOutput():
      if output.HasCrashed():
        outcome = 'CRASH'
      else:
        outcome = 'FAIL'
    else:
      outcome = 'pass'
    print 'Done %s: %s' % (output.test.GetLabel(), outcome)


class OneLineProgressIndicatorForBuildBot(OneLineProgressIndicator):

  def HasRun(self, output):
    super(OneLineProgressIndicatorForBuildBot, self).HasRun(output)
    percent = (((self.total - self.remaining) * 100) // self.total)
    print '@@@STEP_CLEAR@@@'
    print '@@@STEP_TEXT@ %3d%% +%d -%d @@@' % (
        percent, self.succeeded, len(self.failed))


class CompactProgressIndicator(ProgressIndicator):

  def __init__(self, cases, context, templates):
    super(CompactProgressIndicator, self).__init__(cases, context)
    self.templates = templates
    self.last_status_length = 0
    self.start_time = time.time()

  def Starting(self):
    pass

  def Done(self):
    self.PrintProgress('Done')

  def AboutToRun(self, case):
    self.PrintProgress(case.GetLabel())

  def HasRun(self, output):
    if output.UnexpectedOutput():
      self.ClearLine(self.last_status_length)
      self.PrintFailureHeader(output.test)
      stdout = output.output.stdout.strip()
      if len(stdout):
        print self.templates['stdout'] % stdout
      stderr = output.output.stderr.strip()
      if len(stderr):
        print self.templates['stderr'] % stderr
      print "Command: %s" % EscapeCommand(output.command)
      if output.HasCrashed():
        print "--- CRASHED ---"
      if output.HasTimedOut():
        print "--- TIMEOUT ---"

  def Truncate(self, str, length):
    if length and (len(str) > (length - 3)):
      return str[:(length-3)] + "..."
    else:
      return str

  def PrintProgress(self, name):
    self.ClearLine(self.last_status_length)
    elapsed = time.time() - self.start_time
    status = self.templates['status_line'] % {
      'passed': self.succeeded,
      'percent': (((self.total - self.remaining) * 100) // self.total),
      'failed': len(self.failed),
      'test': name,
      'mins': int(elapsed) / 60,
      'secs': int(elapsed) % 60
    }
    status = self.Truncate(status, 78)
    self.last_status_length = len(status)
    print status,
    sys.stdout.flush()


class MonochromeProgressIndicator(CompactProgressIndicator):

  def __init__(self, cases, context):
    templates = {
      'status_line': "[%(mins)02i:%(secs)02i|%%%(percent) 4d|+%(passed) 4d|-%(failed) 4d]: %(test)s",
      'stdout': '%s',
      'stderr': '%s',
      'clear': lambda last_line_length: ("\r" + (" " * last_line_length) + "\r"),
      'max_length': 78
    }
    super(MonochromeProgressIndicator, self).__init__(cases, context, templates)

  def ClearLine(self, last_line_length):
    print ("\r" + (" " * last_line_length) + "\r"),

class ColorProgressIndicator(CompactProgressIndicator):

  def __init__(self, cases, context):
    templates = {
      'status_line': ("[%(mins)02i:%(secs)02i|%%%(percent) 4d|"
                       "\033[32m+%(passed) 4d"
                       "\033[0m|\033[31m-%(failed) 4d\033[0m]: %(test)s"),
      'stdout': '%s',
      'stderr': '%s',
      'clear': lambda last_line_length: ("\r" + (" " * last_line_length) + "\r"),
      'max_length': 78
    }
    super(ColorProgressIndicator, self).__init__(cases, context, templates)

  def ClearLine(self, last_line_length):
    print ("\r" + (" " * last_line_length) + "\r"),


PROGRESS_INDICATORS = {
  'verbose': VerboseProgressIndicator,
  'mono': MonochromeProgressIndicator,
  'color': ColorProgressIndicator,
  'line': OneLineProgressIndicator,
  'buildbot': OneLineProgressIndicatorForBuildBot
}


# -------------------------
# --- F r a m e w o r k ---
# -------------------------


class CommandOutput(object):

  def __init__(self, pid, exit_code, timed_out, stdout, stderr):
    self.pid = pid
    self.exit_code = exit_code
    self.timed_out = timed_out
    self.stdout = stdout
    self.stderr = stderr
    self.failed = None


class TestCase(object):

  def __init__(self, context, path):
    self.path = path
    self.context = context
    self.duration = None
    self.arch = []

  def IsBatchable(self):
    if self.context.use_batch:
      if self.arch and 'dartc' in self.arch:
        return True
    return False

  def IsNegative(self):
    return False

  def CompareTime(self, other):
    return cmp(other.duration, self.duration)

  def DidFail(self, output):
    if output.failed is None:
      output.failed = self.IsFailureOutput(output)
    return output.failed

  def IsFailureOutput(self, output):
    return output.exit_code != 0

  def RunCommand(self, command, cwd=None):
    full_command = self.context.processor(command)
    try:
      output = Execute(full_command, self.context, self.context.timeout, cwd)
    except OSError as e:
      raise utils.ToolError("%s: %s" % (full_command[0], e.strerror))
    test_output = TestOutput(self, full_command, output)
    self.Cleanup()
    return test_output

  def BeforeRun(self):
    pass

  def AfterRun(self):
    pass

  def Run(self):
    self.BeforeRun()
    cmd = self.GetCommand()
    try:
      result = self.RunCommand(cmd)
    finally:
      self.AfterRun()
    return result

  def Cleanup(self):
    return


class TestOutput(object):

  def __init__(self, test, command, output):
    self.test = test
    self.command = command
    self.output = output

  def UnexpectedOutput(self):
    if self.HasCrashed():
      outcome = CRASH
    elif self.HasTimedOut():
      outcome = TIMEOUT
    elif self.HasFailed():
      outcome = FAIL
    else:
      outcome = PASS
    return not outcome in self.test.outcomes

  def HasCrashed(self):
    if utils.IsWindows():
      if self.output.exit_code == 3:
        # The VM uses std::abort to terminate on asserts.
        # std::abort terminates with exit code 3 on Windows.
        return True
      return 0x80000000 & self.output.exit_code and not (0x3FFFFF00 & self.output.exit_code)
    else:
      # Timed out tests will have exit_code -signal.SIGTERM.
      if self.output.timed_out:
        return False
      if self.output.exit_code == 253:
        # The Java dartc runners exit 253 in case of unhandled exceptions.
        return True
      return self.output.exit_code < 0

  def HasTimedOut(self):
    return self.output.timed_out;

  def HasFailed(self):
    execution_failed = self.test.DidFail(self.output)
    if self.test.IsNegative():
      return not execution_failed
    else:
      return execution_failed


def KillProcessWithID(pid):
  if utils.IsWindows():
    os.popen('taskkill /T /F /PID %d' % pid)
  else:
    os.kill(pid, signal.SIGTERM)


MAX_SLEEP_TIME = 0.1
INITIAL_SLEEP_TIME = 0.0001
SLEEP_TIME_FACTOR = 1.25

SEM_INVALID_VALUE = -1
SEM_NOGPFAULTERRORBOX = 0x0002 # Microsoft Platform SDK WinBase.h

def Win32SetErrorMode(mode):
  prev_error_mode = SEM_INVALID_VALUE
  try:
    import ctypes
    prev_error_mode = ctypes.windll.kernel32.SetErrorMode(mode);
  except ImportError:
    pass
  return prev_error_mode

def RunProcess(context, timeout, args, **rest):
  if context.verbose: print "#", " ".join(args)
  popen_args = args
  prev_error_mode = SEM_INVALID_VALUE;
  if utils.IsWindows():
    popen_args = '"' + subprocess.list2cmdline(args) + '"'
    if context.suppress_dialogs:
      # Try to change the error mode to avoid dialogs on fatal errors. Don't
      # touch any existing error mode flags by merging the existing error mode.
      # See http://blogs.msdn.com/oldnewthing/archive/2004/07/27/198410.aspx.
      error_mode = SEM_NOGPFAULTERRORBOX;
      prev_error_mode = Win32SetErrorMode(error_mode);
      Win32SetErrorMode(error_mode | prev_error_mode);
  process = subprocess.Popen(
    shell = utils.IsWindows(),
    args = popen_args,
    **rest
  )
  if utils.IsWindows() and context.suppress_dialogs and prev_error_mode != SEM_INVALID_VALUE:
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
      sleep_time = sleep_time * SLEEP_TIME_FACTOR
      if sleep_time > MAX_SLEEP_TIME:
        sleep_time = MAX_SLEEP_TIME
  return (process, exit_code, timed_out)


def PrintError(str):
  sys.stderr.write(str)
  sys.stderr.write('\n')


def CheckedUnlink(name):
  try:
    os.unlink(name)
  except OSError, e:
    PrintError("os.unlink() " + str(e))


def Execute(args, context, timeout=None, cwd=None):
  (fd_out, outname) = tempfile.mkstemp()
  (fd_err, errname) = tempfile.mkstemp()
  (process, exit_code, timed_out) = RunProcess(
    context,
    timeout,
    args = args,
    stdout = fd_out,
    stderr = fd_err,
    cwd = cwd
  )
  os.close(fd_out)
  os.close(fd_err)
  output = file(outname).read()
  errors = file(errname).read()
  CheckedUnlink(outname)
  CheckedUnlink(errname)
  result = CommandOutput(process.pid, exit_code, timed_out, output, errors)
  return result


class TestConfiguration(object):

  def __init__(self, context, root):
    self.context = context
    self.root = root

  def Contains(self, path, file):
    if len(path) > len(file):
      return False
    for i in xrange(len(path)):
      if not path[i].match(file[i]):
        return False
    return True

  def GetTestStatus(self, sections, defs):
    pass


class TestSuite(object):

  def __init__(self, name):
    self.name = name

  def GetName(self):
    return self.name


class TestRepository(TestSuite):

  def __init__(self, path):
    normalized_path = abspath(path)
    super(TestRepository, self).__init__(basename(normalized_path))
    self.path = normalized_path
    self.is_loaded = False
    self.config = None

  def GetConfiguration(self, context):
    if self.is_loaded:
      return self.config
    self.is_loaded = True
    file = None
    try:
      (file, pathname, description) = imp.find_module('testcfg', [ self.path ])
      module = imp.load_module('testcfg', file, pathname, description)
      self.config = module.GetConfiguration(context, self.path)
    finally:
      if file:
        file.close()
    return self.config

  def ListTests(self, current_path, path, context, mode, arch):
    return self.GetConfiguration(context).ListTests(current_path,
                                                    path,
                                                    mode,
                                                    arch)

  def GetTestStatus(self, context, sections, defs):
    self.GetConfiguration(context).GetTestStatus(sections, defs)


class LiteralTestSuite(TestSuite):

  def __init__(self, tests):
    super(LiteralTestSuite, self).__init__('root')
    self.tests = tests

  def ListTests(self, current_path, path, context, mode, arch):
    name =  path[0]
    result = [ ]
    for test in self.tests:
      test_name = test.GetName()
      if name.match(test_name):
        full_path = current_path + [test_name]
        result += test.ListTests(full_path, path, context, mode, arch)
    return result

  def GetTestStatus(self, context, sections, defs):
    for test in self.tests:
      test.GetTestStatus(context, sections, defs)

class Context(object):

  def __init__(self, workspace, verbose, os, timeout,
               processor, suppress_dialogs, executable, flags,
               keep_temporary_files, use_batch):
    self.workspace = workspace
    self.verbose = verbose
    self.os = os
    self.timeout = timeout
    self.processor = processor
    self.suppress_dialogs = suppress_dialogs
    self.executable = executable
    self.flags = flags
    self.keep_temporary_files = keep_temporary_files
    self.use_batch = use_batch == "true"

  def GetBuildRoot(self, mode, arch):
    result = utils.GetBuildRoot(self.os, mode, arch)
    return result

  def GetBuildConf(self, mode, arch):
    result = utils.GetBuildConf(mode, arch)
    return result

  def GetExecutable(self, mode, arch, name):
    if self.executable is not None:
      return self.executable
    path = abspath(join(self.GetBuildRoot(mode, arch), name))
    if utils.IsWindows() and not path.endswith('.exe'):
      return path + '.exe'
    else:
      return path

  def GetDart(self, mode, arch):
    if arch == 'dartc':
      command = [ abspath(join(self.GetBuildRoot(mode, arch),
                               'compiler', 'bin', 'dartc_test')) ]
    else:
      command = [ self.GetExecutable(mode, arch, 'dart_bin') ]

    return command

  def GetDartC(self, mode, arch):
    dartc = abspath(os.path.join(self.GetBuildRoot(mode, arch),
                                 'compiler', 'bin', 'dartc'))
    if utils.IsWindows(): dartc += '.exe'
    command = [ dartc ]

    # Add the flags from the context to the command line.
    command += self.flags
    return command

  def GetRunTests(self, mode, arch):
    return [ self.GetExecutable(mode, arch, 'run_vm_tests') ]

def RunTestCases(cases_to_run, progress, tasks, context):
  progress = PROGRESS_INDICATORS[progress](cases_to_run, context)
  return progress.Run(tasks)


# -------------------------------------------
# --- T e s t   C o n f i g u r a t i o n ---
# -------------------------------------------


SKIP = 'skip'
FAIL = 'fail'
PASS = 'pass'
OKAY = 'okay'
TIMEOUT = 'timeout'
CRASH = 'crash'
SLOW = 'slow'


class Expression(object):
  pass


class Constant(Expression):

  def __init__(self, value):
    self.value = value

  def Evaluate(self, env, defs):
    return self.value


class Variable(Expression):

  def __init__(self, name):
    self.name = name

  def GetOutcomes(self, env, defs):
    if self.name in env: return ListSet([env[self.name]])
    else: return Nothing()


class Outcome(Expression):

  def __init__(self, name):
    self.name = name

  def GetOutcomes(self, env, defs):
    if self.name in defs:
      return defs[self.name].GetOutcomes(env, defs)
    else:
      return ListSet([self.name])


class Set(object):
  pass


class ListSet(Set):

  def __init__(self, elms):
    self.elms = elms

  def __str__(self):
    return "ListSet%s" % str(self.elms)

  def Intersect(self, that):
    if not isinstance(that, ListSet):
      return that.Intersect(self)
    return ListSet([ x for x in self.elms if x in that.elms ])

  def Union(self, that):
    if not isinstance(that, ListSet):
      return that.Union(self)
    return ListSet(self.elms + [ x for x in that.elms if x not in self.elms ])

  def IsEmpty(self):
    return len(self.elms) == 0


class Everything(Set):

  def Intersect(self, that):
    return that

  def Union(self, that):
    return self

  def IsEmpty(self):
    return False


class Nothing(Set):

  def Intersect(self, that):
    return self

  def Union(self, that):
    return that

  def IsEmpty(self):
    return True


class Operation(Expression):

  def __init__(self, left, op, right):
    self.left = left
    self.op = op
    self.right = right

  def Evaluate(self, env, defs):
    if self.op == '||' or self.op == ',':
      return self.left.Evaluate(env, defs) or self.right.Evaluate(env, defs)
    elif self.op == 'if':
      return False
    elif self.op == '==':
      inter = self.left.GetOutcomes(env, defs).Intersect(self.right.GetOutcomes(env, defs))
      return not inter.IsEmpty()
    else:
      assert self.op == '&&'
      return self.left.Evaluate(env, defs) and self.right.Evaluate(env, defs)

  def GetOutcomes(self, env, defs):
    if self.op == '||' or self.op == ',':
      return self.left.GetOutcomes(env, defs).Union(self.right.GetOutcomes(env, defs))
    elif self.op == 'if':
      if self.right.Evaluate(env, defs): return self.left.GetOutcomes(env, defs)
      else: return Nothing()
    else:
      assert self.op == '&&'
      return self.left.GetOutcomes(env, defs).Intersect(self.right.GetOutcomes(env, defs))


def IsAlpha(str):
  for char in str:
    if not (char.isalpha() or char.isdigit() or char == '_'):
      return False
  return True


class Tokenizer(object):
  """A simple string tokenizer that chops expressions into variables,
  parens and operators"""

  def __init__(self, expr):
    self.index = 0
    self.expr = expr
    self.length = len(expr)
    self.tokens = None

  def Current(self, length = 1):
    if not self.HasMore(length): return ""
    return self.expr[self.index:self.index+length]

  def HasMore(self, length = 1):
    return self.index < self.length + (length - 1)

  def Advance(self, count = 1):
    self.index = self.index + count

  def AddToken(self, token):
    self.tokens.append(token)

  def SkipSpaces(self):
    while self.HasMore() and self.Current().isspace():
      self.Advance()

  def Tokenize(self):
    self.tokens = [ ]
    while self.HasMore():
      self.SkipSpaces()
      if not self.HasMore():
        return None
      if self.Current() == '(':
        self.AddToken('(')
        self.Advance()
      elif self.Current() == ')':
        self.AddToken(')')
        self.Advance()
      elif self.Current() == '$':
        self.AddToken('$')
        self.Advance()
      elif self.Current() == ',':
        self.AddToken(',')
        self.Advance()
      elif IsAlpha(self.Current()):
        buf = ""
        while self.HasMore() and IsAlpha(self.Current()):
          buf += self.Current()
          self.Advance()
        self.AddToken(buf)
      elif self.Current(2) == '&&':
        self.AddToken('&&')
        self.Advance(2)
      elif self.Current(2) == '||':
        self.AddToken('||')
        self.Advance(2)
      elif self.Current(2) == '==':
        self.AddToken('==')
        self.Advance(2)
      else:
        return None
    return self.tokens


class Scanner(object):
  """A simple scanner that can serve out tokens from a given list"""

  def __init__(self, tokens):
    self.tokens = tokens
    self.length = len(tokens)
    self.index = 0

  def HasMore(self):
    return self.index < self.length

  def Current(self):
    return self.tokens[self.index]

  def Advance(self):
    self.index = self.index + 1


def ParseAtomicExpression(scan):
  if scan.Current() == "true":
    scan.Advance()
    return Constant(True)
  elif scan.Current() == "false":
    scan.Advance()
    return Constant(False)
  elif IsAlpha(scan.Current()):
    name = scan.Current()
    scan.Advance()
    return Outcome(name.lower())
  elif scan.Current() == '$':
    scan.Advance()
    if not IsAlpha(scan.Current()):
      return None
    name = scan.Current()
    scan.Advance()
    return Variable(name.lower())
  elif scan.Current() == '(':
    scan.Advance()
    result = ParseLogicalExpression(scan)
    if (not result) or (scan.Current() != ')'):
      return None
    scan.Advance()
    return result
  else:
    return None


BINARIES = ['==']
def ParseOperatorExpression(scan):
  left = ParseAtomicExpression(scan)
  if not left: return None
  while scan.HasMore() and (scan.Current() in BINARIES):
    op = scan.Current()
    scan.Advance()
    right = ParseOperatorExpression(scan)
    if not right:
      return None
    left = Operation(left, op, right)
  return left


def ParseConditionalExpression(scan):
  left = ParseOperatorExpression(scan)
  if not left: return None
  while scan.HasMore() and (scan.Current() == 'if'):
    scan.Advance()
    right = ParseOperatorExpression(scan)
    if not right:
      return None
    left=  Operation(left, 'if', right)
  return left


LOGICALS = ["&&", "||", ","]
def ParseLogicalExpression(scan):
  left = ParseConditionalExpression(scan)
  if not left: return None
  while scan.HasMore() and (scan.Current() in LOGICALS):
    op = scan.Current()
    scan.Advance()
    right = ParseConditionalExpression(scan)
    if not right:
      return None
    left = Operation(left, op, right)
  return left


def ParseCondition(expr):
  """Parses a logical expression into an Expression object"""
  tokens = Tokenizer(expr).Tokenize()
  if not tokens:
    print "Malformed expression: '%s'" % expr
    return None
  scan = Scanner(tokens)
  ast = ParseLogicalExpression(scan)
  if not ast:
    print "Malformed expression: '%s'" % expr
    return None
  if scan.HasMore():
    print "Malformed expression: '%s'" % expr
    return None
  return ast


class ClassifiedTest(object):

  def __init__(self, case, outcomes):
    self.case = case
    self.outcomes = outcomes


class Configuration(object):
  """The parsed contents of a configuration file"""

  def __init__(self, sections, defs):
    self.sections = sections
    self.defs = defs

  def ClassifyTests(self, cases, env):
    sections = [s for s in self.sections if s.condition.Evaluate(env, self.defs)]
    all_rules = reduce(list.__add__, [s.rules for s in sections], [])
    unused_rules = set(all_rules)
    result = [ ]
    all_outcomes = set([])
    for case in cases:
      matches = [ r for r in all_rules if r.Contains(case.path) ]
      outcomes = set([])
      for rule in matches:
        outcomes = outcomes.union(rule.GetOutcomes(env, self.defs))
        unused_rules.discard(rule)
      if not outcomes:
        outcomes = [PASS]
      case.outcomes = outcomes
      all_outcomes = all_outcomes.union(outcomes)
      result.append(ClassifiedTest(case, outcomes))
    return (result, list(unused_rules), all_outcomes)


class Section(object):
  """A section of the configuration file.  Sections are enabled or
  disabled prior to running the tests, based on their conditions"""

  def __init__(self, condition):
    self.condition = condition
    self.rules = [ ]

  def AddRule(self, rule):
    self.rules.append(rule)


class Rule(object):
  """A single rule that specifies the expected outcome for a single
  test."""

  def __init__(self, raw_path, path, value):
    self.raw_path = raw_path
    self.path = path
    self.value = value

  def GetOutcomes(self, env, defs):
    set = self.value.GetOutcomes(env, defs)
    assert isinstance(set, ListSet)
    return set.elms

  def Contains(self, path):
    if len(self.path) > len(path):
      return False
    for i in xrange(len(self.path)):
      if not self.path[i].match(path[i]):
        return False
    return True


HEADER_PATTERN = re.compile(r'\[([^]]+)\]')
RULE_PATTERN = re.compile(r'\s*([^: ]*)\s*:(.*)')
DEF_PATTERN = re.compile(r'^def\s*(\w+)\s*=(.*)$')
PREFIX_PATTERN = re.compile(r'^\s*prefix\s+([\w\_\.\-\/]+)$')


def ReadConfigurationInto(path, sections, defs):
  current_section = Section(Constant(True))
  sections.append(current_section)
  prefix = []
  for line in utils.ReadLinesFrom(path):
    header_match = HEADER_PATTERN.match(line)
    if header_match:
      condition_str = header_match.group(1).strip()
      condition = ParseCondition(condition_str)
      new_section = Section(condition)
      sections.append(new_section)
      current_section = new_section
      continue
    rule_match = RULE_PATTERN.match(line)
    if rule_match:
      path = prefix + SplitPath(rule_match.group(1).strip())
      value_str = rule_match.group(2).strip()
      value = ParseCondition(value_str)
      if not value:
        return False
      current_section.AddRule(Rule(rule_match.group(1), path, value))
      continue
    def_match = DEF_PATTERN.match(line)
    if def_match:
      name = def_match.group(1).lower()
      value = ParseCondition(def_match.group(2).strip())
      if not value:
        return False
      defs[name] = value
      continue
    prefix_match = PREFIX_PATTERN.match(line)
    if prefix_match:
      prefix = SplitPath(prefix_match.group(1).strip())
      continue
    print "Malformed line: '%s'." % line
    return False
  return True


# ---------------
# --- M a i n ---
# ---------------


def BuildOptions():
  result = optparse.OptionParser()
  result.add_option("-m", "--mode",
      help="The test modes in which to run (comma-separated)",
      metavar='[all,debug,release]',
      default='debug')
  result.add_option("-v", "--verbose",
      help="Verbose output",
      default=False,
      action="store_true")
  result.add_option("-p", "--progress",
      help="The style of progress indicator (verbose, line, color, mono)",
      choices=PROGRESS_INDICATORS.keys(),
      default=None)
  result.add_option("--report",
      help="Print a summary of the tests to be run",
      default=False,
      action="store_true")
  result.add_option("--list",
      help="List all the tests, but don't run them",
      default=False,
      action="store_true")
  result.add_option("-s", "--suite",
      help="A test suite",
      default=[],
      action="append")
  result.add_option("-t", "--timeout",
      help="Timeout in seconds",
      default=None,
      type="int")
  result.add_option("--checked",
      help="Run tests in checked mode",
      default=False,
      action="store_true")
  result.add_option("--flag",
      help="Pass this additional flag to the VM",
      default=[],
      action="append")
  result.add_option("--arch",
      help="The architecture to run tests for",
      metavar="[all,ia32,x64,simarm,arm,dartc]",
      default=ARCH_GUESS)
  result.add_option("--os",
      help="The OS to run tests on",
      default=OS_GUESS)
  result.add_option("--valgrind",
      help="Run tests through valgrind",
      default=False,
      action="store_true")
  result.add_option("-j", "--tasks",
      help="The number of parallel tasks to run",
      metavar=HOST_CPUS,
      default=USE_DEFAULT_CPUS,
      type="int")
  result.add_option("--time",
      help="Print timing information after running",
      default=False,
      action="store_true")
  result.add_option("--executable",
      help="The executable with which to run the tests",
      default=None)
  result.add_option("--keep_temporary_files",
      help="Do not delete temporary files after running the tests",
      default=False,
      action="store_true")
  result.add_option("--batch",
      help="Run multiple tests for dartc architecture in a single vm",
      choices=["true","false"],
      default="true",
      type="choice");
  result.add_option("--optimize",
      help="Invoke dart compiler with --optimize flag",
      default=False,
      action="store_true")

  return result


def ProcessOptions(options):
  global VERBOSE
  VERBOSE = options.verbose
  if options.arch == 'all':
    options.arch = 'ia32,x64,simarm'
  if options.mode == 'all':
    options.mode = 'debug,release'
  # By default we run with a higher timeout setting in when running on
  # a simulated architecture and in debug mode.
  if not options.timeout:
    options.timeout = TIMEOUT_SECS
    if 'dartc' in options.arch: options.timeout *= 4
    elif 'chromium' in options.arch: options.timeout *= 4
    elif 'dartium' in options.arch: options.timeout *= 4
    elif 'debug' in options.mode: options.timeout *= 2
    # TODO(zundel): is arch 'sim' out of date?
    if 'sim' in options.arch: options.timeout *= 4
  options.mode = options.mode.split(',')
  options.arch = options.arch.split(',')
  for mode in options.mode:
    if not mode in ['debug', 'release']:
      print "Unknown mode %s" % mode
      return False
  for arch in options.arch:
    if not arch in ['ia32', 'x64', 'simarm', 'arm', 'dartc', 'dartium',
                    'chromium']:
      print "Unknown arch %s" % arch
      return False
  options.flags = []
  if (arch == 'dartc' or arch == 'chromium') and mode == 'release':
    options.flags.append('--optimize')
  options.flags.append('--ignore-unrecognized-flags')
  if options.checked:
    options.flags.append('--enable_asserts')
    options.flags.append('--enable_type_checks')
  if options.optimize:
    options.flags.append('--optimize')
  for flag in options.flag:
    options.flags.append(flag)
  if options.verbose:
    print "Flags on the command line:"
    for x in options.flags:
      print x
  # If the user hasn't specified the progress indicator, we pick
  # a good one depending on the setting of the verbose option.
  if not options.progress:
    if options.verbose: options.progress = 'verbose'
    else: options.progress = 'mono'
  # Options for future use. Such as Windows runner support.
  options.suppress_dialogs = True
  options.special_command = None
  return True


REPORT_TEMPLATE = """\
Total: %(total)i tests
 * %(skipped)4d tests will be skipped
 * %(nocrash)4d tests are expected to be flaky but not crash
 * %(pass)4d tests are expected to pass
 * %(fail_ok)4d tests are expected to fail that we won't fix
 * %(fail)4d tests are expected to fail that we should fix
 * %(crash)4d tests are expected to crash that we should fix
 * %(batched)4d tests are running in batch mode\
"""

def PrintReport(cases):
  """Print a breakdown of which tests are marked pass/skip/fail """
  def IsFlaky(o):
    return (PASS in o) and (FAIL in o) and (not CRASH in o) and (not OKAY in o)
  def IsFailOk(o):
    return (len(o) == 2) and (FAIL in o) and (OKAY in o)
  unskipped = [c for c in cases if not SKIP in c.outcomes]
  print REPORT_TEMPLATE % {
    'total': len(cases),
    'skipped': len(cases) - len(unskipped),
    'nocrash': len([t for t in unskipped if IsFlaky(t.outcomes)]),
    'pass': len([t for t in unskipped if list(t.outcomes) == [PASS]]),
    'fail_ok': len([t for t in unskipped if IsFailOk(t.outcomes)]),
    'fail': len([t for t in unskipped if list(t.outcomes) == [FAIL]]),
    'crash': len([t for t in unskipped if list(t.outcomes) == [CRASH]]),
    'batched' : len([t for t in unskipped if t.case.IsBatchable()])
  }


def PrintTests(cases):
  has_errors = False
  for case in cases:
    try:
      case.case.GetCommand()
    except:
      sys.stderr.write(case.case.filename + '\n')
      has_errors = True
  if has_errors:
    raise Exception('Errors in above files')
  for case in [c for c in cases if not SKIP in c.outcomes]:
    print "%s\t%s\t%s\t%s" %('/'.join(case.case.path),
                             ','.join(case.outcomes),
                             case.case.IsNegative(),
                             '\t'.join(case.case.GetCommand()[1:]))


class Pattern(object):

  def __init__(self, pattern):
    self.pattern = pattern
    self.compiled = None

  def match(self, str):
    if not self.compiled:
      pattern = "^" + self.pattern.replace('*', '.*') + "$"
      self.compiled = re.compile(pattern)
    return self.compiled.match(str)

  def __str__(self):
    return self.pattern


def SplitPath(s):
  stripped = [ c.strip() for c in s.split('/') ]
  return [ Pattern(s) for s in stripped if len(s) > 0 ]


def GetSpecialCommandProcessor(value):
  if (not value) or (value.find('@') == -1):
    def ExpandCommand(args):
      return args
    return ExpandCommand
  else:
    pos = value.find('@')
    import urllib
    prefix = urllib.unquote(value[:pos]).split()
    suffix = urllib.unquote(value[pos+1:]).split()
    def ExpandCommand(args):
      return prefix + args + suffix
    return ExpandCommand


def GetSuites(test_root):
  def IsSuite(path):
    return isdir(path) and exists(join(path, 'testcfg.py'))
  return [ f for f in os.listdir(test_root) if IsSuite(join(test_root, f)) ]


def FormatTime(d):
  millis = round(d * 1000) % 1000
  return time.strftime("%M:%S.", time.gmtime(d)) + ("%03i" % millis)


def Main():
  utils.ConfigureJava()
  parser = BuildOptions()
  (options, args) = parser.parse_args()
  if not ProcessOptions(options):
    parser.print_help()
    return 1

  client = abspath(join(dirname(sys.argv[0]), '..'))
  repositories = []
  for component in os.listdir(client) + ['.']:
    test_path = join(client, component, 'tests')
    if exists(test_path) and isdir(test_path):
      suites = GetSuites(test_path)
      repositories += [TestRepository(join(test_path, name)) for name in suites]
  repositories += [TestRepository(a) for a in options.suite]

  root = LiteralTestSuite(repositories)
  if len(args) == 0:
    paths = [SplitPath(t) for t in BUILT_IN_TESTS]
  else:
    paths = [ ]
    for arg in args:
      path = SplitPath(arg)
      paths.append(path)

  # Check for --valgrind option. If enabled, we overwrite the special
  # command flag with a command that uses the tools/valgrind.py script.
  if options.valgrind:
    run_valgrind = join(client, 'runtime', 'tools', 'valgrind.py')
    options.special_command = "python -u " + run_valgrind + " @"

  context = Context(client,
                    VERBOSE,
                    options.os,
                    options.timeout,
                    GetSpecialCommandProcessor(options.special_command),
                    options.suppress_dialogs,
                    options.executable,
                    options.flags,
                    options.keep_temporary_files,
                    options.batch)

  # Get status for tests
  sections = [ ]
  defs = { }
  root.GetTestStatus(context, sections, defs)
  config = Configuration(sections, defs)

  # List the tests
  all_cases = [ ]
  all_unused = [ ]
  unclassified_tests = [ ]
  globally_unused_rules = None
  for path in paths:
    for mode in options.mode:
      for arch in options.arch:
        env = {
          'mode': mode,
          'system': utils.GuessOS(),
          'arch': arch,
        }
        test_list = root.ListTests([], path, context, mode, arch)
        unclassified_tests += test_list
        (cases, unused_rules, all_outcomes) = config.ClassifyTests(test_list, env)
        if globally_unused_rules is None:
          globally_unused_rules = set(unused_rules)
        else:
          globally_unused_rules = globally_unused_rules.intersection(unused_rules)
        all_cases += cases
        all_unused.append(unused_rules)

  if options.report:
    PrintReport(all_cases)

  if options.list:
    PrintTests(all_cases)
    return 0;

  result = None
  def DoSkip(case):
    return SKIP in case.outcomes or SLOW in case.outcomes
  cases_to_run = [ c for c in all_cases if not DoSkip(c) ]
  if len(cases_to_run) == 0:
    print "No tests to run."
    return 0
  else:
    try:
      start = time.time()
      if RunTestCases(cases_to_run, options.progress, options.tasks,
                      context):
        result = 0
      else:
        result = 1
      duration = time.time() - start
    except KeyboardInterrupt:
      print "Exiting on KeyboardInterrupt"
      return 1

  if options.time:
    print
    print "--- Total time: %s ---" % FormatTime(duration)
    timed_tests = [ t.case for t in cases_to_run if not t.case.duration is None ]
    timed_tests.sort(lambda a, b: a.CompareTime(b))
    index = 1
    for entry in timed_tests[:20]:
      t = FormatTime(entry.duration)
      print "%4i (%s) %s" % (index, t, entry.GetLabel())
      index += 1

  return result


if __name__ == '__main__':
  sys.exit(Main())
