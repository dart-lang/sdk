// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library fasta.collections;

import 'package:kernel/ast.dart' show BottomType, DartType, Expression;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import 'package:kernel/visitor.dart'
    show ExpressionVisitor, ExpressionVisitor1, Transformer, Visitor;

import 'kernel_shadow_ast.dart' show ExpressionJudgment, InferenceVisitor;

import '../problems.dart' show getFileUri, unsupported;

/// A spread element in a list, map, or set literal.
///
/// Spread elements are not truly expressions and they cannot appear in
/// arbitrary expression contexts in the Kernel program.  They can only appear
/// as elements in list, map, or set literals.
class SpreadElement extends ExpressionJudgment {
  final DartType inferredType = const BottomType();
  Expression expression;

  SpreadElement(this.expression) {
    expression?.parent = this;
  }

  /// Spread elements are not expressions and do not have a static type.
  @override
  DartType getStaticType(TypeEnvironment types) {
    throw new UnsupportedError('SpreadElement.getStaticType');
  }

  @override
  accept(ExpressionVisitor<Object> v) => v.defaultExpression(this);

  @override
  accept1(ExpressionVisitor1<Object, Object> v, arg) {
    if (v is InferenceVisitor) {
      return v.visitSpreadElement(this, arg);
    }
    return unsupported("accept1", fileOffset, getFileUri(this));
  }

  @override
  visitChildren(Visitor<Object> v) {
    expression?.accept(v);
  }

  @override
  transformChildren(Transformer v) {
    if (expression != null) {
      expression = expression.accept(v);
      expression?.parent = this;
    }
  }

  @override
  void acceptInference(InferenceVisitor visitor, DartType typeContext) {
    visitor.visitSpreadElement(this, typeContext);
  }
}
