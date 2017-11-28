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
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/library_loader.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/util/util.dart';
import 'package:kernel/ast.dart' as ir;
import '../memory_compiler.dart';
import '../../../../pkg/compiler/tool/generate_kernel.dart' as generate;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

typedef Future<Compiler> CompileFunction();

/// Create multiple compilations for a list of [sources].
///
/// This methods speeds up testing kernel based compilation by creating the IR
/// nodes for all [sources] at the same time. The returned list of
/// [CompileFunction]s compiles one of the [source] at a time using the kernel
/// based compiler.
///
/// Currently, the returned compile function only runs with '--analyze-only'
/// flag.
Future<List<CompileFunction>> compileMultiple(List<String> sources) async {
  Uri entryPoint = Uri.parse('memory:main.dart');

  List<CompileFunction> compilers = <CompileFunction>[];
  for (String source in sources) {
    compilers.add(() async {
      Compiler compiler = compilerFor(
          entryPoint: entryPoint,
          memorySourceFiles: {
            'main.dart': source
          },
          options: [
            Flags.analyzeOnly,
            Flags.enableAssertMessage,
            Flags.useKernel
          ]);
      ElementResolutionWorldBuilder.useInstantiationMap = true;
      compiler.impactCacheDeleter.retainCachesForTesting = true;
      await compiler.run(entryPoint);
      return compiler;
    });
  }
  return compilers;
}

/// Analyze [memorySourceFiles] with [entryPoint] as entry-point using the
/// kernel based element model. The returned [Pair] contains the compiler used
/// to create the IR and the kernel based compiler.
Future<Pair<Compiler, Compiler>> analyzeOnly(
    Uri entryPoint, Map<String, String> memorySourceFiles,
    {bool printSteps: false}) async {
  if (printSteps) {
    print('---- analyze-all -------------------------------------------------');
  }
  Compiler compiler = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [Flags.analyzeAll, Flags.enableAssertMessage]);
  compiler.impactCacheDeleter.retainCachesForTesting = true;
  await compiler.run(entryPoint);

  if (printSteps) {
    print('---- closed world from kernel ------------------------------------');
  }
  Compiler compiler2 = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [Flags.analyzeOnly, Flags.enableAssertMessage, Flags.useKernel]);
  ElementResolutionWorldBuilder.useInstantiationMap = true;
  compiler2.impactCacheDeleter.retainCachesForTesting = true;
  await compiler2.run(entryPoint);
  return new Pair<Compiler, Compiler>(compiler, compiler2);
}

class MemoryKernelLibraryLoaderTask extends KernelLibraryLoaderTask {
  final ir.Program program;

  MemoryKernelLibraryLoaderTask(KernelToElementMapForImpact elementMap,
      DiagnosticReporter reporter, Measurer measurer, this.program)
      : super(null, null, elementMap, null, reporter, measurer);

  Future<LoadedLibraries> loadLibrary(Uri resolvedUri,
      {bool skipFileWithPartOfTag: false}) async {
    return createLoadedLibraries(program);
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

Future generateDill(Uri entryPoint, Map<String, String> memorySourceFiles,
    {bool printSteps: false}) async {
  entryPoint =
      await createTemp(entryPoint, memorySourceFiles, printSteps: printSteps);
  if (printSteps) {
    print('---- generate dill -----------------------------------------------');
  }

  Uri dillFile = Uri.parse('$entryPoint.dill');
  Uri platform =
      computePlatformBinariesLocation().resolve("dart2js_platform.dill");
  await generate.main([
    '--platform=${platform.toFilePath()}',
    '--out=${uriPathToNative(dillFile.path)}',
    '${entryPoint.path}',
  ]);
  return dillFile;
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
  Compiler compiler = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [Flags.useKernel]..addAll(options),
      diagnosticHandler: diagnosticHandler,
      outputProvider: compilerOutput);
  ElementResolutionWorldBuilder.useInstantiationMap = true;
  compiler.impactCacheDeleter.retainCachesForTesting = true;
  if (beforeRun != null) {
    beforeRun(compiler);
  }
  await compiler.run(entryPoint);
  return compiler;
}
