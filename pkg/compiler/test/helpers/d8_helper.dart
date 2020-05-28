// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Partial test that the closed world computed from [WorldImpact]s derived from
// kernel is equivalent to the original computed from resolution.
library dart2js.kernel.compiler_helper;

import 'dart:async';
import 'dart:io';

import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/dart2js.dart' as dart2js;
import 'package:_fe_analyzer_shared/src/util/filenames.dart';
import 'package:expect/expect.dart';
import 'package:sourcemap_testing/src/stacktrace_helper.dart';
import '../helpers/memory_compiler.dart';

Future createTemp(Uri entryPoint, Map<String, String> memorySourceFiles,
    {bool printSteps: false}) async {
  if (memorySourceFiles.isNotEmpty) {
    Directory dir = await Directory.systemTemp.createTemp('dart2js-with-dill');
    if (printSteps) {
      print('--- create temp directory $dir -------------------------------');
    }
    memorySourceFiles.forEach((String name, String source) {
      new File.fromUri(dir.uri.resolve(name)).writeAsStringSync(source);
    });
    entryPoint = dir.uri.resolve(entryPoint.path);
  }
  return entryPoint;
}

Future<D8Result> runWithD8(
    {Uri entryPoint,
    Map<String, String> memorySourceFiles: const <String, String>{},
    List<String> options: const <String>[],
    String expectedOutput,
    bool printJs: false,
    bool printSteps: false}) async {
  retainDataForTesting = true;
  entryPoint ??= Uri.parse('memory:main.dart');
  Uri mainFile =
      await createTemp(entryPoint, memorySourceFiles, printSteps: printSteps);
  String output = uriPathToNative(mainFile.resolve('out.js').path);
  List<String> dart2jsArgs = [
    mainFile.toString(),
    '-o$output',
    '--packages=${Platform.packageConfig}',
  ]..addAll(options);
  if (printSteps) print('Running: dart2js ${dart2jsArgs.join(' ')}');

  CompilationResult result = await dart2js.internalMain(dart2jsArgs);
  Expect.isTrue(result.isSuccess);
  if (printJs) {
    print('dart2js output:');
    print(new File(output).readAsStringSync());
  }

  List<String> d8Args = [
    '$sdkPath/_internal/js_runtime/lib/preambles/d8.js',
    output
  ];
  if (printSteps) print('Running: d8 ${d8Args.join(' ')}');
  ProcessResult runResult = Process.runSync(d8executable, d8Args);
  String out = '${runResult.stderr}\n${runResult.stdout}';
  if (printSteps) print('d8 output:');
  if (printSteps) print(out);
  if (expectedOutput != null) {
    Expect.equals(0, runResult.exitCode, "Unexpected exit code.");
    Expect.stringEquals(expectedOutput.trim(),
        runResult.stdout.replaceAll('\r\n', '\n').trim());
  }
  return new D8Result(result, runResult, output);
}

class D8Result {
  final CompilationResult compilationResult;
  final ProcessResult runResult;
  final String outputPath;

  D8Result(this.compilationResult, this.runResult, this.outputPath);
}
