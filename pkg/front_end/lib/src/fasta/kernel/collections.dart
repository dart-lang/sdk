// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library fasta.collections;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        DartType,
        Expression,
        MapEntry,
        setParents,
        transformList,
        TreeNode,
        VariableDeclaration,
        visitList;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import 'package:kernel/visitor.dart'
    show
        ExpressionVisitor,
        ExpressionVisitor1,
        Transformer,
        TreeVisitor,
        Visitor;

import '../problems.dart' show getFileUri, unsupported;

/// Spread and control-flow elements are not truly expressions and they cannot
/// appear in arbitrary expression contexts in the Kernel program.  They can
/// only appear as elements in list or set literals.
mixin _FakeExpressionMixin on Expression {
  /// Spread and contol-flow elements are not expressions and do not have a
  /// static type.
  @override
  DartType getStaticType(TypeEnvironment types) {
    return unsupported("getStaticType", fileOffset, getFileUri(this));
  }

  @override
  accept(ExpressionVisitor<Object> v) => v.defaultExpression(this);

  @override
  accept1(ExpressionVisitor1<Object, Object> v, arg) =>
      v.defaultExpression(this, arg);
}

/// A spread element in a list or set literal.
class SpreadElement extends Expression with _FakeExpressionMixin {
  Expression expression;
  bool isNullAware;

  SpreadElement(this.expression, this.isNullAware) {
    expression?.parent = this;
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

/// An 'if' element in a list or set literal.
class IfElement extends Expression with _FakeExpressionMixin {
  Expression condition;
  Expression then;
  Expression otherwise;

  IfElement(this.condition, this.then, this.otherwise) {
    condition?.parent = this;
    then?.parent = this;
    otherwise?.parent = this;
  }

  @override
  visitChildren(Visitor<Object> v) {
    condition?.accept(v);
    then?.accept(v);
    otherwise?.accept(v);
  }

  @override
  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept(v);
      otherwise?.parent = this;
    }
  }
}

/// A 'for' element in a list or set literal.
class ForElement extends Expression with _FakeExpressionMixin {
  final List<VariableDeclaration> variables; // May be empty, but not null.
  Expression condition; // May be null.
  final List<Expression> updates; // May be empty, but not null.
  Expression body;

  ForElement(this.variables, this.condition, this.updates, this.body) {
    setParents(variables, this);
    condition?.parent = this;
    setParents(updates, this);
    body?.parent = this;
  }

  @override
  visitChildren(Visitor<Object> v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body?.accept(v);
  }

  @override
  transformChildren(Transformer v) {
    transformList(variables, v, this);
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    transformList(updates, v, this);
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

/// A 'for-in' element in a list or set literal.
class ForInElement extends Expression with _FakeExpressionMixin {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Expression body;
  bool isAsync; // True if this is an 'await for' loop.

  ForInElement(this.variable, this.iterable, this.body, {this.isAsync: false}) {
    variable?.parent = this;
    iterable?.parent = this;
    body?.parent = this;
  }

  visitChildren(Visitor<Object> v) {
    variable?.accept(v);
    iterable?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept(v);
      variable?.parent = this;
    }
    if (iterable != null) {
      iterable = iterable.accept(v);
      iterable?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

mixin _FakeMapEntryMixin implements MapEntry {
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
}

/// A spread element in a map literal.
class SpreadMapEntry extends TreeNode with _FakeMapEntryMixin {
  Expression expression;
  bool isNullAware;

  SpreadMapEntry(this.expression, this.isNullAware) {
    expression?.parent = this;
  }

  accept(TreeVisitor<Object> v) => v.defaultTreeNode(this);

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

/// An 'if' element in a map literal.
class IfMapEntry extends TreeNode with _FakeMapEntryMixin {
  Expression condition;
  MapEntry then;
  MapEntry otherwise;

  IfMapEntry(this.condition, this.then, this.otherwise) {
    condition?.parent = this;
    then?.parent = this;
    otherwise?.parent = this;
  }

  @override
  visitChildren(Visitor<Object> v) {
    condition?.accept(v);
    then?.accept(v);
    otherwise?.accept(v);
  }

  @override
  transformChildren(Transformer v) {
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept(v);
      otherwise?.parent = this;
    }
  }
}

/// A 'for' element in a map literal.
class ForMapEntry extends TreeNode with _FakeMapEntryMixin {
  final List<VariableDeclaration> variables; // May be empty, but not null.
  Expression condition; // May be null.
  final List<Expression> updates; // May be empty, but not null.
  MapEntry body;

  ForMapEntry(this.variables, this.condition, this.updates, this.body) {
    setParents(variables, this);
    condition?.parent = this;
    setParents(updates, this);
    body?.parent = this;
  }

  @override
  visitChildren(Visitor<Object> v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body?.accept(v);
  }

  @override
  transformChildren(Transformer v) {
    transformList(variables, v, this);
    if (condition != null) {
      condition = condition.accept(v);
      condition?.parent = this;
    }
    transformList(updates, v, this);
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}

/// A 'for-in' element in a map literal.
class ForInMapEntry extends TreeNode with _FakeMapEntryMixin {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  MapEntry body;
  bool isAsync; // True if this is an 'await for' loop.

  ForInMapEntry(this.variable, this.iterable, this.body,
      {this.isAsync: false}) {
    variable?.parent = this;
    iterable?.parent = this;
    body?.parent = this;
  }

  visitChildren(Visitor<Object> v) {
    variable?.accept(v);
    iterable?.accept(v);
    body?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept(v);
      variable?.parent = this;
    }
    if (iterable != null) {
      iterable = iterable.accept(v);
      iterable?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
  }
}
