// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:record_use/record_use_internal.dart';

import 'util.dart';

final Uri _pkgVmDir = Platform.script.resolve('../../vm/');

Future<void> runTestCase(Uri source) async {
  await withTempDir((String tempDir) async {
    final recordedUsesFile = path.join(tempDir, 'recorded_usages.json');
    await run([
      Platform.executable,
      'compile',
      'wasm',
      '-O2',
      source.toFilePath(),
      '-o',
      path.join(tempDir, 'out.wasm'),
      '--enable-deferred-loading',
      '--extra-compiler-option=--recorded-uses=$recordedUsesFile',
    ]);

    final actualSemantic = Recordings.fromJson(
      jsonDecode(File(recordedUsesFile).readAsStringSync()),
    );
    final goldenFile = File('${source.toFilePath()}.json.expect');
    final goldenContents = await goldenFile.readAsString();
    final golden = Recordings.fromJson(jsonDecode(goldenContents));
    final semanticEquals =
        actualSemantic.semanticEquals(golden, loadingUnitMapping: (unit) {
      final codeUnits = unit.codeUnits;
      int result = 0;
      int power = 1;
      for (final codeUnit in codeUnits) {
        result += (codeUnit - 35) * power;
        power *= 92;
      }
      return '$result';
    });
    const update = bool.fromEnvironment('updateExpectations');
    if (update && !semanticEquals) {
      goldenFile.writeAsStringSync(jsonEncode(actualSemantic));
      print('Updated expectations for $source');
    } else if (!semanticEquals) {
      print('Actual: ${actualSemantic.toJson()}');
      print('Expected: ${golden.toJson()}');
      print('To update expectations, run: dart -DupdateExpectations=true '
          'pkg/dart2wasm/test/record_use_test.dart '
          '${path.basename(source.toFilePath())}');
      throw 'Expectations for $source do not match';
    }
  });
}

Future<void> main(List<String> args) async {
  assert(args.isEmpty || args.length == 1);
  final filter = args.firstOrNull;
  final testCasesDir = Directory.fromUri(
    _pkgVmDir.resolve('testcases/transformations/record_use/'),
  );
  for (var fse in testCasesDir.listSync(recursive: true, followLinks: false)) {
    if (fse is! File) continue;
    if (fse.path.endsWith('.dart') &&
        !fse.path.contains('helper') &&
        (filter == null || fse.path.contains(filter))) {
      await runTestCase(fse.uri);
    }
  }
}
