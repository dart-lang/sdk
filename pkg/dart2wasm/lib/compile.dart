// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:build_integration/file_system/multi_root.dart'
    show MultiRootFileSystem;
import 'package:front_end/src/api_prototype/macros.dart' as macros
    show isMacroLibraryUri;
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
import 'package:kernel/library_index.dart';
import 'package:kernel/verifier.dart';
import 'package:vm/kernel_front_end.dart' show writeDepfile;
import 'package:vm/transformations/mixin_deduplication.dart'
    as mixin_deduplication show transformComponent;
import 'package:vm/transformations/to_string_transformer.dart'
    as to_string_transformer;
import 'package:vm/transformations/type_flow/transformer.dart' as globalTypeFlow
    show transformComponent;
import 'package:vm/transformations/unreachable_code_elimination.dart'
    as unreachable_code_elimination;
import 'package:wasm_builder/wasm_builder.dart' show Serializer;

import 'compiler_options.dart' as compiler;
import 'constant_evaluator.dart';
import 'js/runtime_generator.dart' as js;
import 'record_class_generator.dart';
import 'records.dart';
import 'target.dart' as wasm show Mode;
import 'target.dart' hide Mode;
import 'translator.dart';

class CompilerOutput {
  final Uint8List wasmModule;
  final String jsRuntime;
  final String? sourceMap;

  CompilerOutput(this.wasmModule, this.jsRuntime, this.sourceMap);
}

/// Compile a Dart file into a Wasm module.
///
/// Returns `null` if an error occurred during compilation. The
/// [handleDiagnosticMessage] callback will have received an error message
/// describing the error.
///
/// When generating a source map, `sourceMapUrl` argument should be provided
/// with the URL of the source map. This value will be added to the Wasm module
/// in `sourceMappingURL` section. When this argument is null the code
/// generator does not generate source mappings.
Future<CompilerOutput?> compileToModule(
    compiler.WasmCompilerOptions options,
    Uri? sourceMapUrl,
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
      enableExperimentalFfi: options.translatorOptions.enableExperimentalFfi,
      enableExperimentalWasmInterop:
          options.translatorOptions.enableExperimentalWasmInterop,
      removeAsserts: !options.translatorOptions.enableAsserts,
      mode: mode);
  CompilerOptions compilerOptions = CompilerOptions()
    ..target = target
    // This is a dummy directory that always exists. This option should be
    // unused as we pass platform.dill or libraries.json, though currently the
    // CFE mandates this option to be there (but doesn't use it).
    // => Remove this once CFE no longer mandates this (or remove option in CFE
    // entirely).
    ..sdkRoot = Uri.file('.')
    ..librariesSpecificationUri = options.librariesSpecPath
    ..packagesFileUri = options.packagesPath
    ..environmentDefines = {
      'dart.tool.dart2wasm': 'true',
      ...options.environment,
    }
    ..explicitExperimentalFlags = options.feExperimentalFlags
    ..verbose = false
    ..onDiagnostic = diagnosticMessageHandler
    ..nnbdMode = NnbdMode.Strong;
  if (options.multiRootScheme != null) {
    compilerOptions.fileSystem = MultiRootFileSystem(
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
  LibraryIndex libraryIndex = LibraryIndex(component, [
    "dart:_boxed_double",
    "dart:_boxed_int",
    "dart:_compact_hash",
    "dart:_internal",
    "dart:_js_helper",
    "dart:_js_types",
    "dart:_list",
    "dart:_string",
    "dart:_wasm",
    "dart:async",
    "dart:collection",
    "dart:core",
    "dart:ffi",
    "dart:typed_data",
  ]);

  if (options.dumpKernelAfterCfe != null) {
    writeComponentToText(component, path: options.dumpKernelAfterCfe!);
  }

  if (options.deleteToStringPackageUri.isNotEmpty) {
    to_string_transformer.transformComponent(
        component, options.deleteToStringPackageUri);
  }

  ConstantEvaluator constantEvaluator = ConstantEvaluator(
      options, target, component, coreTypes, classHierarchy, libraryIndex);
  unreachable_code_elimination.transformComponent(target, component,
      constantEvaluator, options.translatorOptions.enableAsserts);

  js.RuntimeFinalizer jsRuntimeFinalizer =
      js.createRuntimeFinalizer(component, coreTypes, classHierarchy);

  final Map<RecordShape, Class> recordClasses =
      generateRecordClasses(component, coreTypes);
  target.recordClasses = recordClasses;

  if (options.dumpKernelBeforeTfa != null) {
    writeComponentToText(component, path: options.dumpKernelBeforeTfa!);
  }

  mixin_deduplication.transformComponent(component);

  // Patch `dart:_internal`s `mainTearOff` getter.
  final internalLib = component.libraries
      .singleWhere((lib) => lib.importUri.toString() == 'dart:_internal');
  final mainTearOff = internalLib.procedures
      .singleWhere((procedure) => procedure.name.text == 'mainTearOff');
  mainTearOff.isExternal = false;
  mainTearOff.function.body = ReturnStatement(
      ConstantExpression(StaticTearOffConstant(component.mainMethod!)));

  // Keep the flags in-sync with
  // pkg/vm/test/transformations/type_flow/transformer_test.dart
  globalTypeFlow.transformComponent(target, coreTypes, component,
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

  var translator = Translator(component, coreTypes, libraryIndex, recordClasses,
      options.translatorOptions);

  String? depFile = options.depFile;
  if (depFile != null) {
    writeDepfile(
        compilerOptions.fileSystem,
        // TODO(https://dartbug.com/55246): track macro deps when available.
        component.uriToSource.keys
            .where((uri) => !macros.isMacroLibraryUri(uri)),
        options.outputFile,
        depFile);
  }

  final generateSourceMaps = options.translatorOptions.generateSourceMaps;
  final wasmModule = translator.translate(sourceMapUrl);
  final serializer = Serializer();
  wasmModule.serialize(serializer);
  final wasmModuleSerialized = serializer.data;

  final sourceMap =
      generateSourceMaps ? serializer.sourceMapSerializer.serialize() : null;

  String jsRuntime = jsRuntimeFinalizer.generate(
      translator.functions.translatedProcedures,
      translator.internalizedStringsForJSRuntime,
      mode);

  return CompilerOutput(wasmModuleSerialized, jsRuntime, sourceMap);
}
