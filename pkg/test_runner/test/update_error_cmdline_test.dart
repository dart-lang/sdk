// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test_runner/src/utils.dart';

const commonArguments = [
  'run',
  'pkg/test_runner/tool/update_static_error_tests.dart',
  '--update=cfe',
];

const testNameParts = [
  'language',
  'compile_time_constant',
  'compile_time_constant_test'
];

final fileNameParts = [
  'tests',
  ...testNameParts.take(testNameParts.length - 1),
  '${testNameParts.last}.dart',
];

const expectedLine = 'Running CFE on 1 file...';
final expectedUpdateText = '${testNameParts.last}.dart (3 errors)';

void main() async {
  var testFile = File(p.joinAll(fileNameParts));
  var testContent = testFile.readAsStringSync();
  try {
    var errorFound = false;

    var testName = testNameParts.join('/');
    errorFound |= await run(testName);

    var relativeNativePath = p.joinAll(fileNameParts);
    errorFound |= await run(relativeNativePath);

    var relativeUriPath = fileNameParts.join('/');
    errorFound |= await run(relativeUriPath);

    var absoluteNativePath = File(relativeNativePath).absolute.path;
    var result = await run(absoluteNativePath);
    if (Platform.isWindows) {
      // TODO(johnniwinther,rnystrom): Support absolute paths on Windows.
      if (!result) {
        print('Error: Expected failure on Windows. '
            'Update test to expect success on all platforms.');
        errorFound = true;
      } else {
        print('Error on Windows is expected.');
      }
    } else {
      errorFound |= result;
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

Future<bool> run(String input) async {
  var executable = Platform.resolvedExecutable;
  var arguments = [...commonArguments, input];
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
  if (!output.contains(expectedLine)) {
    print('Error: Expected output: $expectedLine');
    hasError = true;
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
