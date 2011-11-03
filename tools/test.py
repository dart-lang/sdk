#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""Test driver for the Dart project used by continuous build and developers."""


import imp
import optparse
import os
import Queue
import re
import sys
import threading
import time
import urllib

import testing
from testing import test_runner
import utils


TIMEOUT_SECS = 60
ARCH_GUESS = utils.GuessArchitecture()
OS_GUESS = utils.GuessOS()
BUILT_IN_TESTS = ['dartc', 'vm', 'standalone', 'corelib', 'language', 'co19',
                  'samples', 'isolate', 'stub-generator', 'client']

# Patterns for matching test options in .dart files.
VM_OPTIONS_PATTERN = re.compile(r'// VMOptions=(.*)')
DART_OPTIONS_PATTERN = re.compile(r'// DartOptions=(.*)')
ISOLATE_STUB_PATTERN = re.compile(r'// IsolateStubs=(.*)')

# ---------------------------------------------
# --- P r o g r e s s   I n d i c a t o r s ---
# ---------------------------------------------


class Error(Exception):
  pass


class ProgressIndicator(object):
  """Base class for displaying the progress of the test run."""

  def __init__(self, cases, context):
    self.abort = False
    self.terminate = False
    self.cases = cases
    self.queue = Queue.Queue(len(cases))
    self.batch_queues = {}
    self.context = context

    # Extract batchable cases.
    found_cmds = {}
    for case in cases:
      cmd = case.case.GetCommand()[0]
      if not utils.IsWindows():
        # Diagnostic check for executable (if an absolute pathname)
        if not cmd in found_cmds:
          if os.path.isabs(cmd) and not os.path.isfile(cmd):
            msg = "Can't find command %s\n" % cmd
            msg += '(Did you build first?  '
            msg += 'Are you running in the correct directory?)'
            raise Exception(msg)
          else:
            found_cmds[cmd] = 1

      if case.case.IsBatchable():
        if not cmd in self.batch_queues:
          self.batch_queues[cmd] = Queue.Queue(len(cases))
        self.batch_queues[cmd].put(case)
      else:
        self.queue.put_nowait(case)

    self.succeeded = 0
    self.remaining = len(cases)
    self.total = len(cases)
    self.failed = []
    self.crashed = 0
    self.lock = threading.Lock()

  def PrintFailureHeader(self, test):
    if test.IsNegative():
      negative_marker = '[negative] '
    else:
      negative_marker = ''
    print '=== %(label)s %(negative)s===' % {
        'label': test.GetLabel(),
        'negative': negative_marker
    }
    print 'Path: %s' % '/'.join(test.path)

  def Run(self, tasks):
    """Starts tests and keeps running until queues are drained."""
    self.Starting()

    # Scale the number of tasks to the nubmer of CPUs on the machine
    if tasks == testing.USE_DEFAULT_CPUS:
      tasks = testing.HOST_CPUS

    # TODO(zundel): Refactor BatchSingle method and TestRunner to
    # share code and simplify this method.

    # Start the non-batchable items first - there are some long running
    # jobs we don't want to wait on at the end.
    threads = []
    # Spawn N-1 threads and then use this thread as the last one.
    # That way -j1 avoids threading altogether which is a nice fallback
    # in case of threading problems.
    for unused_i in xrange(tasks - 1):
      thread = threading.Thread(target=self.RunSingle, args=[])
      threads.append(thread)
      thread.start()

    # Next, crank up the batchable tasks.  Note that this will start
    # 'tasks' more threads, but the assumption is that if batching is
    # enabled that almost all tests are batchable.
    for (cmd, queue) in self.batch_queues.items():
      if not queue.empty():
        batch_tester = None
        try:
          batch_tester = test_runner.BatchRunner(queue, tasks, self,
                                                 [cmd, '-batch'])
        except:
          print 'Aborting batch test for ' + cmd + '. Problem on startup.'
          if batch_tester: batch_tester.Shutdown()
          raise

        try:
          batch_tester.WaitForCompletion()
        except:
          print 'Aborting batch cmd ' + cmd + 'while waiting for completion.'
          if batch_tester: batch_tester.Shutdown()
          raise

    try:
      self.RunSingle()
      if self.abort:
        raise Error('Aborted')
      # Wait for the remaining non-batched threads.
      for thread in threads:
        # Use a timeout so that signals (ctrl-c) will be processed.
        thread.join(timeout=10000000)
        if self.abort:
          raise Error('Aborted')
    except:
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
      except Queue.Empty:
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
      except IOError:
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


def EscapeCommand(command):
  parts = []
  for part in command:
    if ' ' in part:
      # Escape spaces.  We may need to escape more characters for this
      # to work properly.
      parts.append('"%s"' % part)
    else:
      parts.append(part)
  return ' '.join(parts)


