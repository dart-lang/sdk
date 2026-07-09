// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartdev/dartdev.dart';
import 'package:dartdev/src/unified_analytics.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
// Needed to reset the global HTTP client after a test.
import 'package:pub/src/http.dart' as pub show withHttpClient;
import 'package:test/test.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'experiment_util.dart';
import 'utils.dart';

List<Map<String, Object?>> extractAnalytics(io.ProcessResult result) {
  return LineSplitter.split(
    result.stderr,
  ).where((line) => line.startsWith('[analytics]: ')).map((line) {
    return (json.decode(line.substring('[analytics]: '.length)) as Map)
        .cast<String, Object?>();
  }).toList();
}

void main() {
  final experiments = experimentsWithValidation();

  group('VM -> CLI flag smoke test:', () {
    late DartdevRunner command;
    setUp(() {
      command = DartdevRunner([], isAnalyticsTest: true);
    });

    test('--no-analytics', () async {
      final result = await command.runCommand(
        command.parse(['--no-analytics']),
      );
      expect(result, 0);
      expect(command.unifiedAnalytics.telemetryEnabled, false);
    });

    test('--suppress-analytics', () async {
      final result = await command.runCommand(
        command.parse(['--suppress-analytics']),
      );
      expect(result, 0);
      expect(command.unifiedAnalytics.telemetryEnabled, false);
    });

    test('--suppress-analytics and --disable-analytics', () async {
      final result = await command.runCommand(
        command.parse(['--suppress-analytics', '--disable-analytics']),
      );
      // --suppress-analytics and --disable-analytics can't be provided
      // together to ensure analytics state properly sticks.
      expect(result, 254);
    });

    test('--suppress-analytics and --enable-analytics', () async {
      final result = await command.runCommand(
        command.parse(['--suppress-analytics', '--enable-analytics']),
      );
      // --suppress-analytics and --enable-analytics can't be provided
      // together to ensure analytics state properly sticks.
      expect(result, 254);
    });
  });

  group('Sending analytics', () {
    test('help', () async {
      final p = project();
      final analytics = await p.runLocalWithFakeAnalytics(['help']);
      expect(analytics.sentEvents, [
        Event.dartCliCommandExecuted(name: 'help', enabledExperiments: ''),
      ]);
    });

    test('create', () async {
      final p = project();
      final analytics = await p.runLocalWithFakeAnalytics([
        'create',
        '--no-pub',
        '-tpackage-simple',
        path.join(io.Directory.systemTemp.createTempSync().path, 'name'),
      ]);
      expect(analytics.sentEvents, [
        Event.dartCliCommandExecuted(name: 'create', enabledExperiments: ''),
      ]);
    });

    group('pub', () {
      test(
        'get',
        () async {
          final p = project(
            pubspecExtras: {
              'dependencies': {'lints': '2.0.1'},
            },
          );
          final analytics = await p.runLocalWithFakeAnalytics(['pub', 'get']);

          // Pub no longer sends custom analytics,
          // so only the command should be sent.
          expect(analytics.sentEvents, [
            Event.dartCliCommandExecuted(
              name: 'pub/get',
              enabledExperiments: '',
            ),
          ]);
        },
        // This test does a pub get, so it might run slow. Consider adding
        // retries if necessary.
        timeout: Timeout.factor(5),
      );
    });

    test('format', () async {
      final p = project();
      final analytics = await p.runLocalWithFakeAnalytics([
        'format',
        '-l80',
        '.',
      ]);
      expect(analytics.sentEvents, [
        Event.dartCliCommandExecuted(name: 'format', enabledExperiments: ''),
      ]);
    });

    test('run', () async {
      final p = project(mainSrc: 'void main(List<String> args) => print(args)');
      await pub.withHttpClient(client: http.Client(), () async {
        final analytics = await p.runLocalWithFakeAnalytics([
          'run',
          '--no-pause-isolates-on-exit',
          '--enable-asserts',
          'lib/main.dart',
          '--argument',
        ]);
        expect(analytics.sentEvents, [
          Event.dartCliCommandExecuted(name: 'run', enabledExperiments: ''),
        ]);
      });
    });

    group('run --enable-experiments', () {
      for (final experiment in experiments) {
        test(experiment.name, () async {
          final p = project(mainSrc: experiment.validation);
          {
            for (final no in ['', 'no-']) {
              await pub.withHttpClient(client: http.Client(), () async {
                final analytics = await p.runLocalWithFakeAnalytics([
                  'run',
                  '--enable-experiment=$no${experiment.name}',
                  'lib/main.dart',
                ]);
                expect(analytics.sentEvents, [
                  Event.dartCliCommandExecuted(
                    name: 'run',
                    enabledExperiments: '$no${experiment.name}',
                  ),
                ]);
              });
            }
          }
        });
      }
    });

    test('compile', () async {
      final p = project(
        mainSrc: 'void main(List<String> args) => print(args);',
      );
      final analytics = await p.runLocalWithFakeAnalytics([
        'compile',
        'kernel',
        'lib/main.dart',
        '-o',
        'main.kernel',
      ]);
      expect(analytics.sentEvents, [
        Event.dartCliCommandExecuted(
          name: 'compile/kernel',
          enabledExperiments: '',
        ),
      ]);
    });
  });

  group('Analytics hang test', () {
    test('close hangs but runner finishes quickly', () async {
      final fs = MemoryFileSystem.test(style: FileSystemStyle.posix);
      final homeDirectory = fs.directory('/');
      final fakeAnalytics = Analytics.fake(
        tool: DashTool.dartTool,
        homeDirectory: homeDirectory,
        dartVersion: 'dartVersion',
        fs: fs,
      );

      final hangingAnalytics = HangingAnalytics(fakeAnalytics);

      final runner = DartdevRunner(
        ['--no-analytics'],
        analyticsOverride: hangingAnalytics,
      );

      final stopwatch = Stopwatch()..start();
      final result = await runner.runCommand(runner.parse(['--no-analytics']));
      stopwatch.stop();

      expect(result, 0);
      // The timeout is 250ms, so it should definitely finish in less
      // than 1 second.
      // If it hung, it would take much longer or never finish.
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('unified analytics helpers:', () {
    test('sanitizeStacktrace strips file paths and compresses whitespace', () {
      const rawStack =
          '#0  main (file:///Users/username/project/bin/main.dart:10:5)\n'
          '#1  helper   (file:///home/user/app/lib/helper.dart:2:1)';
      final sanitized = sanitizeStacktrace(rawStack, shorten: true);
      expect(sanitized, isNot(contains('/Users/username/project/bin/')));
      expect(sanitized, contains('main.dart'));
      expect(sanitized, contains('helper.dart'));
    });

    test('getDartStorageDirectory resolves user .dart directory', () {
      final dir = getDartStorageDirectory();
      expect(dir, isNotNull);
      // Ensure the directory exists and its basename is '.dart'.
      expect(dir!.existsSync(), isTrue);
      expect(path.basename(dir.path), '.dart');
    });
  });

  group('isBot environment detection:', () {
    test('isBot function executes without error', () {
      // isBot should execute synchronously without throwing
      expect(() => isBot(), returnsNormally);
    });
  });
}

class HangingAnalytics implements Analytics {
  final FakeAnalytics _delegate;
  final Completer<void> _closeCompleter = Completer<void>();

  HangingAnalytics(this._delegate);

  @override
  Future<void> close({int delayDuration = 250}) => _closeCompleter.future;

  @override
  bool get shouldShowMessage => _delegate.shouldShowMessage;

  @override
  String get getConsentMessage => _delegate.getConsentMessage;

  @override
  void clientShowedMessage() => _delegate.clientShowedMessage();

  @override
  Future<void> setTelemetry(bool value) => _delegate.setTelemetry(value);

  @override
  bool get telemetryEnabled => _delegate.telemetryEnabled;

  @override
  Future<http.Response>? send(Event event) {
    _delegate.send(event);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    super.noSuchMethod(invocation);
  }
}
