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
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/common/tasks.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/library_loader.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/util/util.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import '../memory_compiler.dart';
import '../../../../pkg/compiler/tool/generate_kernel.dart' as generate;

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
  List<Uri> uris = <Uri>[];
  Uri entryPoint = Uri.parse('memory:main.dart');
  Map<String, String> memorySourceFiles = <String, String>{
    'main.dart': 'main() {}'
  };
  for (String source in sources) {
    String name = 'input${memorySourceFiles.length}.dart';
    Uri uri = Uri.parse('memory:$name');
    memorySourceFiles[name] = source;
    uris.add(uri);
  }
  Compiler compiler = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [
        Flags.analyzeAll,
        Flags.useKernelInSsa,
        Flags.enableAssertMessage
      ]);
  compiler.librariesToAnalyzeWhenRun = uris;
  await compiler.run(entryPoint);

  List<CompileFunction> compilers = <CompileFunction>[];
  for (Uri uri in uris) {
    compilers.add(() async {
      Compiler compiler2 = compilerFor(
          entryPoint: uri,
          memorySourceFiles: memorySourceFiles,
          options: [
            Flags.analyzeOnly,
            Flags.enableAssertMessage,
            Flags.useKernel
          ]);
      ElementResolutionWorldBuilder.useInstantiationMap = true;
      compiler2.resolution.retainCachesForTesting = true;
      KernelFrontEndStrategy frontendStrategy = compiler2.frontendStrategy;
      KernelToElementMapForImpact elementMap = frontendStrategy.elementMap;
      ir.Program program = new ir.Program(
          libraries:
              compiler.backend.kernelTask.kernel.libraryDependencies(uri));
      LibraryElement library = compiler.libraryLoader.lookupLibrary(uri);
      Expect.isNotNull(library, 'No library found for $uri');
      program.mainMethod = compiler.backend.kernelTask.kernel
          .functionToIr(library.findExported(Identifiers.main));
      compiler2.libraryLoader = new MemoryKernelLibraryLoaderTask(
          elementMap, compiler2.reporter, compiler2.measurer, program);
      await compiler2.run(uri);
      return compiler2;
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
      options: [
        Flags.analyzeAll,
        Flags.useKernelInSsa,
        Flags.enableAssertMessage
      ]);
  await compiler.run(entryPoint);

  if (printSteps) {
    print('---- closed world from kernel ------------------------------------');
  }
  Compiler compiler2 = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [Flags.analyzeOnly, Flags.enableAssertMessage, Flags.useKernel]);
  ElementResolutionWorldBuilder.useInstantiationMap = true;
  compiler2.resolution.retainCachesForTesting = true;
  KernelFrontEndStrategy frontendStrategy = compiler2.frontendStrategy;
  KernelToElementMapForImpact elementMap = frontendStrategy.elementMap;
  compiler2.libraryLoader = new MemoryKernelLibraryLoaderTask(
      elementMap,
      compiler2.reporter,
      compiler2.measurer,
      compiler.backend.kernelTask.program);
  await compiler2.run(entryPoint);
  return new Pair<Compiler, Compiler>(compiler, compiler2);
}

class MemoryKernelLibraryLoaderTask extends KernelLibraryLoaderTask {
  final ir.Program program;

  MemoryKernelLibraryLoaderTask(KernelToElementMapForImpact elementMap,
      DiagnosticReporter reporter, Measurer measurer, this.program)
      : super(elementMap, null, reporter, measurer);

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
  String buildDir = Platform.isMacOS ? 'xcodebuild' : 'out';
  String configuration =
      Platform.environment['DART_CONFIGURATION'] ?? 'ReleaseX64';
  await generate.main([
    '--platform=$buildDir/$configuration/patched_dart2js_sdk/platform.dill',
    '--out=${uriPathToNative(dillFile.path)}',
    '${entryPoint.path}',
  ]);
  return dillFile;
}

Future<Compiler> compileWithDill(
    Uri entryPoint, Map<String, String> memorySourceFiles, List<String> options,
    {bool printSteps: false,
    CompilerOutput compilerOutput,
    void beforeRun(Compiler compiler)}) async {
  Uri dillFile =
      await generateDill(entryPoint, memorySourceFiles, printSteps: printSteps);

  if (printSteps) {
    print('---- compile from dill $dillFile ---------------------------------');
  }
  Compiler compiler = compilerFor(
      entryPoint: dillFile,
      options: [Flags.useKernel]..addAll(options),
      outputProvider: compilerOutput);
  ElementResolutionWorldBuilder.useInstantiationMap = true;
  compiler.resolution.retainCachesForTesting = true;
  if (beforeRun != null) {
    beforeRun(compiler);
  }
  await compiler.run(dillFile);
  return compiler;
}
