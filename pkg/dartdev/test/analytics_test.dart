// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartdev/dartdev.dart';
import 'package:dartdev/src/unified_analytics.dart';
import 'package:dartdev/src/vm_interop_handler.dart';
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
        Event.dartCliCommandExecuted(
          name: 'help',
          enabledExperiments: '',
        ),
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
        Event.dartCliCommandExecuted(
          name: 'create',
          enabledExperiments: '',
          pubspecHasFlutterSdk: false,
          pubspecEnvironmentSdk: '^3.0.0',
        ),
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
              pubspecHasFlutterSdk: false,
              pubspecDependencies: const {'lints'},
              pubspecEnvironmentSdk: '^3.0.0',
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
        Event.dartCliCommandExecuted(
          name: 'format',
          enabledExperiments: '',
        ),
      ]);
    });

    test('info', () async {
      final p = project();
      final analytics = await p.runLocalWithFakeAnalytics(['info']);
      expect(analytics.sentEvents, [
        Event.dartCliCommandExecuted(
          name: 'info/dump',
          enabledExperiments: '',
        ),
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
          Event.dartCliCommandExecuted(
            name: 'run',
            enabledExperiments: '',
            pubspecHasFlutterSdk: false,
            pubspecEnvironmentSdk: '^3.0.0',
          ),
        ]);
      });
    });

    group('run --enable-experiments', () {
      for (final experiment in experiments) {
        test(experiment.name, () async {
          {
            for (final no in ['', 'no-']) {
              final p = project(mainSrc: experiment.validation);
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
                    pubspecHasFlutterSdk: false,
                    pubspecEnvironmentSdk: '^3.0.0',
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
          pubspecHasFlutterSdk: false,
          pubspecEnvironmentSdk: '^3.0.0',
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

  group('Sub-tool suppression on first run:', () {
    const configPath = '/.dart-tool/dart-flutter-telemetry.config';
    final suppressVar = DashEnvVar.suppressAnalytics.name;

    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test(style: FileSystemStyle.posix);
    });

    FakeAnalytics createFake({bool isExternal = true}) => Analytics.fake(
      tool: DashTool.dartTool,
      homeDirectory: fs.directory('/'),
      dartVersion: 'dartVersion',
      fs: fs,
      isExternal: isExternal,
    );

    /// A fake for a user who has already seen the consent message.
    FakeAnalytics createConsentedFake() {
      createFake().clientShowedMessage();
      return createFake();
    }

    bool dartToolConsentRecorded() {
      final config = fs.file(configPath);
      return config.existsSync() &&
          RegExp(
            r'^dart-tool=',
            multiLine: true,
          ).hasMatch(config.readAsStringSync());
    }

    // NOTE: `VmInteropHandler.environmentOverrides` is static, so values set
    // by one run stay visible to later tests in this isolate (including any
    // child processes they start through `runProcess`). Each run below unsets
    // and then sets `DASH__SUPPRESS_ANALYTICS`, so reading it right after a
    // run is reliable.
    Future<String?> runAndGetPropagatedValue(
      Analytics analytics, {
      required bool hasTerminal,
      List<String> args = const [],
      Map<String, String> environment = const {},
    }) async {
      final runner = DartdevRunner(
        args,
        analyticsOverride: analytics,
        // Keep `isBot()` from affecting whether the message is printed.
        isAnalyticsTest: true,
        stdoutHasTerminal: hasTerminal,
        // Don't inherit analytics variables from the test process.
        environment: environment,
      );
      // With no command, `CommandRunner` prints usage; keep test output quiet.
      final result = await runZoned(
        () => runner.runCommand(runner.parse(args)),
        zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
      );
      expect(result, 0);
      return VmInteropHandler.environmentOverrides[suppressVar];
    }

    group('helpers', () {
      test('shouldPrintConsentMessage', () {
        const rows = [
          (pending: true, terminal: true, bot: false, expected: true),
          (pending: true, terminal: true, bot: true, expected: false),
          (pending: true, terminal: false, bot: false, expected: false),
          (pending: true, terminal: false, bot: true, expected: false),
          (pending: false, terminal: true, bot: false, expected: false),
          (pending: false, terminal: true, bot: true, expected: false),
          (pending: false, terminal: false, bot: false, expected: false),
          (pending: false, terminal: false, bot: true, expected: false),
        ];
        for (final (:pending, :terminal, :bot, :expected) in rows) {
          expect(
            shouldPrintConsentMessage(
              consentPending: pending,
              hasTerminal: terminal,
              botSuppressed: bot,
            ),
            expected,
            reason: 'pending: $pending, terminal: $terminal, bot: $bot',
          );
        }
      });

      test('shouldSuppressSubtools', () {
        expect(
          shouldSuppressSubtools(
            suppressAnalytics: false,
            showsConsentMessage: false,
          ),
          isFalse,
        );
        // Regression case: sub-tools must be suppressed on the run where the
        // consent message is shown.
        expect(
          shouldSuppressSubtools(
            suppressAnalytics: false,
            showsConsentMessage: true,
          ),
          isTrue,
        );
        expect(
          shouldSuppressSubtools(
            suppressAnalytics: true,
            showsConsentMessage: false,
          ),
          isTrue,
        );
        expect(
          shouldSuppressSubtools(
            suppressAnalytics: true,
            showsConsentMessage: true,
          ),
          isTrue,
        );
      });
    });

    test('clientShowedMessage clears shouldShowMessage, not okToSend', () {
      // dartdev relies on this: it must read `shouldShowMessage` before
      // calling `clientShowedMessage()`, and it sends nothing itself on the
      // run where the message is shown.
      final analytics = createFake();
      expect(analytics.shouldShowMessage, isTrue);
      expect(analytics.okToSend, isFalse);

      analytics.clientShowedMessage();
      expect(analytics.shouldShowMessage, isFalse);
      expect(analytics.okToSend, isFalse);
      expect(dartToolConsentRecorded(), isTrue);

      // A sub-tool reporting under the same label, started later in the same
      // run, would be allowed to send. This is why dartdev suppresses
      // sub-tools on this run.
      expect(createFake().okToSend, isTrue);
    });

    test('first run with a terminal suppresses sub-tools', () async {
      final analytics = createFake();
      final value = await runAndGetPropagatedValue(
        analytics,
        hasTerminal: true,
      );
      expect(value, 'true');
      // The message was shown and recorded.
      expect(analytics.shouldShowMessage, isFalse);
      expect(dartToolConsentRecorded(), isTrue);
      expect(analytics.sentEvents, isEmpty);
    });

    test('first run without a terminal does not suppress sub-tools', () async {
      final analytics = createFake();
      final value = await runAndGetPropagatedValue(
        analytics,
        hasTerminal: false,
      );
      expect(value, 'false');
      // The message was not shown, so consent is still pending and nothing
      // was recorded; sub-tools using the same label can't send either.
      expect(analytics.shouldShowMessage, isTrue);
      expect(dartToolConsentRecorded(), isFalse);
      expect(createFake().okToSend, isFalse);
    });

    test('consented user does not suppress sub-tools', () async {
      final value = await runAndGetPropagatedValue(
        createConsentedFake(),
        hasTerminal: true,
      );
      expect(value, 'false');
    });

    test('--suppress-analytics still suppresses sub-tools', () async {
      final value = await runAndGetPropagatedValue(
        createConsentedFake(),
        hasTerminal: true,
        args: const ['--suppress-analytics'],
      );
      expect(value, 'true');
    });

    test('inherited DASH__SUPPRESS_ANALYTICS=true is propagated', () async {
      final value = await runAndGetPropagatedValue(
        createConsentedFake(),
        hasTerminal: true,
        environment: {suppressVar: 'true'},
      );
      expect(value, 'true');
    });

    for (final inherited in ['false', '1', '']) {
      test(
        'inherited DASH__SUPPRESS_ANALYTICS="$inherited" is ignored',
        () async {
          final value = await runAndGetPropagatedValue(
            createConsentedFake(),
            hasTerminal: true,
            environment: {suppressVar: inherited},
          );
          expect(value, 'false');
        },
      );
    }

    group('internal builds (isExternal: false)', () {
      test('first run with a terminal does not suppress sub-tools', () async {
        final analytics = createFake(isExternal: false);
        expect(analytics.shouldShowMessage, isFalse);
        expect(analytics.okToSend, isTrue);

        final value = await runAndGetPropagatedValue(
          analytics,
          hasTerminal: true,
        );
        expect(value, 'false');
        expect(fs.file(configPath).existsSync(), isFalse);
      });

      test('clientShowedMessage records nothing', () {
        createFake(isExternal: false).clientShowedMessage();
        expect(fs.file(configPath).existsSync(), isFalse);
      });

      test('--suppress-analytics still suppresses sub-tools', () async {
        final value = await runAndGetPropagatedValue(
          createFake(isExternal: false),
          hasTerminal: true,
          args: const ['--suppress-analytics'],
        );
        expect(value, 'true');
      });
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
      expect(dir!.path, path.join(homeDir!.path, '.dart'));
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