class SimpleProgressIndicator(ProgressIndicator):
  """Base class for printing output of each test separately."""

  def Starting(self):
    """Called at the beginning before any tests are run."""
    print 'Running %i tests' % len(self.cases)

  def Done(self):
    """Called when all tests are complete."""
    print
    for failed in self.failed:
      self.PrintFailureHeader(failed.test)
      if failed.output.stderr:
        print '--- stderr ---'
        print failed.output.stderr.strip()
      if failed.output.stdout:
        print '--- stdout ---'
        print failed.output.stdout.strip()
      print 'Command: %s' % EscapeCommand(failed.command)
      if failed.HasCrashed():
        print '--- CRASHED ---'
      if failed.HasTimedOut():
        print '--- TIMEOUT ---'
    if not self.failed:
      print '==='
      print '=== All tests succeeded'
      print '==='
    else:
      print
      print '==='
      if len(self.failed) == 1:
        print '=== 1 test failed'
      else:
        print '=== %i tests failed' % len(self.failed)
      if self.crashed > 0:
        if self.crashed == 1:
          print '=== 1 test CRASHED'
        else:
          print '=== %i tests CRASHED' % self.crashed
      print '==='


class VerboseProgressIndicator(SimpleProgressIndicator):
  """Print verbose information about each test that is run."""

  def AboutToRun(self, case):
    """Called before each test case is run."""
    print 'Starting %s...' % case.GetLabel()
    sys.stdout.flush()

  def HasRun(self, output):
    """Called after each test case is run."""
    if output.UnexpectedOutput():
      if output.HasCrashed():
        outcome = 'CRASH'
      else:
        outcome = 'FAIL'
    else:
      outcome = 'PASS'
    print 'Done running %s: %s' % (output.test.GetLabel(), outcome)


class OneLineProgressIndicator(SimpleProgressIndicator):
  """Results of each test is printed like a report, on a line by itself."""

  def AboutToRun(self, case):
    """Called before each test case is run."""
    pass

  def HasRun(self, output):
    """Called after each test case is run."""
    if output.UnexpectedOutput():
      if output.HasCrashed():
        outcome = 'CRASH'
      else:
        outcome = 'FAIL'
    else:
      outcome = 'pass'
    print 'Done %s: %s' % (output.test.GetLabel(), outcome)


class StatusFileProgressIndicator(SimpleProgressIndicator):

  def AboutToRun(self, case):
    """Called before each test case is run."""
    pass

  def HasRun(self, output):
    """Called after each test case is run."""
    actual_outcome = output.GetOutcome()
    expected_outcomes = set(output.test.outcomes)
    if not actual_outcome in expected_outcomes:
      expected_outcomes.discard(testing.PASS)
      if expected_outcomes:
        print 'Incorrect status for %s: %s' % (output.test.GetLabel(),
                                               ', '.join(expected_outcomes))
      else:
        print 'Update status for %s: %s' % (output.test.GetLabel(),
                                            actual_outcome)


