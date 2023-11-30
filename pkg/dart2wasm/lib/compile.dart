// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build_integration/file_system/multi_root.dart'
    show MultiRootFileSystem;

import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;
import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        CompilerResult,
        DiagnosticMessage,
        kernelForProgram,
        NnbdMode,
        Severity;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' show writeComponentToText;
import 'package:kernel/verifier.dart';

import 'package:vm/kernel_front_end.dart' show writeDepfile;

import 'package:vm/transformations/type_flow/transformer.dart' as globalTypeFlow
    show transformComponent;

import 'package:dart2wasm/compiler_options.dart' as compiler;
import 'package:dart2wasm/js/runtime_generator.dart' as js;
import 'package:dart2wasm/record_class_generator.dart';
import 'package:dart2wasm/records.dart';
import 'package:dart2wasm/target.dart' hide Mode;
import 'package:dart2wasm/target.dart' as wasm show Mode;
import 'package:dart2wasm/translator.dart';
import 'package:wasm_builder/wasm_builder.dart' show Module, Serializer;

class CompilerOutput {
  final Module _wasmModule;
  final String jsRuntime;

  late final Uint8List wasmModule = _serializeWasmModule();

  Uint8List _serializeWasmModule() {
    final s = Serializer();
    _wasmModule.serialize(s);
    return s.data;
  }

  CompilerOutput(this._wasmModule, this.jsRuntime);
}

/// Compile a Dart file into a Wasm module.
///
/// Returns `null` if an error occurred during compilation. The
/// [handleDiagnosticMessage] callback will have received an error message
/// describing the error.
Future<CompilerOutput?> compileToModule(compiler.CompilerOptions options,
    void Function(DiagnosticMessage) handleDiagnosticMessage) async {
  var succeeded = true;
  void diagnosticMessageHandler(DiagnosticMessage message) {
    if (message.severity == Severity.error) {
      succeeded = false;
    }
    handleDiagnosticMessage(message);
  }

  final wasm.Mode mode;
  if (options.translatorOptions.jsCompatibility) {
    mode = wasm.Mode.jsCompatibility;
  } else {
    mode = wasm.Mode.regular;
  }
  final WasmTarget target = WasmTarget(
      removeAsserts: !options.translatorOptions.enableAsserts, mode: mode);
  CompilerOptions compilerOptions = CompilerOptions()
    ..target = target
    ..sdkRoot = options.sdkPath
    ..librariesSpecificationUri = options.librariesSpecPath
    ..packagesFileUri = options.packagesPath
    ..environmentDefines = options.environment
    ..explicitExperimentalFlags = options.feExperimentalFlags
    ..verbose = false
    ..onDiagnostic = diagnosticMessageHandler
    ..nnbdMode = NnbdMode.Strong;
  if (options.multiRootScheme != null) {
    compilerOptions.fileSystem = new MultiRootFileSystem(
        options.multiRootScheme!,
        options.multiRoots.isEmpty ? [Uri.base] : options.multiRoots,
        StandardFileSystem.instance);
  }

  if (options.platformPath != null) {
    compilerOptions.sdkSummary = options.platformPath;
  } else {
    compilerOptions.compileSdk = true;
  }

  CompilerResult? compilerResult =
      await kernelForProgram(options.mainUri, compilerOptions);
  if (compilerResult == null || !succeeded) {
    return null;
  }
  Component component = compilerResult.component!;
  CoreTypes coreTypes = compilerResult.coreTypes!;
  ClassHierarchy classHierarchy = compilerResult.classHierarchy!;

  if (options.dumpKernelAfterCfe != null) {
    writeComponentToText(component, path: options.dumpKernelAfterCfe!);
  }

  js.RuntimeFinalizer jsRuntimeFinalizer =
      js.createRuntimeFinalizer(component, coreTypes, classHierarchy);

  final Map<RecordShape, Class> recordClasses =
      generateRecordClasses(component, coreTypes);
  target.recordClasses = recordClasses;

  if (options.dumpKernelBeforeTfa != null) {
    writeComponentToText(component, path: options.dumpKernelBeforeTfa!);
  }

  globalTypeFlow.transformComponent(target, coreTypes, component,
      treeShakeSignatures: true,
      treeShakeWriteOnlyFields: true,
      useRapidTypeAnalysis: false);

  if (options.dumpKernelAfterTfa != null) {
    writeComponentToText(component,
        path: options.dumpKernelAfterTfa!, showMetadata: true);
  }

  assert(() {
    verifyComponent(
        target, VerificationStage.afterGlobalTransformations, component);
    return true;
  }());

  var translator = Translator(
      component, coreTypes, recordClasses, options.translatorOptions);

  String? depFile = options.depFile;
  if (depFile != null) {
    writeDepfile(compilerOptions.fileSystem, component.uriToSource.keys,
        options.outputFile, depFile);
  }

  final wasmModule = translator.translate();
  String jsRuntime = jsRuntimeFinalizer.generate(
      translator.functions.translatedProcedures,
      translator.internalizedStringsForJSRuntime,
      mode);
  return CompilerOutput(wasmModule, jsRuntime);
}
