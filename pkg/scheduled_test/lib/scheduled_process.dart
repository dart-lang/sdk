// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_test.scheduled_process;

import 'dart:async';
import 'dart:io';

import 'scheduled_test.dart';
import 'src/utils.dart';
import 'src/value_future.dart';

/// A class representing a [Process] that is scheduled to run in the course of
/// the test. This class allows actions on the process to be scheduled
/// synchronously. All operations on this class are scheduled.
///
/// Before running the test, either [shouldExit] or [kill] must be called on
/// this to ensure that the process terminates when expected.
///
/// If the test fails, this will automatically print out any stdout and stderr
/// from the process to aid debugging.
class ScheduledProcess {
  /// A description of the process. Used for error reporting.
  String get description => _description;
  String _description;

  /// Whether a description was passed explicitly by the user.
  bool _explicitDescription;

  /// The encoding used for the process's input and output streams.
  final Encoding _encoding;

  /// The process that's scheduled to run.
  ValueFuture<Process> _process;

  /// A fork of [_stdout] that records the standard output of the process. Used
  /// for debugging information.
  Stream<String> _stdoutLog;

  /// A line-by-line view of the standard output stream of the process.
  Stream<String> _stdout;

  /// A canceller that controls both [_stdout] and [_stdoutLog].
  StreamCanceller _stdoutCanceller;

  /// A fork of [_stderr] that records the standard error of the process. Used
  /// for debugging information.
  Stream<String> _stderrLog;

  /// A line-by-line view of the standard error stream of the process.
  Stream<String> _stderr;

  /// A canceller that controls both [_stderr] and [_stderrLog].
  StreamCanceller _stderrCanceller;

  /// The exit code of the process that's scheduled to run. This will naturally
  /// only complete once the process has terminated.
  ValueFuture<int> _exitCode;

  /// Whether the user has scheduled the end of this process by calling either
  /// [shouldExit] or [kill].
  var _endScheduled = false;

  /// The task that runs immediately before this process is scheduled to end. If
  /// the process ends during this task, we treat that as expected.
  Task _taskBeforeEnd;

  /// Whether the process is expected to terminate at this point.
  var _endExpected = false;

  /// Schedules a process to start. [executable], [arguments], and [options]
  /// have the same meaning as for [Process.start]. [description] is a string
  /// description of this process; it defaults to the command-line invocation.
  /// [encoding] is the [Encoding] that will be used for the process's input and
  /// output.
  ///
  /// [executable], [arguments], and [options] may be either a [Future] or a
  /// concrete value. If any are [Future]s, the process won't start until the
  /// [Future]s have completed. In addition, [arguments] may be a [List]
  /// containing a mix of strings and [Future]s.
  ScheduledProcess.start(executable, arguments,
      {options, String description, Encoding encoding: Encoding.UTF_8})
      : _encoding = encoding,
        _explicitDescription = description != null,
        _description = description {
    assert(currentSchedule.state == ScheduleState.SET_UP);

    _updateDescription(executable, arguments);

    _scheduleStartProcess(executable, arguments, options);

    _scheduleExceptionCleanup();

    var stdoutWithCanceller = _lineStreamWithCanceller(
        _process.then((p) => p.stdout));
    _stdoutCanceller = stdoutWithCanceller.last;
    var stdoutTee = tee(stdoutWithCanceller.first);
    _stdout = stdoutTee.first;
    _stdoutLog = stdoutTee.last;

    var stderrWithCanceller = _lineStreamWithCanceller(
        _process.then((p) => p.stderr));
    _stderrCanceller = stderrWithCanceller.last;
    var stderrTee = tee(stderrWithCanceller.first);
    _stderr = stderrTee.first;
    _stderrLog = stderrTee.last;
  }

  /// Updates [_description] to reflect [executable] and [arguments], which are
  /// the same values as in [start].
  void _updateDescription(executable, arguments) {
    if (_explicitDescription) return;
    if (executable is Future) {
      _description = "future process";
    } else if (arguments is Future || arguments.any((e) => e is Future)) {
      _description = executable;
    } else {
      _description = "$executable ${arguments.map((a) => '"$a"').join(' ')}";
    }
  }

  /// Schedules the process to start and sets [_process].
  void _scheduleStartProcess(executable, arguments, options) {
    var exitCodeCompleter = new Completer();
    _exitCode = new ValueFuture(exitCodeCompleter.future);

    _process = new ValueFuture(schedule(() {
      if (!_endScheduled) {
        throw new StateError("Scheduled process '$description' must "
            "have shouldExit() or kill() called before the test is run.");
      }

      _handleExit(exitCodeCompleter);

      return Future.wait([
        new Future.sync(() => executable),
        awaitObject(arguments),
        new Future.sync(() => options)
      ]).then((results) {
        executable = results[0];
        arguments = results[1];
        options = results[2];
        _updateDescription(executable, arguments);
        return Process.start(executable, arguments, options).then((process) {
          // TODO(nweiz): enable this when issue 9020 is fixed.
          // process.stdin.encoding = Encoding.UTF_8;
          return process;
        });
      });
    }, "starting process '$description'"));
  }

