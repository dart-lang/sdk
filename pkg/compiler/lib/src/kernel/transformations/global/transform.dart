// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart'
    show TryConstantEvaluator;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../../../options.dart';
import 'clone_mixin_methods_with_super.dart' as transformMixins;
import 'constant_transformer.dart';
import 'js_get_flag_lowering.dart';

void transformLibraries(
    List<Library> libraries,
    TryConstantEvaluator constantEvaluator,
    CoreTypes coreTypes,
    CompilerOptions options) {
  final transformer = _GlobalTransformer(constantEvaluator, coreTypes, options);
  libraries.forEach(transformer.visitLibrary);
}

/// Responsible for performing global transformations on the Kernel AST.
///
/// Transformations facilitated by this class include:
/// 1) Invoke [JsGetFlagLowering] which replaces static invocations of the form
/// `JS_GET_FLAG(VALUE)` with the appropriate flag value.
/// 2) Invoke [transformMixins.transformClass] which clones mixin methods that
/// use `super`.
/// 3) Evaluate unevaluated constants using the program environment and replace
/// some simple constant-like expressions with the equivalent constant.
class _GlobalTransformer extends ConstantTransformer {
  final JsGetFlagLowering _jsGetFlagLowering;

  _GlobalTransformer(
      super.constantEvaluator, CoreTypes coreTypes, super.options)
      : _jsGetFlagLowering = JsGetFlagLowering(coreTypes, options);

  @override
  TreeNode visitClass(Class node) {
    // Transform mixins before performing other transformations to avoid
    // references to stale nodes.
    transformMixins.transformClass(node);
    return super.visitClass(node);
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    final newNode = super.visitStaticInvocation(node);
    if (newNode is! StaticInvocation) return node;
    return _jsGetFlagLowering.transformStaticInvocation(newNode);
  }
}
