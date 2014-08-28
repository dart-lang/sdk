// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_test.scheduled_process;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import 'scheduled_stream.dart';
import 'scheduled_test.dart';
import 'src/utils.dart';
import 'src/value_future.dart';

/// A class representing a [Process] that is scheduled to run in the course of
/// the test. This class allows actions on the process to be scheduled
/// synchronously. All operations on this class are scheduled.
///
/// Before running the test, either [shouldExit] or [kill] must be called on
/// this to ensure that the process terminates when expected. Note that [kill]
/// is using SIGKILL, to ensure the process is killed on Mac OS X (an early
/// SIGTERM on Mac OS X may be ignored).
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
  ScheduledStream<String> get stdout => _stdout;
  ScheduledStream<String> _stdout;

  /// A canceller that controls both [_stdout] and [_stdoutLog].
  StreamCanceller _stdoutCanceller;

  /// A fork of [_stderr] that records the standard error of the process. Used
  /// for debugging information.
  Stream<String> _stderrLog;

  /// A line-by-line view of the standard error stream of the process.
  ScheduledStream<String> get stderr => _stderr;
  ScheduledStream<String> _stderr;

  /// A canceller that controls both [_stderr] and [_stderrLog].
  StreamCanceller _stderrCanceller;

  /// The exit code of the process that's scheduled to run. This will naturally
  /// only complete once the process has terminated.
  ValueFuture<int> _exitCode;

  /// Whether the user has scheduled the end of this process by calling either
  /// [shouldExit] or [kill].
  bool get _endScheduled => _scheduledExitTask != null;

  /// The task where this process is scheduled to exit -- either by waiting to
  /// exit ([shouldExit]) or by killing the process ([kill]).
  ///
  /// It's legal for the process to exit before this task runs. This can happen
  /// for example if there's still standard output to read from the process
  /// after it exits.
  Task _scheduledExitTask;

  /// The task during which the process actually exited.
  Task _actualExitTask;

  /// Schedules a process to start. [executable], [arguments],
  /// [workingDirectory], and [environment] have the same meaning as for
  /// [Process.start]. [description] is a string description of this process; it
  /// defaults to the command-line invocation. [encoding] is the [Encoding] that
  /// will be used for the process's input and output.
  ///
  /// [executable], [arguments], [workingDirectory], and [environment] may be
  /// either a [Future] or a concrete value. If any are [Future]s, the process
  /// won't start until the [Future]s have completed. In addition, [arguments]
  /// may be a [List] containing a mix of strings and [Future]s.
  ScheduledProcess.start(executable, arguments,
      {workingDirectory, environment, String description,
       Encoding encoding: UTF8})
      : _encoding = encoding,
        _explicitDescription = description != null,
        _description = description {
    assert(currentSchedule.state == ScheduleState.SET_UP);

    _updateDescription(executable, arguments);

    _scheduleStartProcess(executable, arguments, workingDirectory, environment);

    _scheduleExceptionCleanup();

    var stdoutWithCanceller = _lineStreamWithCanceller(
        _process.then((p) => Chain.track(p.stdout)));
    _stdoutCanceller = stdoutWithCanceller.last;
    _stdoutLog = stdoutWithCanceller.first;

    var stderrWithCanceller = _lineStreamWithCanceller(
        _process.then((p) => Chain.track(p.stderr)));
    _stderrCanceller = stderrWithCanceller.last;
    _stderrLog = stderrWithCanceller.first;

    _stdout = new ScheduledStream<String>(stdoutStream());
    _stderr = new ScheduledStream<String>(stderrStream());
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
  void _scheduleStartProcess(executable,
                             arguments,
                             workingDirectory,
                             environment) {
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
        new Future.sync(() => workingDirectory),
        new Future.sync(() => environment)
      ]).then((results) {
        executable = results[0];
        arguments = results[1];
        workingDirectory = results[2];
        environment = results[3];
        _updateDescription(executable, arguments);
        return Chain.track(
            Process.start(executable,
                          arguments,
                          workingDirectory: workingDirectory,
                          environment: environment)).then((process) {
          process.stdin.encoding = UTF8;
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
    _process.then((p) => Chain.track(p.exitCode)).then((exitCode) {
      _actualExitTask = currentSchedule.currentTask;
      exitCodeCompleter.complete(exitCode);
    });
  }

  /// Converts a stream of byte lists to a stream of lines and returns that
  /// along with a [StreamCanceller] controlling it.
  Pair<Stream<String>, StreamCanceller> _lineStreamWithCanceller(
      Future<Stream<List<int>>> streamFuture) {
    // Ignore errors from the future. They'll be reported through [schedule].
    streamFuture = streamFuture.catchError((_) => new Stream.fromIterable([]));
    return streamWithCanceller(futureStream(streamFuture)
        .handleError(currentSchedule.signalError)
        .map((chunk) {
      // Whenever the process produces any sort of output, reset the schedule's
      // timer.
      currentSchedule.heartbeat();
      return chunk;
    })
        .transform(_encoding.decoder)
        .transform(new LineSplitter()));
  }

  /// Schedule an exception handler that will clean up the process and provide
  /// debug information if an error occurs.
  void _scheduleExceptionCleanup() {
    currentSchedule.onException.schedule(() {
      _stdoutCanceller();
      _stderrCanceller();

      if (!_process.hasValue) return null;

      var killedPrematurely = false;
      if (!_exitCode.hasValue) {
        killedPrematurely = true;
        _process.value.kill(ProcessSignal.SIGKILL);
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

        var exitDescription;
        if (killedPrematurely) {
          exitDescription = "Process was killed prematurely.";
        } else {
          exitDescription = "Process exited with exit code ${_exitCode.value}";
          if (_actualExitTask != _scheduledExitTask) {
            var taskString = _actualExitTask.toString();
            if (taskString.contains("\n")) {
              exitDescription += " in task:\n${prefixLines(taskString)}";
            } else {
              exitDescription += " in task $taskString";
            }
          }
          exitDescription += ".";
        }

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

  /// Returns a stream that will emit anything the process emits via the
  /// process's standard output from now on.
  ///
  /// This stream will be independent from any other methods that deal with
  /// standard output, including other calls to [stdoutStream].
  ///
  /// This can be overridden by subclasses to return a derived standard output
  /// stream. This stream will then be used for [stdout] and [stderr].
  Stream<String> stdoutStream() {
    var pair = tee(_stdoutLog);
    _stdoutLog = pair.first;
    return pair.last;
  }

  /// Returns a stream that will emit anything the process emits via the
  /// process's standard error from now on.
  ///
  /// This stream will be independent from any other methods that deal with
  /// standard error, including other calls to [stderrStream].
  Stream<String> stderrStream() {
    var pair = tee(_stderrLog);
    _stderrLog = pair.first;
    return pair.last;
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

    schedule(() {
      return _process
          .then((p) => p.kill(ProcessSignal.SIGKILL))
          .then((_) => _exitCode);
    }, "waiting for process '$description' to die");
    _scheduledExitTask = currentSchedule.tasks.contents.last;
  }

  /// Waits for the process to exit, and verifies that the exit code matches
  /// [expectedExitCode] (if given).
  void shouldExit([int expectedExitCode]) {
    if (_endScheduled) {
      throw new StateError("shouldExit() or kill() already called.");
    }

    schedule(() {
      return _exitCode.then((exitCode) {
        if (expectedExitCode != null) {
          expect(exitCode, equals(expectedExitCode));
        }
      });
    }, "waiting for process '$description' to exit");
    _scheduledExitTask = currentSchedule.tasks.contents.last;
  }
}
