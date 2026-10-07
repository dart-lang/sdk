// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart' as cli_logging;
import 'package:dartdev/src/core.dart';
import 'package:dartdev/src/progress.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

const _eraseLine = '\u001b[2K';
const _eraseToLineEnd = '\u001b[0K';

final class _MockStdout implements Stdout {
  final StringBuffer buffer = StringBuffer();

  @override
  final bool hasTerminal;

  @override
  final bool supportsAnsiEscapes;

  _MockStdout({this.hasTerminal = true, this.supportsAnsiEscapes = true});

  @override
  void write(Object? object) {
    buffer.write(object);
  }

  @override
  void writeln([Object? object = '']) {
    buffer.writeln(object);
  }

  @override
  void writeAll(Iterable<Object?> objects, [String sep = '']) {
    buffer.writeAll(objects, sep);
  }

  @override
  void writeCharCode(int charCode) {
    buffer.writeCharCode(charCode);
  }

  @override
  void add(List<int> data) {
    buffer.write(utf8.decode(data));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
    }
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> get done => Future.value();

  @override
  Future<void> flush() async {}

  @override
  Encoding encoding = utf8;

  @override
  IOSink get nonBlocking => this;

  @override
  int get terminalColumns => 80;

  @override
  int get terminalLines => 25;

  @override
  String get lineTerminator => '\n';

  @override
  set lineTerminator(String value) {}
}

Future<void> _runWithMockStdout(
  FutureOr<void> Function(_MockStdout mockStdout) callback, {
  bool hasTerminal = true,
  bool supportsAnsiEscapes = true,
}) async {
  final mockStdout = _MockStdout(
    hasTerminal: hasTerminal,
    supportsAnsiEscapes: supportsAnsiEscapes,
  );
  await IOOverrides.runZoned(
    () => callback(mockStdout),
    stdout: () => mockStdout,
  );
}

Future<void> _runWithMockIo(
  FutureOr<void> Function(_MockStdout mockStdout, _MockStdout mockStderr)
  callback, {
  bool hasTerminal = true,
  bool supportsAnsiEscapes = true,
}) async {
  final mockStdout = _MockStdout(
    hasTerminal: hasTerminal,
    supportsAnsiEscapes: supportsAnsiEscapes,
  );
  final mockStderr = _MockStdout(
    hasTerminal: hasTerminal,
    supportsAnsiEscapes: supportsAnsiEscapes,
  );
  await IOOverrides.runZoned(
    () => callback(mockStdout, mockStderr),
    stdout: () => mockStdout,
    stderr: () => mockStderr,
  );
}

/// Runs [callback] with a fake clock and fake timers (see [fakeAsync]) and
/// with [stdout] replaced by a mock terminal.
///
/// Any progress indicator started by [callback] must be stopped before
/// [callback] returns, as its timer would otherwise outlive the fake zone.
void _runWithFakeTime(
  void Function(FakeAsync async, _MockStdout mockStdout) callback,
) {
  fakeAsync((async) {
    final mockStdout = _MockStdout();
    IOOverrides.runZoned(
      () => callback(async, mockStdout),
      stdout: () => mockStdout,
    );
  });
}

/// Wraps [text] in the gray ANSI color used for the elapsed time, unless
/// `NO_COLOR` is set (which the progress indicator reads from the real
/// environment, so it cannot be mocked here).
String _gray(String text) => Platform.environment.containsKey('NO_COLOR')
    ? text
    : '\u001b[38;5;245m$text\u001b[0m';

