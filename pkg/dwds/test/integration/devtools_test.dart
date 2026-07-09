// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 5))
@TestOn('vm')
library;

import 'dart:io';

import 'package:dwds/src/config/tool_configuration.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
// ignore: deprecated_member_use
import 'package:webdriver/io.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

Future<void> _waitForPageReady(TestContext context) async {
  var attempt = 100;
  while (attempt-- > 0) {
    final content = await context.webDriver.pageSource;
    if (content.contains('hello_world')) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('Page never initialized');
}

void main() {
  final provider = TestSdkConfigurationProvider();
  tearDownAll(provider.dispose);

  final context = TestContext(TestProject.test, provider);

  for (final serveFromDds in [true, false]) {
    group('Injected client with DevTools served from '
        '${serveFromDds ? 'DDS' : 'DevTools Launcher'}', () {
      setUp(() async {
        await context.setUp(
          debugSettings: TestDebugSettings.withDevToolsLaunch(
            context,
            serveFromDds: serveFromDds,
          ),
        );
        await context.webDriver.driver.keyboard.sendChord([Keyboard.alt, 'd']);
        // Wait for DevTools to actually open.
        await Future<void>.delayed(const Duration(seconds: 2));
      });

      tearDown(() async {
        await context.tearDown();
      });

      test('can launch devtools', () async {
        final windows = await context.webDriver.windows.toList();
        await context.webDriver.driver.switchTo.window(windows.last);
        expect(await context.webDriver.pageSource, contains('DevTools'));
        expect(await context.webDriver.currentUrl, contains('ide=Dwds'));
        // TODO(https://github.com/dart-lang/webdev/issues/1888): Re-enable.
      }, skip: Platform.isWindows);

      test(
        'can not launch devtools for the same app in multiple tabs',
        () async {
          final appUrl = await context.webDriver.currentUrl;
          // Open a new tab, select it, and navigate to the app
          await context.webDriver.driver.execute(
            "window.open('$appUrl', '_blank');",
            [],
          );
          await Future<void>.delayed(const Duration(seconds: 2));
          final newAppWindow = await context.webDriver.windows.last;
          await newAppWindow.setAsActive();

          // Wait for the page to be ready before trying to open DevTools
          // again.
          await _waitForPageReady(context);

          // Try to open devtools and check for the alert.
          await context.webDriver.driver.keyboard.sendChord([
            Keyboard.alt,
            'd',
          ]);
          await Future<void>.delayed(const Duration(seconds: 2));
          final alert = context.webDriver.driver.switchTo.alert;
          expect(alert, isNotNull);
          expect(
            await alert.text,
            contains('This app is already being debugged in a different tab'),
          );
          await alert.accept();

          var windows = await context.webDriver.windows.toList();
          for (final window in windows) {
            if (window.id != newAppWindow.id) {
              await window.setAsActive();
              await window.close();
            }
          }

          await newAppWindow.setAsActive();
          await context.webDriver.driver.keyboard.sendChord([
            Keyboard.alt,
            'd',
          ]);
          await Future<void>.delayed(const Duration(seconds: 2));
          windows = await context.webDriver.windows.toList();
          final devToolsWindow = windows.firstWhere(
            (Window window) => window != newAppWindow,
          );
          await devToolsWindow.setAsActive();
          expect(await context.webDriver.pageSource, contains('DevTools'));
        },
        skip: 'See https://github.com/dart-lang/webdev/issues/2462',
      );

      test(
        'destroys and recreates the isolate during a page refresh',
        () async {
          // This test is the same as one in reload_test, but runs here when
          // there is a connected client (DevTools) since it can behave
          // differently.
          // https://github.com/dart-lang/webdev/pull/901#issuecomment-586438132
          final client = context.debugConnection.vmService;
          await client.streamListen('Isolate');
          await context.makeEdits([
            (
              file: context.project.dartEntryFileName,
              originalString: 'Hello World!',
              newString: 'Bonjour le monde!',
            ),
          ]);
          await context.waitForSuccessfulBuild(propagateToBrowser: true);

          final eventsDone = expectLater(
            client.onIsolateEvent,
            emitsThrough(
              emitsInOrder([
                _hasKind(EventKind.kIsolateExit),
                _hasKind(EventKind.kIsolateStart),
                _hasKind(EventKind.kIsolateRunnable),
              ]),
            ),
          );

          await context.webDriver.driver.refresh();

          await eventsDone;
        },
        skip: 'https://github.com/dart-lang/webdev/issues/1888',
      );
    }, timeout: const Timeout.factor(2));
  }

  group('Injected client without a DevTools server', () {
    setUp(() async {
      await context.setUp(
        debugSettings: const TestDebugSettings.noDevToolsLaunch().copyWith(
          enableDevToolsLaunch: true,
          ddsConfiguration: const DartDevelopmentServiceConfiguration(
            serveDevTools: false,
          ),
        ),
      );
    });

    tearDown(() async {
      await context.tearDown();
    });

    test('gives a good error if devtools is not served', () async {
      // Try to open devtools and check for the alert.
      await context.webDriver.driver.keyboard.sendChord([Keyboard.alt, 'd']);
      await Future<void>.delayed(const Duration(seconds: 2));
      final alert = context.webDriver.driver.switchTo.alert;
      expect(alert, isNotNull);
      expect(await alert.text, contains('--debug'));
      await alert.accept();
    });
  });

  group(
    'Injected client with debug extension and without DevTools',
    () {
      setUp(() async {
        await context.setUp(
          debugSettings: const TestDebugSettings.noDevToolsLaunch().copyWith(
            enableDebugExtension: true,
          ),
        );
      });

      tearDown(() async {
        await context.tearDown();
      });

      test('gives a good error if devtools is not served', () async {
        // Click on extension
        await context.extensionConnection.sendCommand('Runtime.evaluate', {
          'expression': 'fakeClick()',
        });
        // Try to open devtools and check for the alert.
        await context.webDriver.driver.keyboard.sendChord([Keyboard.alt, 'd']);
        await Future<void>.delayed(const Duration(seconds: 2));
        final alert = context.webDriver.driver.switchTo.alert;
        expect(alert, isNotNull);
        expect(await alert.text, contains('--debug'));
        await alert.accept();
      });
      // TODO(https://github.com/dart-lang/webdev/issues/1724): Re-enable debug
      // extension tests on Windows.
    },
    tags: ['extension'],
    skip: 'https://github.com/dart-lang/webdev/issues/2114',
    timeout: const Timeout.factor(2),
  );
}

TypeMatcher<Event> _hasKind(String kind) =>
    isA<Event>().having((Event e) => e.kind, 'kind', kind);
