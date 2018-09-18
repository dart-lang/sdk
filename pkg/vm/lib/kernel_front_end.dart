// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the VM-specific translation of Dart source code to kernel binaries.
library vm.kernel_front_end;

import 'dart:async';

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;
import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/fasta/fasta_codes.dart' as codes;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, ProblemHandler;
import 'package:front_end/src/api_prototype/kernel_generator.dart'
    show kernelForProgram;
import 'package:front_end/src/api_prototype/compilation_message.dart'
    show Severity;
import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/ast.dart' show Component, Field, StaticGet;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/transformations/constants.dart' as constants;
import 'package:kernel/vm/constants_native_effects.dart' as vm_constants;

import 'bytecode/gen_bytecode.dart' show generateBytecode;

import 'constants_error_reporter.dart' show ForwardConstantEvaluationErrors;
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
    Map<String, String> environmentDefines,
    bool genBytecode: false,
    bool dropAST: false,
    bool enableAsserts: false,
    bool enableConstantEvaluation: true}) async {
  // Replace error handler to detect if there are compilation errors.
  final errorDetector =
      new ErrorDetector(previousErrorHandler: options.onProblem);
  options.onProblem = errorDetector;

  final component = await kernelForProgram(source, options);

  // Run global transformations only if component is correct.
  if (aot && component != null) {
    await _runGlobalTransformations(
        source,
        options,
        component,
        options.strongMode,
        useGlobalTypeFlowAnalysis,
        entryPoints,
        environmentDefines,
        enableAsserts,
        enableConstantEvaluation,
        errorDetector);
  }

  if (genBytecode && !errorDetector.hasCompilationErrors && component != null) {
    await runWithFrontEndCompilerContext(source, options, component, () {
      generateBytecode(component,
          strongMode: options.strongMode,
          dropAST: dropAST,
          environmentDefines: environmentDefines);
    });
  }

  // Restore error handler (in case 'options' are reused).
  options.onProblem = errorDetector.previousErrorHandler;

  return component;
}

Future _runGlobalTransformations(
    Uri source,
    CompilerOptions compilerOptions,
    Component component,
    bool strongMode,
    bool useGlobalTypeFlowAnalysis,
    List<String> entryPoints,
    Map<String, String> environmentDefines,
    bool enableAsserts,
    bool enableConstantEvaluation,
    ErrorDetector errorDetector) async {
  if (strongMode) {
    if (errorDetector.hasCompilationErrors) return;

    final coreTypes = new CoreTypes(component);
    _patchVmConstants(coreTypes);

    // TODO(alexmarkov, dmitryas): Consider doing canonicalization of identical
    // mixin applications when creating mixin applications in frontend,
    // so all backends (and all transformation passes from the very beginning)
    // can benefit from mixin de-duplication.
    // At least, in addition to VM/AOT case we should run this transformation
    // when building a platform dill file for VM/JIT case.
    mixin_deduplication.transformComponent(component);

    if (enableConstantEvaluation) {
      await _performConstantEvaluation(source, compilerOptions, component,
          coreTypes, environmentDefines, strongMode, enableAsserts);

      if (errorDetector.hasCompilationErrors) return;
    }

    if (useGlobalTypeFlowAnalysis) {
      globalTypeFlow.transformComponent(
          compilerOptions.target, coreTypes, component, entryPoints);
    } else {
      devirtualization.transformComponent(coreTypes, component);
    }

    no_dynamic_invocations_annotator.transformComponent(component);
  }
}

/// Runs given [action] with [CompilerContext]. This is needed to
/// be able to report compile-time errors.
Future<T> runWithFrontEndCompilerContext<T>(Uri source,
    CompilerOptions compilerOptions, Component component, T action()) async {
  final processedOptions = new ProcessedOptions(compilerOptions, [source]);

  // Run within the context, so we have uri source tokens...
  return await CompilerContext.runWithOptions(processedOptions,
      (CompilerContext context) async {
    // To make the fileUri/fileOffset -> line/column mapping, we need to
    // pre-fill the map.
    context.uriToSource.addAll(component.uriToSource);

    return action();
  });
}

Future _performConstantEvaluation(
    Uri source,
    CompilerOptions compilerOptions,
    Component component,
    CoreTypes coreTypes,
    Map<String, String> environmentDefines,
    bool strongMode,
    bool enableAsserts) async {
  final vmConstants =
      new vm_constants.VmConstantsBackend(environmentDefines, coreTypes);

  await runWithFrontEndCompilerContext(source, compilerOptions, component, () {
    final hierarchy = new ClassHierarchy(component);
    final typeEnvironment =
        new TypeEnvironment(coreTypes, hierarchy, strongMode: strongMode);

    // TFA will remove constants fields which are unused (and respects the
    // vm/embedder entrypoints).
    constants.transformComponent(component, vmConstants,
        keepFields: true,
        strongMode: true,
        evaluateAnnotations: true,
        enableAsserts: enableAsserts,
        errorReporter: new ForwardConstantEvaluationErrors(typeEnvironment));
  });
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
  final ProblemHandler previousErrorHandler;
  bool hasCompilationErrors = false;

  ErrorDetector({this.previousErrorHandler});

  void call(codes.FormattedMessage problem, Severity severity,
      List<codes.FormattedMessage> context) {
    if (severity == Severity.error) {
      hasCompilationErrors = true;
    }

    previousErrorHandler?.call(problem, severity, context);
  }
}

class ErrorPrinter {
  final ProblemHandler previousErrorHandler;
  final compilationMessages = <Uri, List<List>>{};

  ErrorPrinter({this.previousErrorHandler});

  void call(codes.FormattedMessage problem, Severity severity,
      List<codes.FormattedMessage> context) {
    final sourceUri = problem.locatedMessage.uri;
    compilationMessages.putIfAbsent(sourceUri, () => [])
      ..add([problem, context]);
    previousErrorHandler?.call(problem, severity, context);
  }

  void printCompilationMessages(Uri baseUri) {
    final sortedUris = compilationMessages.keys.toList()
      ..sort((a, b) => '$a'.compareTo('$b'));
    for (final Uri sourceUri in sortedUris) {
      for (final List errorTuple in compilationMessages[sourceUri]) {
        final codes.FormattedMessage message = errorTuple.first;
        print(message.formatted);

        final List context = errorTuple.last;
        for (final codes.FormattedMessage message in context?.reversed) {
          print(message.formatted);
        }
      }
    }
  }
}

bool parseCommandLineDefines(
    List<String> dFlags, Map<String, String> environmentDefines, String usage) {
  for (final String dflag in dFlags) {
    final equalsSignIndex = dflag.indexOf('=');
    if (equalsSignIndex < 0) {
      environmentDefines[dflag] = '';
    } else if (equalsSignIndex > 0) {
      final key = dflag.substring(0, equalsSignIndex);
      final value = dflag.substring(equalsSignIndex + 1);
      environmentDefines[key] = value;
    } else {
      print('The environment constant options must have a key (was: "$dflag")');
      print(usage);
      return false;
    }
  }
  return true;
}
