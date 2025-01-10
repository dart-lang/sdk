// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/dev_compiler.dart';
import 'package:dev_compiler/src/command/command.dart';
import 'package:dev_compiler/src/js_ast/js_ast.dart';
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:kernel/target/targets.dart';

/// Result compiling using [compileFromMemory].
///
/// This is meant for testing and therefore include not only the resulting
/// [Program] various artifacts of the compilation.
class MemoryCompilerResult {
  final fe.DdcResult ddcResult;
  final ProgramCompiler compiler;
  final Program program;
  final List<fe.DiagnosticMessage> errors;

  MemoryCompilerResult(
      this.ddcResult, this.compiler, this.program, this.errors);
}

/// Result of compiling using [componentFromMemory].
///
/// This is meant for use in tests and performs the front end compilation to
/// components without calling DDC.
class MemoryComponentResult {
  final fe.DdcResult ddcResult;
  final List<fe.DiagnosticMessage> errors;

  MemoryComponentResult(this.ddcResult, this.errors);
}

/// Uri used as the base uri for files provided in memory through the
/// [MemoryFileSystem].
Uri memoryDirectory = Uri.parse('memory://');

/// Compiles [entryPoint] to a kernel `Component` using the [memoryFiles] as
/// sources.
///
/// [memoryFiles] maps relative paths to their source text. [entryPoint] must
/// be absolute, using [memoryDirectory] as a base uri to refer to a file from
/// [memoryFiles].
Future<MemoryComponentResult> componentFromMemory(
    Map<String, String> memoryFiles, Uri entryPoint,
    {Map<fe.ExperimentalFlag, bool>? explicitExperimentalFlags}) async {
  var errors = <fe.DiagnosticMessage>[];
  void diagnosticMessageHandler(fe.DiagnosticMessage message) {
    if (message.severity == fe.Severity.error) {
      errors.add(message);
    }
    fe.printDiagnosticMessage(message, print);
  }

  var memoryFileSystem = fe.MemoryFileSystem(memoryDirectory);
  for (var entry in memoryFiles.entries) {
    memoryFileSystem
        .entityForUri(memoryDirectory.resolve(entry.key))
        .writeAsStringSync(entry.value);
  }
  var compilerState = fe.initializeCompiler(
      null,
      false,
      sourcePathToUri(getSdkPath()),
      sourcePathToUri(defaultSdkSummaryPath),
      null,
      sourcePathToUri(defaultLibrarySpecPath),
      [],
      DevCompilerTarget(
          TargetFlags(trackWidgetCreation: false, soundNullSafety: true)),
      fileSystem: fe.HybridFileSystem(memoryFileSystem),
      environmentDefines: {},
      explicitExperimentalFlags: explicitExperimentalFlags,
      nnbdMode: fe.NnbdMode.Strong);
  var result =
      await fe.compile(compilerState, [entryPoint], diagnosticMessageHandler);
  if (result == null) {
    throw 'Memory compilation failed';
  }
  return MemoryComponentResult(result, errors);
}

/// Compiles [entryPoint] to JavaScript using the [memoryFiles] as sources.
///
/// [memoryFiles] maps relative paths to their source text. [entryPoint] must
/// be absolute, using [memoryDirectory] as a base uri to refer to a file from
/// [memoryFiles].
Future<MemoryCompilerResult> compileFromMemory(
    Map<String, String> memoryFiles, Uri entryPoint,
    {Map<fe.ExperimentalFlag, bool>? explicitExperimentalFlags}) async {
  var MemoryComponentResult(ddcResult: result, :errors) =
      await componentFromMemory(memoryFiles, entryPoint);
  var options = Options(moduleName: 'test');
  var compiler =
      // TODO(nshahan): Do we need to support [importToSummary] and
      // [summaryToModule].
      ProgramCompiler(result.component, result.classHierarchy, options, {}, {});

  var jsModule = compiler.emitModule(result.compiledLibraries);

  return MemoryCompilerResult(result, compiler, jsModule, errors);
}