void main() {
  group('progress', () {
    setUp(resetProgressGracePeriod);

    tearDown(() {
      stopActiveProgress();
      resetProgressGracePeriod();
    });

    test(
      'runs callback to completion, prints completed newline, and resets grace period',
      () => _runWithMockStdout((mockStdout) async {
        var executed = false;
        final result = await progress('Testing progress', () async {
          expect(mockStdout.buffer.toString(), 'Testing progress... ');
          expect(progressGracePeriod.hasShownProgress, isTrue);
          executed = true;
          return 42;
        });
        expect(executed, isTrue);
        expect(result, 42);
        expect(mockStdout.buffer.toString(), 'Testing progress... \n');
        expect(progressGracePeriod.hasShownProgress, isFalse);
      }),
    );

    test(
      'propagates errors and cleans up',
      () => _runWithMockStdout((mockStdout) async {
        await expectLater(
          () => progress('Failing task', () async {
            throw StateError('Task failed');
          }),
          throwsStateError,
        );
      }),
    );

    test(
      'propagates synchronous errors and cleans up',
      () => _runWithMockStdout((mockStdout) async {
        await expectLater(
          () => progress('Failing task', () {
            throw StateError('Task failed synchronously');
          }),
          throwsStateError,
        );
      }),
    );

    test(
      'transient progress erases line with ANSI escape sequence',
      () => _runWithMockStdout((mockStdout) async {
        var executed = false;
        final result = await progress(
          'Testing transient progress',
          () async {
            expect(
              mockStdout.buffer.toString(),
              'Testing transient progress... ',
            );
            executed = true;
            return 'done';
          },
          transient: true,
          delay: Duration.zero,
        );
        expect(executed, isTrue);
        expect(result, 'done');
        expect(
          mockStdout.buffer.toString(),
          'Testing transient progress... \r$_eraseLine',
        );
      }),
    );

    test(
      'output: ProgressOutput.stderr writes to stderr and leaves stdout empty',
      () => _runWithMockIo((mockStdout, mockStderr) async {
        final result = await progress(
          'Stderr task',
          () async {
            expect(mockStdout.buffer.toString(), isEmpty);
            expect(mockStderr.buffer.toString(), 'Stderr task... ');
            return 'done';
          },
          transient: true,
          output: ProgressOutput.stderr,
          delay: Duration.zero,
        );
        expect(result, 'done');
        expect(mockStdout.buffer.toString(), isEmpty);
        expect(
          mockStderr.buffer.toString(),
          'Stderr task... \r$_eraseLine',
        );
      }),
    );

    test(
      'output: ProgressOutput.none runs callback without writing any output',
      () => _runWithMockIo((mockStdout, mockStderr) async {
        final result = await progress(
          'Silent task',
          () async => 'done',
          output: ProgressOutput.none,
          delay: Duration.zero,
        );
        expect(result, 'done');
        expect(mockStdout.buffer.toString(), isEmpty);
        expect(mockStderr.buffer.toString(), isEmpty);
        expect(progressGracePeriod.hasShownProgress, isFalse);
      }),
    );

    test(
      'transient progress produces no output when ANSI is disabled',
      () => _runWithMockStdout(supportsAnsiEscapes: false, (mockStdout) async {
        final result = await progress(
          'Testing transient progress',
          () async => 'done',
          transient: true,
          delay: Duration.zero,
        );
        expect(result, 'done');
        expect(mockStdout.buffer.toString(), isEmpty);
      }),
    );

    test(
      'transient progress produces no output when stdout has no terminal',
      () => _runWithMockStdout(hasTerminal: false, (mockStdout) async {
        final result = await progress(
          'Testing transient progress',
          () async => 'done',
          transient: true,
          delay: Duration.zero,
        );
        expect(result, 'done');
        expect(mockStdout.buffer.toString(), isEmpty);
      }),
    );

    test(
      'non-transient progress logs once without animation when ANSI is disabled',
      () => _runWithMockStdout(supportsAnsiEscapes: false, (mockStdout) async {
        progressGracePeriod.markProgressShown();
        final result = await progress(
          'Testing progress',
          () async => 'done',
        );
        expect(result, 'done');
        expect(mockStdout.buffer.toString(), 'Testing progress...\n');
        expect(progressGracePeriod.hasShownProgress, isFalse);
      }),
    );

    test(
      'delayed transient progress writes nothing if stopped before delay',
      () => _runWithFakeTime((async, mockStdout) {
        final completer = Completer<void>();
        var completed = false;
        progress(
          'Testing delayed progress',
          () => completer.future,
          transient: true,
          delay: const Duration(seconds: 5),
        ).whenComplete(() => completed = true);

        async.elapse(const Duration(seconds: 4));
        expect(mockStdout.buffer.toString(), isEmpty);

        completer.complete();
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(progressGracePeriod.hasShownProgress, isFalse);

        // Nothing is written once the delay would have passed either.
        async.elapse(const Duration(seconds: 5));
        expect(mockStdout.buffer.toString(), isEmpty);
      }),
    );

    test(
      'delayed transient progress writes and clears if stopped after delay',
      () => _runWithFakeTime((async, mockStdout) {
        final completer = Completer<void>();
        var completed = false;
        progress(
          'Testing delayed progress',
          () => completer.future,
          transient: true,
          delay: const Duration(milliseconds: 500),
        ).whenComplete(() => completed = true);

        async.elapse(const Duration(milliseconds: 499));
        expect(mockStdout.buffer.toString(), isEmpty);
        expect(progressGracePeriod.hasShownProgress, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(mockStdout.buffer.toString(), 'Testing delayed progress... ');
        expect(progressGracePeriod.hasShownProgress, isTrue);

        completer.complete();
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(
          mockStdout.buffer.toString(),
          'Testing delayed progress... \r$_eraseLine',
        );
      }),
    );

    test(
      'subsequent transient progress displays with zero delay once progress shown',
      () => _runWithMockStdout((mockStdout) async {
        progressGracePeriod.markProgressShown();
        final result = await progress(
          'Testing subsequent progress',
          () async {
            expect(
              mockStdout.buffer.toString(),
              'Testing subsequent progress... ',
            );
            return 'ok';
          },
          transient: true,
        );
        expect(result, 'ok');
        expect(
          mockStdout.buffer.toString(),
          'Testing subsequent progress... \r$_eraseLine',
        );
      }),
    );

    test('DartdevLogger resets grace period on output', () {
      final mockLogger = _MockLogger();
      final dartdevLogger = DartdevLogger(mockLogger);

      for (final action in <void Function()>[
        () => dartdevLogger.stdout('Some output'),
        () => dartdevLogger.stderr('Some error'),
        () => dartdevLogger.write('Some text'),
        () => dartdevLogger.writeCharCode(65),
      ]) {
        progressGracePeriod.markProgressShown();
        expect(progressGracePeriod.hasShownProgress, isTrue);
        action();
        expect(progressGracePeriod.hasShownProgress, isFalse);
      }
    });

    test(
      'DartdevLogger.progress uses shared progress indicator',
      () => _runWithMockStdout((mockStdout) {
        final mockLogger = _MockLogger(sink: mockStdout);
        final dartdevLogger = DartdevLogger(mockLogger);

        final p = dartdevLogger.progress('Some progress');
        expect(mockStdout.buffer.toString(), 'Some progress... ');
        expect(progressGracePeriod.hasShownProgress, isTrue);

        p.finish();
        expect(mockStdout.buffer.toString(), 'Some progress... \n');
        expect(progressGracePeriod.hasShownProgress, isFalse);

        mockStdout.buffer.clear();
        final p2 = dartdevLogger.progress('Canceled progress');
        expect(mockStdout.buffer.toString(), 'Canceled progress... ');
        p2.cancel();
        expect(
          mockStdout.buffer.toString(),
          'Canceled progress... \r$_eraseLine',
        );
      }),
    );

    test(
      'Progress.finish erases transient progress and writes message on its own line',
      () => _runWithMockStdout((mockStdout) {
        final dartdevLogger = DartdevLogger(
          _MockLogger(sink: mockStdout),
          transientProgress: true,
        );
        progressGracePeriod.markProgressShown();

        final p = dartdevLogger.progress('Transient progress');
        expect(mockStdout.buffer.toString(), 'Transient progress... ');
        p.finish();
        expect(
          mockStdout.buffer.toString(),
          'Transient progress... \r$_eraseLine',
        );

        mockStdout.buffer.clear();
        final p2 = dartdevLogger.progress('Transient progress');
        p2.finish(message: 'Done');
        expect(
          mockStdout.buffer.toString(),
          'Transient progress... \r${_eraseLine}Done\n',
        );
        expect(progressGracePeriod.hasShownProgress, isFalse);
      }),
    );

    test(
      'Progress.finish writes message on its own line after progress line',
      () => _runWithMockStdout((mockStdout) {
        final dartdevLogger = DartdevLogger(_MockLogger(sink: mockStdout));

        final p = dartdevLogger.progress('Some progress');
        p.finish(message: 'Done', showTiming: true);
        expect(mockStdout.buffer.toString(), 'Some progress... \nDone\n');
      }),
    );

    test(
      'Progress.finish writes nothing when progress output is suppressed',
      () => _runWithMockIo((mockStdout, mockStderr) {
        final dartdevLogger = DartdevLogger(
          _MockLogger(sink: mockStdout, stderrSink: mockStderr),
          output: ProgressOutput.none,
        );

        dartdevLogger.progress('Suppressed progress').finish(message: 'Done');
        expect(mockStdout.buffer.toString(), isEmpty);
        expect(mockStderr.buffer.toString(), isEmpty);
      }),
    );

    test(
      'DartdevLogger stops active transient progress and erases line before output',
      () => _runWithMockStdout((mockStdout) async {
        final mockLogger = _MockLogger(sink: mockStdout);
        final dartdevLogger = DartdevLogger(mockLogger);

        final completer = Completer<void>();
        final progressFuture = progress(
          'Ongoing task',
          () => completer.future,
          transient: true,
          delay: Duration.zero,
        );

        expect(mockStdout.buffer.toString(), 'Ongoing task... ');
        dartdevLogger.stdout('Logging during progress');
        expect(
          mockStdout.buffer.toString(),
          'Ongoing task... \r$_eraseLine'
          'Logging during progress\n',
        );
        completer.complete();
        await progressFuture;
      }),
    );

    test(
      'stopActiveProgress erases elapsed time on non-transient progress and resets grace period',
      () => _runWithMockStdout((mockStdout) async {
        final completer = Completer<void>();
        final progressFuture = progress(
          'Ongoing task',
          () => completer.future,
          transient: false,
          delay: Duration.zero,
        );

        expect(progressGracePeriod.hasShownProgress, isTrue);
        stopActiveProgress();
        expect(progressGracePeriod.hasShownProgress, isFalse);
        expect(
          mockStdout.buffer.toString(),
          'Ongoing task... \rOngoing task... $_eraseToLineEnd\n',
        );
        completer.complete();
        await progressFuture;
      }),
    );

    test(
      'starting new progress stops previous active progress',
      () => _runWithMockStdout((mockStdout) async {
        final completer1 = Completer<void>();
        final completer2 = Completer<void>();
        final p1 = progress(
          'First task',
          () => completer1.future,
          transient: true,
          delay: Duration.zero,
        );

        final p2 = progress(
          'Second task',
          () => completer2.future,
          transient: true,
          delay: Duration.zero,
        );

        completer2.complete();
        await p2;

        completer1.complete();
        await p1;

        expect(
          mockStdout.buffer.toString(),
          'First task... \r$_eraseLine'
          'Second task... \r$_eraseLine',
        );
      }),
    );

    test('DartdevLogger trace does not reset grace period unless verbose', () {
      final normalLogger = DartdevLogger(_MockLogger(isVerbose: false));
      progressGracePeriod.markProgressShown();
      expect(progressGracePeriod.hasShownProgress, isTrue);

      normalLogger.trace('Debug trace');
      expect(progressGracePeriod.hasShownProgress, isTrue);

      final verboseLogger = DartdevLogger(_MockLogger(isVerbose: true));
      verboseLogger.trace('Debug trace');
      expect(progressGracePeriod.hasShownProgress, isFalse);
    });

    test(
      'withDartdevLogger routes stdout to stderr and defaults progress to transient on stderr',
      () => _runWithMockIo((mockStdout, mockStderr) async {
        final mockLogger = _MockLogger(
          sink: mockStdout,
          stderrSink: mockStderr,
        );
        await withDartdevLogger(
          () async {
            log.stdout('Status message');
            expect(mockStdout.buffer.toString(), isEmpty);
            expect(mockStderr.buffer.toString(), 'Status message\n');
            mockStderr.buffer.clear();

            await progress(
              'Zone task',
              () async {
                expect(mockStdout.buffer.toString(), isEmpty);
                expect(mockStderr.buffer.toString(), 'Zone task... ');
              },
              delay: Duration.zero,
            );
            expect(mockStdout.buffer.toString(), isEmpty);
            expect(
              mockStderr.buffer.toString(),
              'Zone task... \r$_eraseLine',
            );
          },
          delegate: mockLogger,
          output: ProgressOutput.stderr,
          transientProgress: true,
        );
      }),
    );

    test(
      'withDartdevLogger suppresses stdout, trace, and progress when output is ProgressOutput.none',
      () => _runWithMockIo((mockStdout, mockStderr) async {
        final mockLogger = _MockLogger(
          isVerbose: true,
          sink: mockStdout,
          stderrSink: mockStderr,
        );
        await withDartdevLogger(
          () async {
            log.stdout('Suppressed stdout');
            log.write('Suppressed write');
            log.writeCharCode(65);
            log.trace('Suppressed trace');
            await progress(
              'Suppressed progress',
              () async {},
              output: ProgressOutput.stderr,
              delay: Duration.zero,
            );
            expect(mockStdout.buffer.toString(), isEmpty);
            expect(mockStderr.buffer.toString(), isEmpty);

            log.stderr('Error still printed');
            expect(mockStderr.buffer.toString(), 'Error still printed\n');
          },
          delegate: mockLogger,
          output: ProgressOutput.none,
        );
      }),
    );

    test(
      'shows elapsed time once a task takes at least a second',
      () => _runWithFakeTime((async, mockStdout) {
        final completer = Completer<void>();
        var completed = false;
        progress(
          'Slow task',
          () => completer.future,
        ).whenComplete(() => completed = true);
        expect(mockStdout.buffer.toString(), 'Slow task... ');

        async.elapse(const Duration(milliseconds: 999));
        expect(mockStdout.buffer.toString(), 'Slow task... ');

        async.elapse(const Duration(milliseconds: 1));
        expect(
          mockStdout.buffer.toString(),
          'Slow task... ${_gray('(1.0s)')}',
        );

        // Each later tick backspaces over the previous time and rewrites it.
        async.elapse(const Duration(milliseconds: 100));
        expect(
          mockStdout.buffer.toString(),
          endsWith('${'\b' * 6}${_gray('(1.1s)')}'),
        );

        completer.complete();
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(
          mockStdout.buffer.toString(),
          endsWith('${'\b' * 6}${_gray('(1.1s)')}\n'),
        );
      }),
    );

    test(
      'transient progress erases the line including the elapsed time',
      () => _runWithFakeTime((async, mockStdout) {
        final completer = Completer<void>();
        var completed = false;
        progress(
          'Slow task',
          () => completer.future,
          transient: true,
          delay: Duration.zero,
        ).whenComplete(() => completed = true);
        async.elapse(const Duration(seconds: 1));
        expect(
          mockStdout.buffer.toString(),
          'Slow task... ${_gray('(1.0s)')}',
        );

        completer.complete();
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(
          mockStdout.buffer.toString(),
          'Slow task... ${_gray('(1.0s)')}\r$_eraseLine',
        );
      }),
    );

    test(
      'stopActiveProgress erases the elapsed time from the progress line',
      () => _runWithFakeTime((async, mockStdout) {
        final completer = Completer<void>();
        var completed = false;
        progress(
          'Slow task',
          () => completer.future,
        ).whenComplete(() => completed = true);
        async.elapse(const Duration(seconds: 1));
        expect(
          mockStdout.buffer.toString(),
          'Slow task... ${_gray('(1.0s)')}',
        );

        stopActiveProgress();
        expect(
          mockStdout.buffer.toString(),
          'Slow task... ${_gray('(1.0s)')}\rSlow task... $_eraseToLineEnd\n',
        );

        // Once stopped, the indicator writes nothing more.
        async.elapse(const Duration(seconds: 1));
        completer.complete();
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(
          mockStdout.buffer.toString(),
          'Slow task... ${_gray('(1.0s)')}\rSlow task... $_eraseToLineEnd\n',
        );
      }),
    );

    test(
      'Progress.finish erases the elapsed time unless showTiming is true',
      () => _runWithFakeTime((async, mockStdout) {
        final dartdevLogger = DartdevLogger(_MockLogger(sink: mockStdout));

        final p = dartdevLogger.progress('Slow task');
        async.elapse(const Duration(seconds: 1));
        expect(
          mockStdout.buffer.toString(),
          'Slow task... ${_gray('(1.0s)')}',
        );
        p.finish(message: 'Done');
        expect(
          mockStdout.buffer.toString(),
          'Slow task... ${_gray('(1.0s)')}\rSlow task... $_eraseToLineEnd\n'
          'Done\n',
        );

        mockStdout.buffer.clear();
        final p2 = dartdevLogger.progress('Slow task');
        async.elapse(const Duration(seconds: 1));
        p2.finish(showTiming: true);
        expect(
          mockStdout.buffer.toString(),
          'Slow task... ${_gray('(1.0s)')}${'\b' * 6}${_gray('(1.0s)')}\n',
        );
      }),
    );

    test(
      'withDartdevLogger inherits unspecified settings from the enclosing zone',
      () {
        final stdoutBuffer = StringBuffer();
        final stderrBuffer = StringBuffer();
        final outerLogger = _MockLogger(
          isVerbose: true,
          sink: stdoutBuffer,
          stderrSink: stderrBuffer,
        );
        withDartdevLogger(
          () {
            withDartdevLogger(() {
              expect(dartdevLogger.output, ProgressOutput.stderr);
              expect(dartdevLogger.transientProgress, isTrue);
              expect(log.isVerbose, isTrue);
              log.stdout('Nested status');
              expect(stdoutBuffer.toString(), isEmpty);
              expect(stderrBuffer.toString(), 'Nested status\n');
            });
            withDartdevLogger(
              () {
                expect(dartdevLogger.output, ProgressOutput.none);
                expect(dartdevLogger.transientProgress, isTrue);
              },
              output: ProgressOutput.none,
            );
            withDartdevLogger(
              () {
                expect(dartdevLogger.output, ProgressOutput.stderr);
                expect(dartdevLogger.transientProgress, isFalse);
              },
              transientProgress: false,
            );
            expect(dartdevLogger.output, ProgressOutput.stderr);
            expect(dartdevLogger.transientProgress, isTrue);
          },
          delegate: outerLogger,
          output: ProgressOutput.stderr,
          transientProgress: true,
        );
      },
    );

    test(
      'dartdevLogger falls back to the default logger when the zone logger is not a DartdevLogger',
      () {
        final plainLogger = _MockLogger();
        withLogger(plainLogger, () {
          expect(log, same(plainLogger));
          expect(dartdevLogger, isNot(same(plainLogger)));
          expect(dartdevLogger.output, ProgressOutput.stdout);
          expect(dartdevLogger.transientProgress, isFalse);
          withDartdevLogger(() {
            expect(log, isA<DartdevLogger>());
            expect(dartdevLogger.output, ProgressOutput.stderr);
          }, output: ProgressOutput.stderr);
        });
      },
    );
  });
}

final class _MockLogger implements cli_logging.Logger {
  @override
  final bool isVerbose;

  final StringSink? sink;
  final StringSink? stderrSink;

  _MockLogger({this.isVerbose = false, this.sink, this.stderrSink});

  @override
  cli_logging.Ansi get ansi => cli_logging.Ansi(false);

  @override
  void stdout(String message) {
    sink?.writeln(message);
  }

  @override
  void stderr(String message) {
    (stderrSink ?? sink)?.writeln(message);
  }

  @override
  void trace(String message) {
    if (isVerbose) {
      sink?.writeln(message);
    }
  }

  @override
  void write(String message) {
    sink?.write(message);
  }

  @override
  void writeCharCode(int charCode) {
    sink?.writeCharCode(charCode);
  }

  @override
  cli_logging.Progress progress(String message) => _MockProgress();

  @override
  void flush() {}
}

final class _MockProgress implements cli_logging.Progress {
  @override
  String get message => '';

  @override
  Duration get elapsed => Duration.zero;

  @override
  void cancel() {}

  @override
  void finish({String? message, bool showTiming = false}) {}
}
