// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test_runner/src/utils.dart';

void main() async {
  const testNamePartsCfe = [
    'language',
    'compile_time_constant',
    'compile_time_constant_test'
  ];
  const testNamePartsWeb = ['web', 'extension_type_assert_error_test'];
  const expectedLineCfe = 'Running CFE on 1 file...';
  final expectedUpdateTextCfe = '${testNamePartsCfe.last}.dart (3 errors)';
  final expectedLineCfeWeb =
      'Running dart2js on ${toFileNameParts(testNamePartsCfe).join('/')}...';

  final expectedLineWeb =
      'Running dart2js on ${toFileNameParts(testNamePartsWeb).join('/')}...';
  final expectedUpdateTextWeb = '${testNamePartsWeb.last}.dart (1 error)';

  await doTest(toFileNameParts(testNamePartsCfe), testNamePartsCfe,
      '--update=cfe', [expectedLineCfe], expectedUpdateTextCfe);
  await doTest(
      toFileNameParts(testNamePartsCfe),
      testNamePartsCfe,
      '--update=cfe,web',
      [expectedLineCfe, expectedLineCfeWeb],
      expectedUpdateTextCfe,
      runAll: false);
  await doTest(toFileNameParts(testNamePartsWeb), testNamePartsWeb,
      '--update=web', [expectedLineWeb], expectedUpdateTextWeb,
      runAll: false);
  await doTest(
      toFileNameParts(testNamePartsWeb),
      testNamePartsWeb,
      '--update=web,cfe',
      [expectedLineCfe, expectedLineWeb],
      expectedUpdateTextWeb,
      runAll: false);
}

List<String> toFileNameParts(List<String> testNameParts) => [
      'tests',
      ...testNameParts.take(testNameParts.length - 1),
      '${testNameParts.last}.dart',
    ];

String toFileName(List<String> fileNameParts) => p.joinAll(fileNameParts);

Future<void> doTest(List<String> fileNameParts, List<String> testNameParts,
    String target, List<String> expectedLines, String expectedUpdateText,
    {bool runAll = true}) async {
  var testFile = File(toFileName(fileNameParts));
  var testContent = testFile.readAsStringSync();
  try {
    var errorFound = false;

    var testName = testNameParts.join('/');
    errorFound |=
        await run(testName, target, expectedLines, expectedUpdateText);

    if (runAll) {
      var relativeNativePath = p.joinAll(fileNameParts);
      errorFound |= await run(
          relativeNativePath, target, expectedLines, expectedUpdateText);

      var relativeUriPath = fileNameParts.join('/');
      errorFound |=
          await run(relativeUriPath, target, expectedLines, expectedUpdateText);

      var absoluteNativePath = File(relativeNativePath).absolute.path;
      errorFound |= await run(
          absoluteNativePath, target, expectedLines, expectedUpdateText);
    }

    if (errorFound) {
      print('----------------------------------------------------------------');
      throw 'Error found!';
    }
  } finally {
    // Restore original test content.
    testFile.writeAsStringSync(testContent);
  }
}

Future<bool> run(String input, String target, List<String> expectedLines,
    String expectedUpdateText) async {
  const commonArguments = [
    'run',
    'pkg/test_runner/tool/update_static_error_tests.dart',
  ];

  var executable = Platform.resolvedExecutable;
  var arguments = [...commonArguments, target, input];
  print('--------------------------------------------------------------------');
  print('Running: $executable ${arguments.join(' ')}');
  var process = await Process.start(executable, runInShell: true, arguments);
  var lines = <String>[];
  process.stdout.forEach((e) => lines.add(decodeUtf8(e)));
  process.stderr.forEach((e) => lines.add(decodeUtf8(e)));
  var exitCode = await process.exitCode;
  var output = lines.join();
  print(output);
  print('Exit code: $exitCode');

  var hasError = false;
  for (var expectedLine in expectedLines) {
    if (!output.contains(expectedLine)) {
      print('Error: Expected output: $expectedLine');
      hasError = true;
    }
  }
  if (!output.contains(expectedUpdateText)) {
    print('Error: Expected update: $expectedUpdateText');
    hasError = true;
  }
  if (exitCode != 0) {
    print('Error: Expected exit code: 0');
    hasError = true;
  }
  return hasError;
}
