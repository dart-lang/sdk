// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Partial test that the closed world computed from [WorldImpact]s derived from
// kernel is equivalent to the original computed from resolution.
library dart2js.kernel.compiler_helper;

import 'dart:async';
import 'dart:io';

import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common/tasks.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/dart2js.dart' as dart2js;
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/library_loader.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/util/util.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:sourcemap_testing/src/stacktrace_helper.dart';
import '../memory_compiler.dart';

/// Analyze [memorySourceFiles] with [entryPoint] as entry-point using the
/// kernel based element model. The returned [Pair] contains the compiler used
/// to create the IR and the kernel based compiler.
Future<Pair<Compiler, Compiler>> analyzeOnly(
    Uri entryPoint, Map<String, String> memorySourceFiles,
    {bool printSteps: false}) async {
  if (printSteps) {
    print('---- analyze-all -------------------------------------------------');
  }
  CompilationResult result1 = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [
        Flags.useOldFrontend,
        Flags.analyzeAll,
        Flags.enableAssertMessage
      ],
      beforeRun: (compiler) {
        compiler.impactCacheDeleter.retainCachesForTesting = true;
      });

  if (printSteps) {
    print('---- closed world from kernel ------------------------------------');
  }
  ElementResolutionWorldBuilder.useInstantiationMap = true;
  CompilationResult result2 = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [Flags.analyzeOnly, Flags.enableAssertMessage],
      beforeRun: (compiler) {
        compiler.impactCacheDeleter.retainCachesForTesting = true;
      });
  return new Pair<Compiler, Compiler>(result1.compiler, result2.compiler);
}

class MemoryKernelLibraryLoaderTask extends KernelLibraryLoaderTask {
  final ir.Component component;

  MemoryKernelLibraryLoaderTask(KernelToElementMapForImpact elementMap,
      DiagnosticReporter reporter, Measurer measurer, this.component)
      : super(null, null, null, elementMap, null, reporter, measurer);

  Future<LoadedLibraries> loadLibrary(Uri resolvedUri,
      {bool skipFileWithPartOfTag: false}) async {
    return createLoadedLibraries(component);
  }
}

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

Future<Compiler> runWithD8(
    {Uri entryPoint,
    Map<String, String> memorySourceFiles: const <String, String>{},
    List<String> options: const <String>[],
    String expectedOutput,
    bool printJs: false}) async {
  entryPoint ??= Uri.parse('memory:main.dart');
  Uri mainFile =
      await createTemp(entryPoint, memorySourceFiles, printSteps: true);
  String output = uriPathToNative(mainFile.resolve('out.js').path);
  List<String> dart2jsArgs = [
    mainFile.toString(),
    '-o$output',
    '--packages=${Platform.packageConfig}',
  ]..addAll(options);
  print('Running: dart2js ${dart2jsArgs.join(' ')}');

  CompilationResult result = await dart2js.internalMain(dart2jsArgs);
  Expect.isTrue(result.isSuccess);
  if (printJs) {
    print('dart2js output:');
    print(new File(output).readAsStringSync());
  }

  List<String> d8Args = [
    'sdk/lib/_internal/js_runtime/lib/preambles/d8.js',
    output
  ];
  print('Running: d8 ${d8Args.join(' ')}');
  ProcessResult runResult = Process.runSync(d8executable, d8Args);
  String out = '${runResult.stderr}\n${runResult.stdout}';
  print('d8 output:');
  print(out);
  if (expectedOutput != null) {
    Expect.equals(0, runResult.exitCode);
    Expect.stringEquals(expectedOutput.trim(),
        runResult.stdout.replaceAll('\r\n', '\n').trim());
  }
  return result.compiler;
}

Future<Compiler> compileWithDill(
    {Uri entryPoint,
    Map<String, String> memorySourceFiles: const <String, String>{},
    List<String> options: const <String>[],
    CompilerDiagnostics diagnosticHandler,
    bool printSteps: false,
    CompilerOutput compilerOutput,
    void beforeRun(Compiler compiler)}) async {
  if (printSteps) {
    print('---- compile from dill -------------------------------------------');
  }
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: options,
      diagnosticHandler: diagnosticHandler,
      outputProvider: compilerOutput,
      beforeRun: (compiler) {
        ElementResolutionWorldBuilder.useInstantiationMap = true;
        compiler.impactCacheDeleter.retainCachesForTesting = true;
        if (beforeRun != null) {
          beforeRun(compiler);
        }
      });
  return result.compiler;
}
