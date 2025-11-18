// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.18

import 'dart:io';

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

  test('Golden test for recorded usages in dart2js', timeout: longTimeout,
      () async {
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
      final expectedRecordedUsages = '''{
  "metadata": {
    "comment": "Resources referenced by annotated resource identifiers",
    "AppTag": "TBD",
    "environment": {
      "dart.web.assertions_enabled": "false",
      "dart.tool.dart2js": "true",
      "dart.tool.dart2js.minify": "false",
      "dart.tool.dart2js.disable_rti_optimization": "false",
      "dart.tool.dart2js.primitives:trust": "false",
      "dart.tool.dart2js.types:trust": "false"
    },
    "version": "0.4.0"
  },
  "constants": [
    {
      "type": "int",
      "value": 3
    },
    {
      "type": "int",
      "value": 4
    }
  ],
  "locations": [
    {
      "uri": "bin/drop_data_asset_calls.dart"
    }
  ],
  "recordings": [
    {
      "definition": {
        "identifier": {
          "uri": "package:drop_data_asset/src/drop_data_asset.dart",
          "scope": "MyMath",
          "name": "add"
        }
      },
      "calls": [
        {
          "type": "with_arguments",
          "positional": [
            0,
            1
          ],
          "loading_unit": "out.js",
          "@": 0
        }
      ]
    }
  ]
}''';
      expect(actualRecordedUsages, expectedRecordedUsages);
    });
  });

  test('Golden test for recorded usages in dart2js - no instance support yet',
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
      final expectedRecordedUsages = '''{
  "metadata": {
    "comment": "Resources referenced by annotated resource identifiers",
    "AppTag": "TBD",
    "environment": {
      "dart.web.assertions_enabled": "false",
      "dart.tool.dart2js": "true",
      "dart.tool.dart2js.minify": "false",
      "dart.tool.dart2js.disable_rti_optimization": "false",
      "dart.tool.dart2js.primitives:trust": "false",
      "dart.tool.dart2js.types:trust": "false"
    },
    "version": "0.4.0"
  }
}''';
      expect(actualRecordedUsages, expectedRecordedUsages);
    });
  });
}