  /// Listens for [_process] to exit and passes the exit code to
  /// [exitCodeCompleter]. If the process completes earlier than expected, an
  /// exception will be signaled to the schedule.
  void _handleExit(Completer exitCodeCompleter) {
    // We purposefully avoid using wrapFuture here. If an error occurs while a
    // process is running, we want the schedule to move to the onException
    // queue where the process will be killed, rather than blocking the tasks
    // queue waiting for the process to exit.
    _process.then((p) => p.exitCode).then((exitCode) {
      if (_endExpected) {
        exitCodeCompleter.complete(exitCode);
        return;
      }

      wrapFuture(pumpEventQueue().then((_) {
        if (currentSchedule.currentTask != _taskBeforeEnd) return;
        // If we're one task before the end was scheduled, wait for that task
        // to complete and pump the event queue so that _endExpected will be
        // set.
        return _taskBeforeEnd.result.then((_) => pumpEventQueue());
      }).then((_) {
        exitCodeCompleter.complete(exitCode);

        if (!_endExpected) {
          throw "Process '$description' ended earlier than scheduled "
            "with exit code $exitCode.";
        }
      }), "waiting to reach shouldExit() or kill() for process "
          "'$description'");
    });
  }

  /// Converts a stream of bytes to a stream of lines and returns that along
  /// with a [StreamCanceller] controlling it.
  Pair<Stream<String>, StreamCanceller> _lineStreamWithCanceller(
      Future<Stream<int>> streamFuture) {
    return streamWithCanceller(futureStream(streamFuture)
        .handleError((e) => currentSchedule.signalError(e))
        .transform(new StringDecoder(_encoding))
        .transform(new LineTransformer()));
  }

  /// Schedule an exception handler that will clean up the process and provide
  /// debug information if an error occurs.
  void _scheduleExceptionCleanup() {
    currentSchedule.onException.schedule(() {
      _stdoutCanceller();
      _stderrCanceller();

      if (!_process.hasValue) return;

      var killedPrematurely = false;
      if (!_exitCode.hasValue) {
        killedPrematurely = true;
        _endExpected = true;
        _process.value.kill();
        // Ensure that the onException queue waits for the process to actually
        // exit after being killed.
        wrapFuture(_process.value.exitCode, "waiting for process "
            "'$description' to die");
      }

      return Future.wait([
        _stdoutLog.toList(),
        _stderrLog.toList()
      ]).then((results) {
        var stdout = results[0].join("\n");
        var stderr = results[1].join("\n");

        var exitDescription = killedPrematurely
            ? "Process was killed prematurely."
            : "Process exited with exit code ${_exitCode.value}.";
        currentSchedule.addDebugInfo(
            "Results of running '$description':\n"
            "$exitDescription\n"
            "Standard output:\n"
            "${prefixLines(stdout)}\n"
            "Standard error:\n"
            "${prefixLines(stderr)}");
      });
    }, "cleaning up process '$description'");
  }

  /// Reads the next line of stdout from the process.
  Future<String> nextLine() => schedule(() => streamFirst(_stdout),
      "reading the next stdout line from process '$description'");

  /// Reads the next line of stderr from the process.
  Future<String> nextErrLine() => schedule(() => streamFirst(_stderr),
      "reading the next stderr line from process '$description'");

  /// Reads the remaining stdout from the process. This should only be called
  /// after kill() or shouldExit().
  Future<String> remainingStdout() {
    if (!_endScheduled) {
      throw new StateError("remainingStdout() should only be called after "
          "kill() or shouldExit().");
    }

    return schedule(() => _stdout.toList().then((lines) => lines.join("\n")),
        "reading the remaining stdout from process '$description'");
  }

  /// Reads the remaining stderr from the process. This should only be called
  /// after kill() or shouldExit().
  Future<String> remainingStderr() {
    if (!_endScheduled) {
      throw new StateError("remainingStderr() should only be called after "
          "kill() or shouldExit().");
    }

    return schedule(() => _stderr.toList().then((lines) => lines.join("\n")),
        "reading the remaining stderr from process '$description'");
  }

  /// Writes [line] to the process as stdin.
  void writeLine(String line) {
    schedule(() {
      return _process.then((p) => p.stdin.writeln('$line'));
    }, "writing '$line' to stdin for process '$description'");
  }

  /// Closes the process's stdin stream.
  void closeStdin() {
    schedule(() => _process.then((p) => p.stdin.close()),
        "closing stdin for process '$description'");
  }

  /// Kills the process, and waits until it's dead.
  void kill() {
    if (_endScheduled) {
      throw new StateError("shouldExit() or kill() already called.");
    }

    _endScheduled = true;
    _taskBeforeEnd = currentSchedule.tasks.contents.last;
    schedule(() {
      _endExpected = true;
      return _process.then((p) => p.kill()).then((_) => _exitCode);
    }, "waiting for process '$description' to die");
  }

  /// Waits for the process to exit, and verifies that the exit code matches
  /// [expectedExitCode] (if given).
  void shouldExit([int expectedExitCode]) {
    if (_endScheduled) {
      throw new StateError("shouldExit() or kill() already called.");
    }

    _endScheduled = true;
    _taskBeforeEnd = currentSchedule.tasks.contents.last;
    schedule(() {
      _endExpected = true;
      return _exitCode.then((exitCode) {
        if (expectedExitCode != null) {
          expect(exitCode, equals(expectedExitCode));
        }
      });
    }, "waiting for process '$description' to exit");
  }
}
