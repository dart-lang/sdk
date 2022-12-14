// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'test_support.dart';

main() {
  group('validates arguments', () {
    group('for Dart CLI adapter', () {
      late DapTestSession dap;
      setUp(() async {
        dap = await DapTestSession.setUp();
      });
      tearDown(() => dap.tearDown());

      String errorMessage(
        String field,
        String request,
        String expectedType,
        Object? actual,
      ) =>
          '"$field" argument in $request configuration must be a $expectedType '
          'but provided value was a ${actual.runtimeType} ($actual)';

      group('for launchRequest', () {
        Future<void> expectError(
          Map<String, Object?> args,
          String expectedError,
        ) async {
          final response = await dap.client.sendRequest(
            args,
            overrideCommand: 'launch',
            allowFailure: true,
          );

          expect(response.success, isFalse);
          expect(response.message, expectedError);
        }

        test('when a non-String is supplied for a String', () async {
          await expectError(
            {
              'program': true,
            },
            errorMessage('program', 'launch', 'String', true),
          );
        });

        test('when a non-Map is supplied for a Map', () async {
          await expectError(
            {
              'program': '',
              'env': 'test',
            },
            errorMessage('env', 'launch/attach', 'Map<String, String>', 'test'),
          );
        });

        test('when an invalid type is supplied for a Map value', () async {
          await expectError(
            {
              'program': '',
              'env': {'FOO': true}
            },
            errorMessage('env', 'launch/attach', 'Map<String, String>',
                <String, dynamic>{'FOO': true}),
          );
        });
      });

      group('for attachRequest', () {
        Future<void> expectError(
          Map<String, Object?> args,
          String expectedError,
        ) async {
          final response = await dap.client.sendRequest(
            args,
            overrideCommand: 'attach',
            allowFailure: true,
          );

          expect(response.success, isFalse);
          expect(response.message, expectedError);
        }

        test('when a non-String is supplied for a String?', () async {
          await expectError(
            {
              'vmServiceUri': true,
            },
            errorMessage('vmServiceUri', 'attach', 'String?', true),
          );
        });

        test('when a non-Map is supplied for a Map', () async {
          await expectError(
            {
              'program': '',
              'env': 'test',
            },
            errorMessage('env', 'launch/attach', 'Map<String, String>', 'test'),
          );
        });

        test('when an invalid type is supplied for a Map value', () async {
          await expectError(
            {
              'program': '',
              'env': {'FOO': true}
            },
            errorMessage('env', 'launch/attach', 'Map<String, String>',
                <String, dynamic>{'FOO': true}),
          );
        });
      });
    });

    group('for Dart Test adapter', () {
      late DapTestSession dap;
      setUp(() async {
        dap = await DapTestSession.setUp(additionalArgs: ['--test']);
      });
      tearDown(() => dap.tearDown());

      group('for launchRequest', () {
        Future<void> expectError(
          Map<String, Object?> args,
          String expectedError,
        ) async {
          final response = await dap.client.sendRequest(
            args,
            overrideCommand: 'launch',
            allowFailure: true,
          );

          expect(response.success, isFalse);
          expect(response.message, expectedError);
        }

        test('when a non-String is supplied for a String', () async {
          await expectError(
            {
              'program': true,
            },
            '"program" argument in launch configuration must be a String but provided value was a bool (true)',
          );
        });

        test('when a non-Map is supplied for a Map', () async {
          await expectError(
            {
              'program': '',
              'env': 'test',
            },
            '"env" argument in launch/attach configuration must be a Map<String, String> but provided value was a String (test)',
          );
        });

        test('when an invalid type is supplied for a Map value', () async {
          await expectError(
            {
              'program': '',
              'env': {'FOO': true}
            },
            '"env" argument in launch/attach configuration must be a Map<String, String> but provided value was a _Map<String, dynamic> ({FOO: true})',
          );
        });
      });

      group('for attachRequest', () {
        Future<void> expectError(
          Map<String, Object?> args,
          String expectedError,
        ) async {
          final response = await dap.client.sendRequest(
            args,
            overrideCommand: 'attach',
            allowFailure: true,
          );

          expect(response.success, isFalse);
          expect(response.message, expectedError);
        }

        test('when a non-String is supplied for a String?', () async {
          await expectError(
            {
              'vmServiceUri': true,
            },
            '"vmServiceUri" argument in attach configuration must be a String? but provided value was a bool (true)',
          );
        });

        test('when a non-Map is supplied for a Map', () async {
          await expectError(
            {
              'program': '',
              'env': 'test',
            },
            '"env" argument in launch/attach configuration must be a Map<String, String> but provided value was a String (test)',
          );
        });

        test('when an invalid type is supplied for a Map value', () async {
          await expectError(
            {
              'program': '',
              'env': {'FOO': true}
            },
            '"env" argument in launch/attach configuration must be a Map<String, String> but provided value was a _Map<String, dynamic> ({FOO: true})',
          );
        });
      });
    });

    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
