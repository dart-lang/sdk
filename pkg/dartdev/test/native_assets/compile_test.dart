// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'dart:convert';
import 'dart:io';

import 'package:record_use/record_use.dart';
import 'package:test/test.dart';

import '../utils.dart';
import 'helpers.dart';

void main() async {
  if (!nativeAssetsExperimentAvailableOnCurrentChannel) {
    return;
  }

  test('dart compile not supported', timeout: longTimeout, () async {
    await nativeAssetsTest('dart_app', (dartAppUri) async {
      final result = await runDart(
        arguments: [
          'compile',
          'exe',
          'bin/dart_app.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: false,
      );
      expect(
        result.stderr,
        contains(
          "'dart compile' does not support build hooks, use 'dart build' instead.",
        ),
      );
      expect(result.exitCode, 255);
    });
  });

  test('Recorded usages in dart2js', timeout: longTimeout, () async {
    await recordUseTest('drop_data_asset', (dartAppUri) async {
      await runDart(
        arguments: ['pub', 'get'],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: true,
      );
      // Now try using the add symbol only, so the multiply library is
      // tree-shaken.

      await runDart(
        arguments: [
          'compile',
          'js',
          '--write-resources',
          'bin/drop_data_asset_calls.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: true,
      );

      // The build directory exists
      final recordedUsages =
          File.fromUri(dartAppUri.resolve('out.js.resources.json'));
      expect(recordedUsages.existsSync(), true);

      final actualRecordedUsages = recordedUsages.readAsStringSync();
      final u = RecordedUsages.fromJson(jsonDecode(actualRecordedUsages));
      final constArguments = u.constArgumentsFor(Identifier(
        importUri: 'package:drop_data_asset/src/drop_data_asset.dart',
        scope: 'MyMath',
        name: 'add',
      ));
      expect(constArguments.length, 1);
      expect(constArguments.first.named.isEmpty, true);
      expect(constArguments.first.positional, [3, 4]);
    });
  });

  // TODO(https://github.com/dart-lang/native/issues/2893): Implement instance
  // support.
  test('Recorded usages in dart2js - no instance support yet',
      timeout: longTimeout, () async {
    await recordUseTest('drop_data_asset', (dartAppUri) async {
      await runDart(
        arguments: ['pub', 'get'],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: true,
      );
      // Now try using the add symbol only, so the multiply library is
      // tree-shaken.
      await runDart(
        arguments: [
          'compile',
          'js',
          '--write-resources',
          'bin/drop_data_asset_instances.dart',
        ],
        workingDirectory: dartAppUri,
        logger: logger,
        expectExitCodeZero: true,
      );

      // The build directory exists
      final recordedUsages =
          File.fromUri(dartAppUri.resolve('out.js.resources.json'));
      expect(recordedUsages.existsSync(), true);

      final actualRecordedUsages = recordedUsages.readAsStringSync();
      final u = RecordedUsages.fromJson(jsonDecode(actualRecordedUsages));
      final constantsOf = u.constantsOf(Identifier(
        importUri: 'package:drop_data_asset/src/drop_data_asset.dart',
        name: 'RecordCallToC',
      ));
      expect(constantsOf.length, 0);
    });
  });
}
