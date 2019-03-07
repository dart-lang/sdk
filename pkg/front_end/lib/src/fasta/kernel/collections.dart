// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library fasta.collections;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show BottomType, DartType, Expression, MapEntry, TreeNode;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import 'package:kernel/visitor.dart'
    show
        ExpressionVisitor,
        ExpressionVisitor1,
        Transformer,
        TreeVisitor,
        Visitor;

import '../problems.dart' show getFileUri, unsupported;

/// A spread element in a list or set literal.
///
/// Spread elements are not truly expressions and they cannot appear in
/// arbitrary expression contexts in the Kernel program.  They can only appear
/// as elements in list or set literals.
class SpreadElement extends Expression {
  final DartType inferredType = const BottomType();
  Expression expression;
  bool isNullAware;

  SpreadElement(this.expression, this.isNullAware) {
    expression?.parent = this;
  }

  /// Spread elements are not expressions and do not have a static type.
  @override
  DartType getStaticType(TypeEnvironment types) {
    return unsupported("getStaticType", fileOffset, getFileUri(this));
  }

  @override
  accept(ExpressionVisitor<Object> v) => v.defaultExpression(this);

  @override
  accept1(ExpressionVisitor1<Object, Object> v, arg) {
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
}

/// A spread element in a map literal.
class SpreadMapEntry extends TreeNode implements MapEntry {
  Expression expression;

  SpreadMapEntry(this.expression) {
    expression?.parent = this;
  }

  @override
  Expression get key => throw UnsupportedError('SpreadMapEntry.key getter');

  @override
  void set key(Expression expr) {
    throw UnsupportedError('SpreadMapEntry.key setter');
  }

  @override
  Expression get value => throw UnsupportedError('SpreadMapEntry.value getter');

  @override
  void set value(Expression expr) {
    throw UnsupportedError('SpreadMapEntry.value setter');
  }

  @override
  accept(TreeVisitor<Object> v) {
    throw UnsupportedError('SpreadMapEntry.accept');
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
}
