// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';
import 'package:front_end/src/fasta/kernel/constant_evaluator.dart' as kernel;
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';

import 'package:vm/transformations/vm_constant_evaluator.dart';

import 'package:dart2wasm/compiler_options.dart';
import 'package:dart2wasm/target.dart';

class ConstantEvaluator extends kernel.ConstantEvaluator
    implements VMConstantEvaluator {
  ConstantEvaluator(WasmCompilerOptions options, WasmTarget target,
      Component component, CoreTypes coreTypes, ClassHierarchy classHierarchy)
      : super(
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
  bool shouldEvaluateMember(Member node) => false;
}
