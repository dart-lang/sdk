// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:record_use/record_use_internal.dart';

import 'util.dart';

final Uri _pkgVmDir = Platform.script.resolve('../../vm/');

Future<void> runTestCase(
  Uri sourceFileUri,
  Uri sourcePackageUri,
  Uri packagesFileUri,
) async {
  final bool isThrowsTest = sourceFileUri.path.contains('throws');
  await withTempDir((String tempDir) async {
    final recordedUsesFile = path.join(tempDir, 'recorded_usages.json');
    final List<String> args = [
      Platform.executable,
      'compile',
      'wasm',
      '-O2',
      '--packages=${packagesFileUri.toFilePath()}',
      sourceFileUri.toFilePath(),
      '-o',
      path.join(tempDir, 'out.wasm'),
      '--enable-deferred-loading',
      '--extra-compiler-option=--recorded-uses=$recordedUsesFile',
    ];

    if (isThrowsTest) {
      final result = await Process.run(args.first, args.skip(1).toList());
      if (result.exitCode == 0) {
        throw 'Compilation succeeded for $sourceFileUri but was expected to fail.';
      }
      final errors = '${result.stdout}\n${result.stderr}';
      if (sourceFileUri.path.contains('invalid_location')) {
        if (!errors.contains('RecordUse') ||
            !errors.contains('cannot be placed on this element')) {
          throw 'Wrong error message for $sourceFileUri:\n$errors';
        }
      }
      return;
    }

    await run(args);

    final actualSemantic = Recordings.fromJson(
      jsonDecode(File(recordedUsesFile).readAsStringSync()),
    );
    final goldenFile = File('${sourceFileUri.toFilePath()}.json.expect');
    const update = bool.fromEnvironment('updateExpectations');

    bool semanticEquals = false;
    if (goldenFile.existsSync()) {
      try {
        final goldenContents = await goldenFile.readAsString();
        final golden = Recordings.fromJson(jsonDecode(goldenContents));
        semanticEquals =
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
      } on FormatException {
        if (!update) {
          rethrow;
        }
      }
    }

    if (update && !semanticEquals) {
      goldenFile.writeAsStringSync(
        JsonEncoder.withIndent('  ').convert(actualSemantic.toJson()),
      );
      print('Updated expectations for $sourceFileUri');
    } else if (!semanticEquals) {
      final encoder = JsonEncoder.withIndent('  ');
      print('Actual:\n${encoder.convert(actualSemantic.toJson())}');
      if (goldenFile.existsSync()) {
        final goldenContents = await goldenFile.readAsString();
        print('Expected:\n$goldenContents');
      }
      print('To update expectations, run: dart -DupdateExpectations=true '
          'pkg/dart2wasm/test/record_use_test.dart '
          '${path.basename(sourceFileUri.toFilePath())}');
      throw 'Expectations for $sourceFileUri do not match';
    }
  });
}

Future<void> main(List<String> args) async {
  assert(args.isEmpty || args.length == 1);
  final filter = args.firstOrNull;
  final recordUseTestDir = _pkgVmDir.resolve(
    'testcases/transformations/record_use/',
  );
  final testCasesDir = Directory.fromUri(recordUseTestDir.resolve('lib/'));
  final packagesFileUri = _pkgVmDir.resolve(
    '../../.dart_tool/package_config.json',
  );

  for (var fse in testCasesDir.listSync(recursive: true, followLinks: false)) {
    if (fse is! File) continue;
    if (fse.path.endsWith('.dart') &&
        !fse.path.contains('helper') &&
        (filter == null || fse.path.contains(filter))) {
      final name = path.basename(fse.path);
      final packageUri = Uri.parse('package:record_use_test/$name');
      await runTestCase(fse.uri, packageUri, packagesFileUri);
    }
  }

  await runOutsidePackageThrows(packagesFileUri);
}

Future<void> runOutsidePackageThrows(Uri packagesFileUri) async {
  await withTempDir((String tempDir) async {
    final sourceFile = File(path.join(tempDir, 'outside.dart'));
    sourceFile.writeAsStringSync('''
import 'package:meta/meta.dart' show RecordUse;
class SomeClass {
  @RecordUse()
  static String someStaticMethod(int a) => a.toString();
}
void main() {
  print(SomeClass.someStaticMethod(42));
}
''');
    final result = await Process.run(Platform.executable, [
      'compile',
      'wasm',
      '-O2',
      '--packages=${packagesFileUri.toFilePath()}',
      sourceFile.path,
      '-o',
      path.join(tempDir, 'out.wasm'),
    ]);

    if (result.exitCode == 0) {
      throw 'Compilation succeeded but was expected to fail.';
    }
    final errors = '${result.stdout}\n${result.stderr}';
    if (!errors.contains('RecordUse') || !errors.contains('package:')) {
      throw 'Wrong error message for outside package test:\n$errors';
    }
  });
}
