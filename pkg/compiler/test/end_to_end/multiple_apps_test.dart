// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that bundling part files into the same file still allows them to load
// correctly.

import 'dart:io';

import 'package:expect/expect.dart';

import '../helpers/d8_helper.dart';

Future<Directory> createTempDir() {
  return Directory.systemTemp.createTemp('dart2js_multiple_apps_test-');
}

Future<ProcessResult> getOldCompilationResult(Uri mainFile, Uri outputFile,
    {List<String> options = const []}) async {
  print('Running: hardened dart2js');

  ProcessResult result = Process.runSync('tools/sdks/dart-sdk/bin/dart', [
    'compile',
    'js',
    mainFile.toFilePath(),
    '-o',
    outputFile.toFilePath(),
    if (Platform.packageConfig != null) '--packages=${Platform.packageConfig}',
    ...options
  ]);

  Expect.equals(
      0, result.exitCode, 'Failed to compile $mainFile with hardened SDK.');
  print('Done: created old result for $mainFile');
  return result;
}

Future<void> runTestWithOptions(List<Uri> jsFiles) async {
  print('Running: $jsFiles');

  final result = executeJsWithD8(jsFiles);
  if (result.exitCode != 0) {
    Expect.fail('Expected exit code 0 for $jsFiles. D8 results:\n'
        '${(result.stdout as String).trim()}');
  }
  Expect.equals(0, result.exitCode);
}

void main() async {
  final tmpDir = await createTempDir();
  Uri inUri = Platform.script.resolve('deferred_data/deferred_main.dart');
  Uri oldOutUri = tmpDir.uri.resolve('out-old.js');
  Uri oldOutUriMin = tmpDir.uri.resolve('out-old-min.js');
  Uri newOutUri = tmpDir.uri.resolve('out-new.js');
  Uri newOutUriMin = tmpDir.uri.resolve('out-new-min.js');

  await getCompilationResultsForD8(inUri, newOutUri);
  await getCompilationResultsForD8(inUri, newOutUriMin, options: ['--minify']);
  await getOldCompilationResult(inUri, oldOutUri);
  await getOldCompilationResult(inUri, oldOutUriMin, options: ['--minify']);

  await runTestWithOptions([oldOutUri, newOutUri]);
  await runTestWithOptions([oldOutUriMin, newOutUriMin]);
  await runTestWithOptions([newOutUri, oldOutUri]);
  await runTestWithOptions([newOutUriMin, oldOutUriMin]);
}
