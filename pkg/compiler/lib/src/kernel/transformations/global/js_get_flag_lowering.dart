// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../../../options.dart';

/// An AST transformation which lowers invocations of `JS_GET_FLAG`.
///
/// `JS_GET_FLAG` is defined in `dart:_foreign_helper` and is invoked in runtime
/// libraries as a way of accessing compiler options in runtime code. The return
/// value is a de facto constant, so the compiler replaces the invocation by its
/// result before codegen rather than performing an operation at runtime.
///
/// The earlier this lowering is performed, the more optimizations are enabled.
/// Because `JS_GET_FLAG` invocations are typically used as conditions, SSA is
/// able to simplify boolean expressions and eliminate dead branches guarded by
/// `JS_GET_FLAG`. However, if we lower `JS_GET_FLAG` during SSA, the dead code
/// will still previously have been treated as live. Using a kernel
/// transformation early allows us to perform treeshaking of the now-dead
/// references as well.
///
/// This transformation is a global transformation because it needs access to
/// [CompilerOptions], which is not available modularly.
class JsGetFlagLowering {
  final CoreTypes _coreTypes;
  final CompilerOptions _options;

  JsGetFlagLowering(this._coreTypes, this._options);

  Expression transformStaticInvocation(StaticInvocation node) {
    if (node.target != _coreTypes.jsGetFlag) return node;
    final argument = node.arguments.positional.single;

    String? flag;
    if (argument is StringLiteral) {
      flag = argument.value;
    } else if (argument is ConstantExpression) {
      final constant = argument.constant;
      if (constant is StringConstant) {
        flag = constant.value;
      }
    }

    if (flag == null) _unsupportedFlag(argument);
    final flagValue = _getFlagValue(flag);
    if (flagValue == null) _unsupportedFlag(flag);
    return ConstantExpression(BoolConstant(flagValue))
      ..fileOffset = node.fileOffset;
  }

  bool? _getFlagValue(String flagName) => switch (flagName) {
        'DEV_COMPILER' => false,
        'MINIFIED' => _options.enableMinification,
        'MUST_RETAIN_METADATA' => false,
        'USE_CONTENT_SECURITY_POLICY' =>
          _options.features.useContentSecurityPolicy.isEnabled,
        'VARIANCE' => _options.enableVariance,
        'LEGACY' => _options.useLegacySubtyping,
        'EXTRA_NULL_SAFETY_CHECKS' => _options.experimentNullSafetyChecks,
        'PRINT_LEGACY_STARS' => _options.printLegacyStars,
        _ => null,
      };

  Never _unsupportedFlag(Object? flag) =>
      throw UnsupportedError('Unexpected JS_GET_FLAG argument: $flag');
}
