#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

import os
import subprocess
import sys
import tempfile
import time
import threading
import traceback
import Queue

import test
import testing
import utils


class Error(Exception):
  pass

class TestRunner(object):
  """Base class for runners """
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
          self.RecordPassFail(last_case, buf, testing.CRASH)
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

      except Queue.Empty:
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
        self.RecordPassFail(last_case, buf, testing.CRASH)

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
      assert false, "Unexpected outcome: %s" % outcome

    cmd_output = test.CommandOutput(0, exit_code,
                                    outcome == testing.TIMEOUT, stdout_buf, "")
    test_output = test.TestOutput(case.case,
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
    """Kill all active runners"""
    print "Shutting down remaining runners"
    self.terminate = True;
    for runner in self.runners.values():
      runner.kill()
    # Give threads a chance to exit gracefully
    time.sleep(2)
    for runner in self.runners.values():
      self.EndRunner(runner)
