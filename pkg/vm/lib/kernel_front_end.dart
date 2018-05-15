// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the VM-specific translation of Dart source code to kernel binaries.
library vm.kernel_front_end;

import 'dart:async';

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, ErrorHandler;
import 'package:front_end/src/api_prototype/kernel_generator.dart'
    show kernelForProgram;
import 'package:front_end/src/api_prototype/compilation_message.dart'
    show CompilationMessage, Severity;
import 'package:front_end/src/fasta/severity.dart' show Severity;
import 'package:kernel/ast.dart' show Component, StaticGet, Field;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:vm/bytecode/gen_bytecode.dart' show generateBytecode;

import 'transformations/devirtualization.dart' as devirtualization
    show transformComponent;
import 'transformations/mixin_deduplication.dart' as mixin_deduplication
    show transformComponent;
import 'transformations/no_dynamic_invocations_annotator.dart'
    as no_dynamic_invocations_annotator show transformComponent;
import 'transformations/type_flow/transformer.dart' as globalTypeFlow
    show transformComponent;

/// Generates a kernel representation of the program whose main library is in
/// the given [source]. Intended for whole program (non-modular) compilation.
///
/// VM-specific replacement of [kernelForProgram].
///
Future<Component> compileToKernel(Uri source, CompilerOptions options,
    {bool aot: false,
    bool useGlobalTypeFlowAnalysis: false,
    List<String> entryPoints,
    bool genBytecode: false,
    bool dropAST: false}) async {
  // Replace error handler to detect if there are compilation errors.
  final errorDetector =
      new ErrorDetector(previousErrorHandler: options.onError);
  options.onError = errorDetector;

  final component = await kernelForProgram(source, options);

  // Restore error handler (in case 'options' are reused).
  options.onError = errorDetector.previousErrorHandler;

  // Run global transformations only if component is correct.
  if (aot && (component != null) && !errorDetector.hasCompilationErrors) {
    _runGlobalTransformations(
        component, options.strongMode, useGlobalTypeFlowAnalysis, entryPoints);
  }

  if (genBytecode && component != null) {
    generateBytecode(component,
        strongMode: options.strongMode, dropAST: dropAST);
  }

  return component;
}

_runGlobalTransformations(Component component, bool strongMode,
    bool useGlobalTypeFlowAnalysis, List<String> entryPoints) {
  if (strongMode) {
    final coreTypes = new CoreTypes(component);

    _patchVmConstants(coreTypes);

    // TODO(alexmarkov, dmitryas): Consider doing canonicalization of identical
    // mixin applications when creating mixin applications in frontend,
    // so all backends (and all transformation passes from the very beginning)
    // can benefit from mixin de-duplication.
    // At least, in addition to VM/AOT case we should run this transformation
    // when building a platform dill file for VM/JIT case.
    mixin_deduplication.transformComponent(component);

    if (useGlobalTypeFlowAnalysis) {
      globalTypeFlow.transformComponent(coreTypes, component, entryPoints);
    } else {
      devirtualization.transformComponent(coreTypes, component);
    }

    no_dynamic_invocations_annotator.transformComponent(component);
  }
}

void _patchVmConstants(CoreTypes coreTypes) {
  // Fix Endian.host to be a const field equal to Endial.little instead of
  // a final field. VM does not support big-endian architectures at the
  // moment.
  // Can't use normal patching process for this because CFE does not
  // support patching fields.
  // See http://dartbug.com/32836 for the background.
  final Field host =
      coreTypes.index.getMember('dart:typed_data', 'Endian', 'host');
  host.isConst = true;
  host.initializer = new StaticGet(
      coreTypes.index.getMember('dart:typed_data', 'Endian', 'little'))
    ..parent = host;
}

class ErrorDetector {
  final ErrorHandler previousErrorHandler;
  bool hasCompilationErrors = false;

  ErrorDetector({this.previousErrorHandler});

  void call(CompilationMessage message) {
    if (message.severity == Severity.error) {
      hasCompilationErrors = true;
    }

    previousErrorHandler?.call(message);
  }
}
