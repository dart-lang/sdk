// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        CompilerResult,
        DiagnosticMessage,
        kernelForProgram,
        Severity;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';

import 'package:vm/transformations/type_flow/transformer.dart' as globalTypeFlow
    show transformComponent;

import 'package:dart2wasm/target.dart';
import 'package:dart2wasm/translator.dart';

/// Compile a Dart file into a Wasm module.
///
/// Returns `null` if an error occurred during compilation. The
/// [handleDiagnosticMessage] callback will have received an error message
/// describing the error.
Future<Uint8List?> compileToModule(
    Uri mainUri,
    Uri sdkRoot,
    TranslatorOptions options,
    void Function(DiagnosticMessage) handleDiagnosticMessage) async {
  var succeeded = true;
  void diagnosticMessageHandler(DiagnosticMessage message) {
    if (message.severity == Severity.error) {
      succeeded = false;
    }
    handleDiagnosticMessage(message);
  }

  Target target = WasmTarget();
  CompilerOptions compilerOptions = CompilerOptions()
    ..target = target
    ..compileSdk = true
    ..sdkRoot = sdkRoot
    ..environmentDefines = {}
    ..verbose = false
    ..onDiagnostic = diagnosticMessageHandler;

  CompilerResult? compilerResult =
      await kernelForProgram(mainUri, compilerOptions);
  if (compilerResult == null || !succeeded) {
    return null;
  }
  Component component = compilerResult.component!;
  CoreTypes coreTypes = compilerResult.coreTypes!;

  globalTypeFlow.transformComponent(target, coreTypes, component,
      treeShakeSignatures: true,
      treeShakeWriteOnlyFields: true,
      useRapidTypeAnalysis: false);

  var translator = Translator(component, coreTypes,
      TypeEnvironment(coreTypes, compilerResult.classHierarchy!), options);
  return translator.translate();
}