class OneLineProgressIndicatorForBuildBot(OneLineProgressIndicator):

  def HasRun(self, output):
    """Called after each test case is run."""
    super(OneLineProgressIndicatorForBuildBot, self).HasRun(output)
    percent = (((self.total - self.remaining) * 100) // self.total)
    print '@@@STEP_CLEAR@@@'
    print '@@@STEP_TEXT@ %3d%% +%d -%d @@@' % (
        percent, self.succeeded, len(self.failed))


class CompactProgressIndicator(ProgressIndicator):
  """Continuously updates a single line w/ a summary of progress of the run."""

  def __init__(self, cases, context, templates):
    super(CompactProgressIndicator, self).__init__(cases, context)
    self.templates = templates
    self.last_status_length = 0
    self.start_time = time.time()

  def Starting(self):
    """Called at the beginning before any tests are run."""
    pass

  def Done(self):
    """Called when all tests are complete."""
    self._PrintProgress('Done')

  def AboutToRun(self, case):
    """Called before each test case is run."""
    self._PrintProgress(case.GetLabel())

  def HasRun(self, output):
    """Called after each test case is run."""
    if output.UnexpectedOutput():
      self.ClearLine(self.last_status_length)
      self.PrintFailureHeader(output.test)
      stdout = output.output.stdout.strip()
      if stdout:
        print self.templates['stdout'] % stdout
      stderr = output.output.stderr.strip()
      if stderr:
        print self.templates['stderr'] % stderr
      print 'Command: %s' % EscapeCommand(output.command)
      if output.HasCrashed():
        print '--- CRASHED ---'
      if output.HasTimedOut():
        print '--- TIMEOUT ---'

  def _Truncate(self, buf, length):
    """Truncate a line if it exceeds length, substituting an ellipsis..."""
    if length and (len(buf) > (length - 3)):
      return buf[:(length-3)] + '...'
    else:
      return buf

  def _PrintProgress(self, name):
    """Refresh the display."""
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
    status = self._Truncate(status, 78)
    self.last_status_length = len(status)
    print status,
    sys.stdout.flush()

  def ClearLine(self, last_line_length):
    """Erase the current line w/ a linefeed and overwriting with spaces."""
    print ('\r' + (' ' * last_line_length) + '\r'),


class MonochromeProgressIndicator(CompactProgressIndicator):
  """A CompactProgressIndicator with no color."""

  def __init__(self, cases, context):
    templates = {
        'status_line': '[%(mins)02i:%(secs)02i|%%%(percent) '
        '4d|+%(passed) 4d|-%(failed) 4d]: %(test)s',
        'stdout': '%s',
        'stderr': '%s',
        'clear': lambda last_line_len: self.ClearLine(last_line_len),
        'max_length': 78
    }
    super(MonochromeProgressIndicator, self).__init__(cases,
                                                      context,
                                                      templates)


class ColorProgressIndicator(CompactProgressIndicator):
  """A CompactProgressIndicator with pretty colors."""

  def __init__(self, cases, context):
    templates = {
        'status_line': ('[%(mins)02i:%(secs)02i|%%%(percent) 4d|'
                        '\033[32m+%(passed) 4d'
                        '\033[0m|\033[31m-%(failed) 4d\033[0m]: %(test)s'),
        'stdout': '%s',
        'stderr': '%s',
        'clear': lambda last_line_len: self.ClearLine(last_line_len),
        'max_length': 78
    }
    super(ColorProgressIndicator, self).__init__(cases, context, templates)


PROGRESS_INDICATORS = {
    'verbose': VerboseProgressIndicator,
    'mono': MonochromeProgressIndicator,
    'color': ColorProgressIndicator,
    'line': OneLineProgressIndicator,
    'buildbot': OneLineProgressIndicatorForBuildBot,
    'status': StatusFileProgressIndicator,
}


# -------------------------
# --- F r a m e w o r k ---
# -------------------------


class TestCase(object):
  """A single test case, like running 'dart' on a single .dart file."""

  def __init__(self, context, path):
    self.path = path
    self.context = context
    self.duration = None
    self.arch = []
    self.component = []

  def IsBatchable(self):
    if self.context.use_batch:
      if self.component and 'dartc' in self.component:
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

  def RunCommand(self, command, cwd=None, cleanup=True):
    full_command = self.context.processor(command)
    try:
      output = test_runner.Execute(full_command, self.context,
                                   self.context.timeout, cwd)
    except OSError as e:
      raise utils.ToolError('%s: %s' % (full_command[0], e.strerror))
    test_output = test_runner.TestOutput(self, full_command, output)
    if cleanup: self.Cleanup()
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


class TestConfiguration(object):
  """Test configurations give test.py the list of tests, e.g. listing a dir."""

  def __init__(self, context, root):
    self.context = context
    self.root = root

  def Contains(self, path, filename):
    """Returns True if the given path regexp matches the passed filename."""

    if len(path) > len(filename):
      return False
    for i in xrange(len(path)):
      try:
        if not path[i].match(filename[i]):
          return False
      except:
        print 'Invalid regexp %s in .status file. ' % '/'.join(path)
        print 'Try escaping special characters with \\'
        raise

    return True

  def GetTestStatus(self, sections, defs):
    pass


class TestSuite(object):

  def __init__(self, name):
    self.name = name

  def GetName(self):
    return self.name


class TestRepository(TestSuite):
  """A collection of test configurations."""

  def __init__(self, path):
    normalized_path = os.path.abspath(path)
    super(TestRepository, self).__init__(os.path.basename(normalized_path))
    self.path = normalized_path
    self.is_loaded = False
    self.config = None

  def GetConfiguration(self, context):
    """Retrieve a TestConfiguration subclass for this set of tests."""
    if self.is_loaded:
      return self.config
    self.is_loaded = True
    filename = None
    try:
      (filename, pathname, description) = imp.find_module(
          'testcfg', [self.path])
      module = imp.load_module('testcfg', filename, pathname, description)
      self.config = module.GetConfiguration(context, self.path)
    finally:
      if filename:
        filename.close()
    return self.config

  def ListTests(self, current_path, path, context, mode, arch, component):
    return self.GetConfiguration(context).ListTests(current_path,
                                                    path,
                                                    mode,
                                                    arch,
                                                    component)

  def GetTestStatus(self, context, sections, defs):
    self.GetConfiguration(context).GetTestStatus(sections, defs)


class LiteralTestSuite(TestSuite):
  """Represents one set of tests."""

  def __init__(self, tests):
    super(LiteralTestSuite, self).__init__('root')
    self.tests = tests

  def ListTests(self, current_path, path, context, mode, arch, component):
    name = path[0]
    result = []
    for test in self.tests:
      test_name = test.GetName()
      if name.match(test_name):
        full_path = current_path + [test_name]
        result += test.ListTests(full_path, path, context, mode, arch, component)
    return result

  def GetTestStatus(self, context, sections, defs):
    for test in self.tests:
      test.GetTestStatus(context, sections, defs)


class Context(object):
  """A way to send global context for the test run to each test case."""

  def __init__(self, workspace, verbose, os_name, timeout,
               processor, suppress_dialogs, executable, flags,
               keep_temporary_files, use_batch):
    self.workspace = workspace
    self.verbose = verbose
    self.os = os_name
    self.timeout = timeout
    self.processor = processor
    self.suppress_dialogs = suppress_dialogs
    self.executable = executable
    self.flags = flags
    self.keep_temporary_files = keep_temporary_files
    self.use_batch = use_batch == 'true'

  def GetBuildRoot(self, mode, arch):
    """The top level directory containing compiler, runtime, tools..."""
    result = utils.GetBuildRoot(self.os, mode, arch)
    return result

  def GetBuildConf(self, mode, arch):
    result = utils.GetBuildConf(mode, arch)
    return result

  def GetExecutable(self, mode, arch, path):
    """Returns the name of the executable used to run the test."""
    if self.executable is not None:
      return self.executable
    if utils.IsWindows() and not path.endswith('.exe'):
      return path + '.exe'
    else:
      return path

  def GetD8(self, mode, arch):
    d8 = os.path.join(self.GetBuildRoot(mode, arch), 'd8')
    return self.GetExecutable(mode, arch, d8)

  def GetDart(self, mode, arch, component):
    dart = utils.GetDartRunner(mode, arch, component)
    return [self.GetExecutable(mode, arch, dart)]

  def GetDartC(self, mode, arch):
    """Returns the path to the Dart --> JS compiler."""
    dartc = os.path.abspath(os.path.join(
        self.GetBuildRoot(mode, arch), 'compiler', 'bin', 'dartc'))
    if utils.IsWindows(): dartc += '.exe'
    command = [dartc]

    # Add the flags from the context to the command line.
    command += self.flags
    return command

  def GetRunTests(self, mode, arch):
    path = os.path.join(self.GetBuildRoot(mode, arch), 'run_vm_tests')
    return [self.GetExecutable(mode, arch, path)]


def RunTestCases(cases_to_run, progress, tasks, context):
  """Chooses a progress indicator and then starts the tests."""
  progress = PROGRESS_INDICATORS[progress](cases_to_run, context)
  return progress.Run(tasks)


# -------------------------------------------
# --- T e s t   C o n f i g u r a t i o n ---
# -------------------------------------------


class Expression(object):
  pass


class Constant(Expression):

  def __init__(self, value):
    super(Constant, self).__init__()
    self.value = value

  def Evaluate(self, unused_env, unused_defs):
    return self.value


class Variable(Expression):

  def __init__(self, name):
    super(Variable, self).__init__()
    self.name = name

  def GetOutcomes(self, env, unused_defs):
    if self.name in env:
      return ListSet([env[self.name]])
    else: return Nothing()

  def Evaluate(self, env, defs):
    return env[self.name]


class Outcome(Expression):

  def __init__(self, name):
    super(Outcome, self).__init__()
    self.name = name

  def GetOutcomes(self, env, defs):
    if self.name in defs:
      return defs[self.name].GetOutcomes(env, defs)
    else:
      return ListSet([self.name])


class Set(object):
  """An abstract set class used to hold Rules."""
  pass


class ListSet(Set):
  """A set that uses lists for storage."""

  def __init__(self, elms):
    super(ListSet, self).__init__()
    self.elms = elms

  def __str__(self):
    return 'ListSet%s' % str(self.elms)

  def Intersect(self, that):
    if not isinstance(that, ListSet):
      return that.Intersect(self)
    return ListSet([x for x in self.elms if x in that.elms])

  def Union(self, that):
    if not isinstance(that, ListSet):
      return that.Union(self)
    return ListSet(self.elms +
                   [x for x in that.elms if x not in self.elms])

  def IsEmpty(self):
    return not self.elms


class Everything(Set):
  """A set that represents all possible values."""

  def Intersect(self, that):
    return that

  def Union(self, unused_that):
    return self

  def IsEmpty(self):
    return False


class Nothing(Set):

  def Intersect(self, unused_that):
    return self

  def Union(self, that):
    return that

  def IsEmpty(self):
    return True


class Operation(Expression):
  """A conditional expression. e.g. ($arch == ia32)."""

  def __init__(self, left, op, right):
    super(Operation, self).__init__()
    self.left = left
    self.op = op
    self.right = right

  def Evaluate(self, env, defs):
    """Evaluates expression in the .status file. e.g. ($arch == ia32)."""
    if self.op == '||' or self.op == ',':
      return self.left.Evaluate(env, defs) or self.right.Evaluate(env, defs)
    elif self.op == 'if':
      return False
    elif self.op == '==':
      outcomes = self.left.GetOutcomes(env, defs)
      inter = outcomes.Intersect(self.right.GetOutcomes(env, defs))
      return not inter.IsEmpty()
    else:
      assert self.op == '&&'
      return self.left.Evaluate(env, defs) and self.right.Evaluate(env, defs)

  def GetOutcomes(self, env, defs):
    if self.op == '||' or self.op == ',':
      outcomes = self.left.GetOutcomes(env, defs)
      return outcomes.Union(self.right.GetOutcomes(env, defs))
    elif self.op == 'if':
      if self.right.Evaluate(env, defs):
        return self.left.GetOutcomes(env, defs)
      else: return Nothing()
    else:
      assert self.op == '&&'
      outcomes = self.left.GetOutcomes(env, defs)
      return outcomes.Intersect(self.right.GetOutcomes(env, defs))


def IsAlpha(buf):
  """Returns True if the entire string is alphanumeric."""
  for char in buf:
    if not (char.isalpha() or char.isdigit() or char == '_'):
      return False
  return True


class Tokenizer(object):
  """Tokenizer that chops expressions into variables, parens and operators."""

  def __init__(self, expr):
    self.index = 0
    self.expr = expr
    self.length = len(expr)
    self.tokens = None

  def Current(self, length=1):
    if not self.HasMore(length): return ''
    return self.expr[self.index:self.index+length]

  def HasMore(self, length=1):
    return self.index < self.length + (length - 1)

  def Advance(self, count=1):
    self.index += count

  def AddToken(self, token):
    self.tokens.append(token)

  def SkipSpaces(self):
    while self.HasMore() and self.Current().isspace():
      self.Advance()

  def Tokenize(self):
    """Lexical analysis of an expression in a .status file.

    Example:
      [ $mode == debug && ($component == chromium || $component == dartc) ]

    Args:
      None.

    Returns:
      A list of tokens on success, None on failure.
    """

    self.tokens = []
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
        buf = ''
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
  """A simple scanner that can serve out tokens from a given list."""

  def __init__(self, tokens):
    self.tokens = tokens
    self.length = len(tokens)
    self.index = 0

  def HasMore(self):
    return self.index < self.length

  def Current(self):
    return self.tokens[self.index]

  def Advance(self):
    self.index += 1


def ParseAtomicExpression(scan):
  """Parse an single (non recursive) expression in a .status file."""

  if scan.Current() == 'true':
    scan.Advance()
    return Constant(True)
  elif scan.Current() == 'false':
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


def ParseOperatorExpression(scan):
  """Parse an expression that has operators."""
  left = ParseAtomicExpression(scan)
  if not left: return None
  while scan.HasMore() and (scan.Current() in ['==']):
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
    left = Operation(left, 'if', right)
  return left


def ParseLogicalExpression(scan):
  """Parse a binary expression separated by boolean operators."""
  left = ParseConditionalExpression(scan)
  if not left: return None
  while scan.HasMore() and (scan.Current() in ['&&', '||', ',']):
    op = scan.Current()
    scan.Advance()
    right = ParseConditionalExpression(scan)
    if not right:
      return None
    left = Operation(left, op, right)
  return left


def ParseCondition(expr):
  """Parses a boolean expression into an Expression object."""
  tokens = Tokenizer(expr).Tokenize()
  if not tokens:
    print 'Malformed expression: "%s"' % expr
    return None
  scan = Scanner(tokens)
  ast = ParseLogicalExpression(scan)
  if not ast:
    print 'Malformed expression: "%s"' % expr
    return None
  if scan.HasMore():
    print 'Malformed expression: "%s"' % expr
    return None
  return ast


class ClassifiedTest(object):

  def __init__(self, case, outcomes):
    self.case = case
    self.outcomes = outcomes


class Configuration(object):
  """The parsed contents of a configuration file."""

  def __init__(self, sections, defs):
    self.sections = sections
    self.defs = defs

  def ClassifyTests(self, cases, env):
    """Matches a test case with the test prefixes requested on the cmdline.

    This 'wraps' each TestCase object with some meta information
    about the test.

    Args:
      cases: list of TestCase objects to classify.
      env:   dictionary containing values for 'mode',
             'system', 'component', 'arch' and 'checked'.

    Returns:
      A triplet of (result, rules, expected_outcomes).
    """
    sections = [s for s in self.sections
                if s.condition.Evaluate(env, self.defs)]
    all_rules = reduce(list.__add__, [s.rules for s in sections], [])
    unused_rules = set(all_rules)
    result = []
    all_outcomes = set([])
    for case in cases:
      matches = [r for r in all_rules if r.Contains(case.path)]
      outcomes = set([])
      for rule in matches:
        outcomes = outcomes.union(rule.GetOutcomes(env, self.defs))
        unused_rules.discard(rule)
      if not outcomes:
        outcomes = [testing.PASS]
      case.outcomes = outcomes
      all_outcomes = all_outcomes.union(outcomes)
      result.append(ClassifiedTest(case, outcomes))
    return (result, list(unused_rules), all_outcomes)


class Section(object):
  """A section of the configuration file.

     Sections are enabled or disabled prior to running the tests,
     based on their conditions.
  """

  def __init__(self, condition):
    self.condition = condition
    self.rules = []

  def AddRule(self, rule):
    self.rules.append(rule)


class Rule(object):
  """A single rule that specifies the expected outcome for a single test."""

  def __init__(self, raw_path, path, value):
    self.raw_path = raw_path
    self.path = path
    self.value = value

  def GetOutcomes(self, env, defs):
    outcomes = self.value.GetOutcomes(env, defs)
    assert isinstance(outcomes, ListSet)
    return outcomes.elms

  def Contains(self, path):
    """Returns True if the specified path matches this rule (regexp)."""
    if len(self.path) > len(path):
      return False
    for i in xrange(len(self.path)):
      try:
        if not self.path[i].match(path[i]):
          return False
      except:
        print 'Invalid regexp %s in .status file. ' % '/'.join(path)
        print 'Try escaping special characters with \\'
        raise
    return True


HEADER_PATTERN = re.compile(r'\[([^]]+)\]')
RULE_PATTERN = re.compile(r'\s*([^: ]*)\s*:(.*)')
DEF_PATTERN = re.compile(r'^def\s*(\w+)\s*=(.*)$')
PREFIX_PATTERN = re.compile(r'^\s*prefix\s+([\w\_\.\-\/]+)$')


def ReadConfigurationInto(path, sections, defs):
  """Parses a .status file into specified sections and defs arguments."""
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
      path = prefix + _SplitPath(rule_match.group(1).strip())
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
      prefix = _SplitPath(prefix_match.group(1).strip())
      continue
    print 'Malformed line: "%s".' % line
    return False
  return True


# ---------------
# --- M a i n ---
# ---------------


def BuildOptions():
  """Configures the Python optparse library with the cmdline for test.py."""
  result = optparse.OptionParser()
  result.add_option(
      '-m', '--mode',
      help='The test modes in which to run (comma-separated)',
      metavar='[all,debug,release]',
      default='debug')
  result.add_option(
      '-v', '--verbose',
      help='Verbose output',
      default=False,
      action='store_true')
  result.add_option(
      '-p', '--progress',
      help='The style of progress indicator (verbose, line, color, mono)',
      choices=PROGRESS_INDICATORS.keys(),
      default=None)
  result.add_option(
      '--report',
      help='Print a summary of the tests to be run',
      default=False,
      action='store_true')
  result.add_option(
      '--list',
      help='List all the tests, but don\'t run them',
      default=False,
      action='store_true')
  result.add_option(
      '-s', '--suite',
      help='A test suite',
      default=[],
      action='append')
  result.add_option(
      '-t', '--timeout',
      help='Timeout in seconds',
      default=None,
      type='int')
  result.add_option(
      '--checked',
      help='Run tests in checked mode',
      default=False,
      action='store_true')
  result.add_option(
      '--flag',
      help='Pass this additional flag to the VM',
      default=[],
      action='append')
  result.add_option(
      '--arch',
      help='The architecture to run tests for',
      metavar='[all,ia32,x64,simarm,arm]',
      default=ARCH_GUESS)
  result.add_option(
      '--os',
      help='The OS to run tests on',
      default=OS_GUESS)
  result.add_option(
      '--valgrind',
      help='Run tests through valgrind',
      default=False,
      action='store_true')
  result.add_option(
      '-j', '--tasks',
      help='The number of parallel tasks to run',
      metavar=testing.HOST_CPUS,
      default=testing.USE_DEFAULT_CPUS,
      type='int')
  result.add_option(
      '--time',
      help='Print timing information after running',
      default=False,
      action='store_true')
  result.add_option(
      '--executable',
      help='The executable with which to run the tests',
      default=None)
  result.add_option(
      '--keep_temporary_files',
      help='Do not delete temporary files after running the tests',
      default=False,
      action='store_true')
  result.add_option(
      '--batch',
      help='Run multiple tests for dartc component in a single vm',
      choices=['true', 'false'],
      default='true',
      type='choice')
  result.add_option(
      '--optimize',
      help='Invoke dart compiler with --optimize flag',
      default=False,
      action='store_true')
  result.add_option(
      '-c', '--component',
      help='The component to test against '
           '(most, vm, dartc, frog, frogsh, chromium, dartium)',
      metavar='[most,vm,dartc,chromium,dartium]',
      default='vm')
  return result


def ProcessOptions(options):
  """Process command line options."""
  if options.arch == 'all':
    options.arch = 'ia32,x64,simarm'
  if options.mode == 'all':
    options.mode = 'debug,release'
  if options.component == 'most':
    options.component = 'vm,dartc'

  # By default we run with a higher timeout setting in when running on
  # a simulated architecture and in debug mode.
  if not options.timeout:
    options.timeout = TIMEOUT_SECS
    if 'dartc' in options.component:
      options.timeout *= 4
    elif 'chromium' in options.component:
      options.timeout *= 4
    elif 'dartium' in options.component:
      options.timeout *= 4
    elif 'debug' in options.mode:
      options.timeout *= 2
  options.mode = options.mode.split(',')
  options.arch = options.arch.split(',')
  options.component = options.component.split(',')
  for mode in options.mode:
    if not mode in ['debug', 'release']:
      print 'Unknown mode %s' % mode
      return False
  for arch in options.arch:
    if not arch in ['ia32', 'x64', 'simarm', 'arm']:
      print 'Unknown arch %s' % arch
      return False
  for component in options.component:
    if not component in ['vm', 'dartc', 'frog', 'frogsh',
                         'chromium', 'dartium']:
      print 'Unknown component %s' % component
      return False
  options.flags = []
  options.flags.append('--ignore-unrecognized-flags')
  if options.checked:
    options.flags.append('--enable_asserts')
    options.flags.append('--enable_type_checks')
  if options.optimize:
    options.flags.append('--optimize')
  for flag in options.flag:
    options.flags.append(flag)
  if options.verbose:
    print 'Flags on the command line:'
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
  """Print a breakdown of which tests are marked pass/skip/fail."""

  def IsFlaky(o):
    return ((testing.PASS in o) and (testing.FAIL in o)
            and (not testing.CRASH in o) and (not testing.OKAY in o))

  def IsFailOk(o):
    return (len(o) == 2) and (testing.FAIL in o) and (testing.OKAY in o)

  unskipped = [c for c in cases if not testing.SKIP in c.outcomes]
  print REPORT_TEMPLATE % {
      'total': len(cases),
      'skipped': len(cases) - len(unskipped),
      'nocrash': len([t for t in unskipped if IsFlaky(t.outcomes)]),
      'pass': len([t for t in unskipped
                   if list(t.outcomes) == [testing.PASS]]),
      'fail_ok': len([t for t in unskipped
                      if IsFailOk(t.outcomes)]),
      'fail': len([t for t in unskipped
                   if list(t.outcomes) == [testing.FAIL]]),
      'crash': len([t for t in unskipped
                    if list(t.outcomes) == [testing.CRASH]]),
      'batched': len([t for t in unskipped if t.case.IsBatchable()])
  }


def PrintTests(cases):
  """Print a table of the tests to be run (--list cmdline option)."""
  has_errors = False
  for case in cases:
    try:
      case.case.GetCommand()
    except:
      # Python can throw an exception while parsing the .dart file.
      # We don't want to end the program.
      # TODO(zundel): something better... its a bit of a hack.
      sys.stderr.write(case.case.filename + '\n')
      has_errors = True
  if has_errors:
    raise Exception('Errors in above files')
  for case in [c for c in cases if not testing.SKIP in c.outcomes]:
    print '%s\t%s\t%s\t%s' %('/'.join(case.case.path),
                             ','.join(case.outcomes),
                             case.case.IsNegative(),
                             '\t'.join(case.case.GetCommand()[1:]))


class Pattern(object):
  """Convenience class to hold a compiled re pattern."""

  def __init__(self, pattern):
    self.pattern = pattern
    self.compiled = None

  def match(self, buf):
    if not self.compiled:
      pattern = '^%s$' % self.pattern.replace('*', '.*')
      self.compiled = re.compile(pattern)
    return self.compiled.match(buf)

  def __str__(self):
    return self.pattern


def _SplitPath(s):
  """Split a path into directories - opposite of os.path.join()?"""
  stripped = [c.strip() for c in s.split('/')]
  return [Pattern(s) for s in stripped if s]


def GetSpecialCommandProcessor(value):
  if (not value) or (value.find('@') == -1):

    def ExpandCommand(args):
      return args

    return ExpandCommand
  else:
    pos = value.find('@')
    prefix = urllib.unquote(value[:pos]).split()
    suffix = urllib.unquote(value[pos+1:]).split()

    def ExpandCommand(args):
      return prefix + args + suffix

    return ExpandCommand


def GetSuites(test_root):
  def IsSuite(path):
    return os.path.isdir(path) and os.path.exists(
        os.path.join(path, 'testcfg.py'))
  return [f for f in os.listdir(test_root) if IsSuite(
      os.path.join(test_root, f))]


def FormatTime(d):
  millis = round(d * 1000) % 1000
  return time.strftime('%M:%S.', time.gmtime(d)) + ('%03i' % millis)


def Main():
  """Main loop."""
  utils.ConfigureJava()
  parser = BuildOptions()
  (options, args) = parser.parse_args()
  if not ProcessOptions(options):
    parser.print_help()
    return 1

  client = os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]), '..'))
  repositories = []
  for component in os.listdir(client) + ['.']:
    test_path = os.path.join(client, component, 'tests')
    if os.path.exists(test_path) and os.path.isdir(test_path):
      suites = GetSuites(test_path)
      repositories += [TestRepository(os.path.join(test_path, name))
                       for name in suites]
  repositories += [TestRepository(a) for a in options.suite]

  root = LiteralTestSuite(repositories)
  if args:
    paths = []
    for arg in args:
      path = _SplitPath(arg)
      paths.append(path)
  else:
    paths = [_SplitPath(t) for t in BUILT_IN_TESTS]

  # Check for --valgrind option. If enabled, we overwrite the special
  # command flag with a command that uses the tools/valgrind.py script.
  if options.valgrind:
    run_valgrind = os.path.join(client, 'runtime', 'tools', 'valgrind.py')
    options.special_command = 'python -u ' + run_valgrind + ' @'

  context = Context(client,
                    options.verbose,
                    options.os,
                    options.timeout,
                    GetSpecialCommandProcessor(options.special_command),
                    options.suppress_dialogs,
                    options.executable,
                    options.flags,
                    options.keep_temporary_files,
                    options.batch)

  # Get status for tests
  sections = []
  defs = {}
  root.GetTestStatus(context, sections, defs)
  config = Configuration(sections, defs)

  # List the tests
  all_cases = []
  all_unused = []
  globally_unused_rules = None
  for path in paths:
    for mode in options.mode:
      for arch in options.arch:
        for component in options.component:
          env = {
              'mode': mode,
              'system': utils.GuessOS(),
              'arch': arch,
              'component': component,
              'checked': options.checked,
              'unchecked': not options.checked,
          }
          test_list = root.ListTests([], path, context, mode, arch, component)
          (cases, unused_rules, unused_outcomes) = config.ClassifyTests(
              test_list, env)
          if globally_unused_rules is None:
            globally_unused_rules = set(unused_rules)
          else:
            globally_unused_rules = (
                globally_unused_rules.intersection(unused_rules))
          all_cases += cases
          all_unused.append(unused_rules)

  if options.report:
    PrintReport(all_cases)

  if options.list:
    PrintTests(all_cases)
    return 0

  result = None

  def DoSkip(case):
    return testing.SKIP in case.outcomes or testing.SLOW in case.outcomes

  cases_to_run = [c for c in all_cases if not DoSkip(c)]
  # Creating test cases may generate temporary files. Make sure
  # Skipped tests clean up these files.
  for c in all_cases:
    if DoSkip(c): c.case.Cleanup()

  if cases_to_run:
    try:
      start = time.time()
      if RunTestCases(cases_to_run, options.progress, options.tasks,
                      context):
        result = 0
      else:
        result = 1
      duration = time.time() - start
    except KeyboardInterrupt:
      print 'Exiting on KeyboardInterrupt'
      return 1
  else:
    print 'No tests to run.'
    return 0

  if options.time:
    print
    print '--- Total time: %s ---' % FormatTime(duration)
    timed_tests = [t.case for t in cases_to_run if not t.case.duration is None]
    timed_tests.sort(lambda a, b: a.CompareTime(b))
    index = 1
    for entry in timed_tests[:20]:
      t = FormatTime(entry.duration)
      print '%4i (%s) %s' % (index, t, entry.GetLabel())
      index += 1

  return result


if __name__ == '__main__':
  sys.exit(Main())
