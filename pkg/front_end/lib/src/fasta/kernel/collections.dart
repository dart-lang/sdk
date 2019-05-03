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
        NullLiteral,
        Statement,
        TreeNode,
        VariableDeclaration,
        setParents,
        transformList,
        visitList;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import 'package:kernel/visitor.dart'
    show
        ExpressionVisitor,
        ExpressionVisitor1,
        Transformer,
        TreeVisitor,
        Visitor;

import '../messages.dart'
    show templateExpectedAfterButGot, templateExpectedButGot;

import '../problems.dart' show getFileUri, unsupported;

import '../type_inference/inference_helper.dart' show InferenceHelper;

/// Mixin for spread and control-flow elements.
///
/// Spread and control-flow elements are not truly expressions and they cannot
/// appear in arbitrary expression contexts in the Kernel program.  They can
/// only appear as elements in list or set literals.  They are translated into
/// a lower-level representation and never serialized to .dill files.
mixin ControlFlowElement on Expression {
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
class SpreadElement extends Expression with ControlFlowElement {
  Expression expression;
  bool isNullAware;

  /// The type of the elements of the collection that [expression] evaluates to.
  ///
  /// It is set during type inference and is used to add appropriate type casts
  /// during the desugaring.
  DartType elementType;

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
class IfElement extends Expression with ControlFlowElement {
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
class ForElement extends Expression with ControlFlowElement {
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
class ForInElement extends Expression with ControlFlowElement {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Statement prologue; // May be null.
  Expression body;
  Expression problem; // May be null.
  bool isAsync; // True if this is an 'await for' loop.

  ForInElement(
      this.variable, this.iterable, this.prologue, this.body, this.problem,
      {this.isAsync: false}) {
    variable?.parent = this;
    iterable?.parent = this;
    prologue?.parent = this;
    body?.parent = this;
    problem?.parent = this;
  }

  visitChildren(Visitor<Object> v) {
    variable?.accept(v);
    iterable?.accept(v);
    prologue?.accept(v);
    body?.accept(v);
    problem?.accept(v);
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
    if (prologue != null) {
      prologue = prologue.accept(v);
      prologue?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
    if (problem != null) {
      problem = problem.accept(v);
      problem?.parent = this;
    }
  }
}

mixin ControlFlowMapEntry implements MapEntry {
  @override
  Expression get key {
    throw UnsupportedError('ControlFlowMapEntry.key getter');
  }

  @override
  void set key(Expression expr) {
    throw UnsupportedError('ControlFlowMapEntry.key setter');
  }

  @override
  Expression get value {
    throw UnsupportedError('ControlFlowMapEntry.value getter');
  }

  @override
  void set value(Expression expr) {
    throw UnsupportedError('ControlFlowMapEntry.value setter');
  }

  @override
  accept(TreeVisitor<Object> v) => v.defaultTreeNode(this);
}

/// A spread element in a map literal.
class SpreadMapEntry extends TreeNode with ControlFlowMapEntry {
  Expression expression;
  bool isNullAware;

  /// The type of the map entries of the map that [expression] evaluates to.
  ///
  /// It is set during type inference and is used to add appropriate type casts
  /// during the desugaring.
  DartType entryType;

  SpreadMapEntry(this.expression, this.isNullAware) {
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

/// An 'if' element in a map literal.
class IfMapEntry extends TreeNode with ControlFlowMapEntry {
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
class ForMapEntry extends TreeNode with ControlFlowMapEntry {
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
class ForInMapEntry extends TreeNode with ControlFlowMapEntry {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Statement prologue; // May be null.
  MapEntry body;
  Expression problem; // May be null.
  bool isAsync; // True if this is an 'await for' loop.

  ForInMapEntry(
      this.variable, this.iterable, this.prologue, this.body, this.problem,
      {this.isAsync: false}) {
    variable?.parent = this;
    iterable?.parent = this;
    prologue?.parent = this;
    body?.parent = this;
    problem?.parent = this;
  }

  visitChildren(Visitor<Object> v) {
    variable?.accept(v);
    iterable?.accept(v);
    prologue?.accept(v);
    body?.accept(v);
    problem?.accept(v);
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
    if (prologue != null) {
      prologue = prologue.accept(v);
      prologue?.parent = this;
    }
    if (body != null) {
      body = body.accept(v);
      body?.parent = this;
    }
    if (problem != null) {
      problem = problem.accept(v);
      problem?.parent = this;
    }
  }
}

Expression convertToElement(MapEntry entry, InferenceHelper helper) {
  if (entry is SpreadMapEntry) {
    return new SpreadElement(entry.expression, entry.isNullAware)
      ..fileOffset = entry.expression.fileOffset;
  }
  if (entry is IfMapEntry) {
    return new IfElement(
        entry.condition,
        convertToElement(entry.then, helper),
        entry.otherwise == null
            ? null
            : convertToElement(entry.otherwise, helper))
      ..fileOffset = entry.fileOffset;
  }
  if (entry is ForMapEntry) {
    return new ForElement(entry.variables, entry.condition, entry.updates,
        convertToElement(entry.body, helper))
      ..fileOffset = entry.fileOffset;
  }
  if (entry is ForInMapEntry) {
    return new ForInElement(entry.variable, entry.iterable, entry.prologue,
        convertToElement(entry.body, helper), entry.problem,
        isAsync: entry.isAsync)
      ..fileOffset = entry.fileOffset;
  }
  return helper.desugarSyntheticExpression(helper.buildProblem(
    templateExpectedButGot.withArguments(','),
    entry.fileOffset,
    1,
  ));
}

bool isConvertibleToMapEntry(Expression element) {
  if (element is SpreadElement) return true;
  if (element is IfElement) {
    return isConvertibleToMapEntry(element.then) &&
        (element.otherwise == null ||
            isConvertibleToMapEntry(element.otherwise));
  }
  if (element is ForElement) {
    return isConvertibleToMapEntry(element.body);
  }
  if (element is ForInElement) {
    return isConvertibleToMapEntry(element.body);
  }
  return false;
}

MapEntry convertToMapEntry(Expression element, InferenceHelper helper) {
  if (element is SpreadElement) {
    return new SpreadMapEntry(element.expression, element.isNullAware)
      ..fileOffset = element.expression.fileOffset;
  }
  if (element is IfElement) {
    return new IfMapEntry(
        element.condition,
        convertToMapEntry(element.then, helper),
        element.otherwise == null
            ? null
            : convertToMapEntry(element.otherwise, helper))
      ..fileOffset = element.fileOffset;
  }
  if (element is ForElement) {
    return new ForMapEntry(element.variables, element.condition,
        element.updates, convertToMapEntry(element.body, helper))
      ..fileOffset = element.fileOffset;
  }
  if (element is ForInElement) {
    return new ForInMapEntry(
        element.variable,
        element.iterable,
        element.prologue,
        convertToMapEntry(element.body, helper),
        element.problem,
        isAsync: element.isAsync)
      ..fileOffset = element.fileOffset;
  }
  return new MapEntry(
      helper.desugarSyntheticExpression(helper.buildProblem(
        templateExpectedAfterButGot.withArguments(':'),
        element.fileOffset,
        // TODO(danrubel): what is the length of the expression?
        1,
      )),
      new NullLiteral());
}
