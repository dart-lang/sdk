// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/constant_evaluator.dart' as kernel;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/type_environment.dart';
import 'package:vm/transformations/vm_constant_evaluator.dart';

import 'compiler_options.dart';
import 'target.dart';

class ConstantEvaluator extends kernel.ConstantEvaluator
    implements VMConstantEvaluator {
  final bool _checkBounds;
  final bool _minify;
  final bool _hasDynamicModuleSupport;
  final bool _deferredLoadingEnabled;

  final Procedure? _dartInternalCheckBoundsGetter;
  final Procedure? _dartInternalMinifyGetter;
  final Procedure? _dartInternalHasDynamicModuleSupportGetter;
  final Procedure? _dartInternalDeferredLoadingEnabled;

  ConstantEvaluator(
      WasmCompilerOptions options,
      WasmTarget target,
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy classHierarchy,
      LibraryIndex libraryIndex)
      : _checkBounds = !options.translatorOptions.omitBoundsChecks,
        _minify = options.translatorOptions.minify,
        _hasDynamicModuleSupport = options.enableDynamicModules,
        _deferredLoadingEnabled =
            options.translatorOptions.enableDeferredLoading ||
                options.translatorOptions.enableMultiModuleStressTestMode,
        _dartInternalCheckBoundsGetter = libraryIndex.tryGetProcedure(
            "dart:_internal", LibraryIndex.topLevel, "get:checkBounds"),
        _dartInternalMinifyGetter = libraryIndex.tryGetProcedure(
            "dart:_internal", LibraryIndex.topLevel, "get:minify"),
        _dartInternalHasDynamicModuleSupportGetter =
            libraryIndex.tryGetProcedure("dart:_internal",
                LibraryIndex.topLevel, "get:hasDynamicModuleSupport"),
        _dartInternalDeferredLoadingEnabled = libraryIndex.tryGetProcedure(
            "dart:_internal",
            LibraryIndex.topLevel,
            "get:deferredLoadingEnabled"),
        super(
          target.dartLibrarySupport,
          target.constantsBackend,
          component,
          options.environment,
          TypeEnvironment(coreTypes, classHierarchy),
          const kernel.SimpleErrorReporter(),
          enableTripleShift: true,
          enableAsserts: options.translatorOptions.enableAsserts,
          errorOnUnevaluatedConstant: true,
        );

  @override
  Constant visitStaticGet(StaticGet node) {
    final target = node.target;
    if (target == _dartInternalCheckBoundsGetter) {
      return canonicalize(BoolConstant(_checkBounds));
    }
    if (target == _dartInternalMinifyGetter) {
      return canonicalize(BoolConstant(_minify));
    }
    if (target == _dartInternalHasDynamicModuleSupportGetter) {
      return canonicalize(BoolConstant(_hasDynamicModuleSupport));
    }
    if (target == _dartInternalDeferredLoadingEnabled) {
      return canonicalize(BoolConstant(_deferredLoadingEnabled));
    }

    return super.visitStaticGet(node);
  }

  // TODO: We may want consider (similar to the VM) supporting a
  // `wasm:const-evaluate` pragma that we recognize here, and then make sure
  // functions with the pragma are evaluated before TFA (raise a compile-time
  // error if they are not).
  @override
  bool shouldEvaluateMember(Member node) =>
      node == _dartInternalCheckBoundsGetter ||
      node == _dartInternalMinifyGetter ||
      node == _dartInternalHasDynamicModuleSupportGetter ||
      node == _dartInternalDeferredLoadingEnabled;
}
