// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/kernel/constant_evaluator.dart' as kernel;
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

  final Procedure _dartInternalCheckBoundsGetter;

  ConstantEvaluator(
      WasmCompilerOptions options,
      WasmTarget target,
      Component component,
      CoreTypes coreTypes,
      ClassHierarchy classHierarchy,
      LibraryIndex libraryIndex)
      : _checkBounds = !options.translatorOptions.omitBoundsChecks,
        _dartInternalCheckBoundsGetter = libraryIndex.getTopLevelProcedure(
            "dart:_internal", "get:_checkBounds"),
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
          evaluationMode: kernel.EvaluationMode.strong,
        );

  @override
  Constant visitStaticGet(StaticGet node) {
    final target = node.target;
    if (target == _dartInternalCheckBoundsGetter) {
      return canonicalize(BoolConstant(_checkBounds));
    }

    return super.visitStaticGet(node);
  }

  // TODO: We may want consider (similar to the VM) supporting a
  // `wasm:const-evaluate` pragma that we recognize here, and then make sure
  // functions with the pragma are evaluated before TFA (raise a compile-time
  // error if they are not).
  @override
  bool shouldEvaluateMember(Member node) =>
      node == _dartInternalCheckBoundsGetter;
}
