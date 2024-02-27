// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart' as ir;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/src/printer.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../environment.dart';
import '../kernel/dart2js_target.dart';

class Dart2jsConstantEvaluator extends ir.TryConstantEvaluator {
  Dart2jsConstantEvaluator(ir.Component component,
      ir.TypeEnvironment typeEnvironment, ir.ReportErrorFunction reportError,
      {Environment? environment,
      super.supportReevaluationForTesting,
      required super.evaluationMode})
      : super(
          const Dart2jsDartLibrarySupport(),
          const Dart2jsConstantsBackend(supportsUnevaluatedConstants: false),
          component,
          typeEnvironment,
          reportError,
          environmentDefines: environment?.definitions ?? const {},
        );
}

/// Class to represent a reference to a constant in allocation nodes.
///
/// This class is needed in order to support serialization of references to
/// constant nodes. Since the constant nodes are not [ir.TreeNode]s we can only
/// serialize the constants as values which would bypass by the canonicalization
/// performed by the CFE. This class extends only as a trick to easily pass
/// it through serialization.
///
/// By adding a reference to the constant expression in which the constant
/// occurred, we can serialize references to constants in two steps: a reference
/// to the constant expression followed by an index of the referred constant
/// in the traversal order of the constant held by the constant expression.
///
/// This is used for list, map, and set literals.
class ConstantReference extends ir.TreeNode {
  final ir.ConstantExpression expression;
  final ir.Constant constant;

  ConstantReference(this.expression, this.constant);

  @override
  void visitChildren(ir.Visitor<Object?> v) {
    throw UnsupportedError("ConstantReference.visitChildren");
  }

  @override
  R accept<R>(ir.TreeVisitor<R> v) {
    throw UnsupportedError("ConstantReference.accept");
  }

  @override
  R accept1<R, A>(ir.TreeVisitor1<R, A> v, A arg) {
    throw UnsupportedError("ConstantReference.accept");
  }

  @override
  Never transformChildren(ir.Transformer v) {
    throw UnsupportedError("ConstantReference.transformChildren");
  }

  @override
  Never transformOrRemoveChildren(ir.RemovingTransformer v) {
    throw UnsupportedError("ConstantReference.transformOrRemoveChildren");
  }

  @override
  int get hashCode => 13 * constant.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConstantReference && constant == other.constant;
  }

  @override
  String toString() => 'ConstantReference(${toStringInternal()})';

  @override
  String toStringInternal() => 'constant=${constant.toStringInternal()}';

  @override
  String toText(ir.AstTextStrategy strategy) => constant.toText(strategy);

  @override
  void toTextInternal(ir.AstPrinter printer) =>
      constant.toTextInternal(printer);
}
