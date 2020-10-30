// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library fasta.collections;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        DartType,
        Expression,
        ExpressionStatement,
        MapEntry,
        NullLiteral,
        Statement,
        TreeNode,
        VariableDeclaration,
        setParents,
        transformList,
        visitList;

import 'package:kernel/src/printer.dart';

import 'package:kernel/type_environment.dart' show StaticTypeContext;

import 'package:kernel/visitor.dart'
    show
        ExpressionVisitor,
        ExpressionVisitor1,
        Transformer,
        TreeVisitor,
        Visitor;

import '../messages.dart'
    show noLength, templateExpectedAfterButGot, templateExpectedButGot;

import '../problems.dart' show getFileUri, unsupported;

import '../type_inference/inference_helper.dart' show InferenceHelper;

/// Mixin for spread and control-flow elements.
///
/// Spread and control-flow elements are not truly expressions and they cannot
/// appear in arbitrary expression contexts in the Kernel program.  They can
/// only appear as elements in list or set literals.  They are translated into
/// a lower-level representation and never serialized to .dill files.
mixin ControlFlowElement on Expression {
  /// Spread and control-flow elements are not expressions and do not have a
  /// static type.
  @override
  DartType getStaticType(StaticTypeContext context) {
    return unsupported("getStaticType", fileOffset, getFileUri(this));
  }

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return unsupported("getStaticTypeInternal", fileOffset, getFileUri(this));
  }

  @override
  R accept<R>(ExpressionVisitor<R> v) => v.defaultExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.defaultExpression(this, arg);

  /// Returns this control flow element as a [MapEntry], or `null` if this
  /// control flow element cannot be converted into a [MapEntry].
  ///
  /// [onConvertForElement] is called when a [ForElement] or [ForInElement] is
  /// converted to a [ForMapEntry] or [ForInMapEntry], respectively.
  // TODO(johnniwinther): Merge this with [convertToMapEntry].
  MapEntry toMapEntry(void onConvertForElement(TreeNode from, TreeNode to));
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
      expression = expression.accept<TreeNode>(v);
      expression?.parent = this;
    }
  }

  @override
  SpreadMapEntry toMapEntry(
      void onConvertForElement(TreeNode from, TreeNode to)) {
    return new SpreadMapEntry(expression, isNullAware)..fileOffset = fileOffset;
  }

  @override
  String toString() {
    return "SpreadElement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    if (isNullAware) {
      printer.write('?');
    }
    printer.writeExpression(expression);
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
      condition = condition.accept<TreeNode>(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept<TreeNode>(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept<TreeNode>(v);
      otherwise?.parent = this;
    }
  }

  @override
  MapEntry toMapEntry(void onConvertForElement(TreeNode from, TreeNode to)) {
    MapEntry thenEntry;
    if (then is ControlFlowElement) {
      ControlFlowElement thenElement = then;
      thenEntry = thenElement.toMapEntry(onConvertForElement);
    }
    if (thenEntry == null) return null;
    MapEntry otherwiseEntry;
    if (otherwise != null) {
      if (otherwise is ControlFlowElement) {
        ControlFlowElement otherwiseElement = otherwise;
        otherwiseEntry = otherwiseElement.toMapEntry(onConvertForElement);
      }
      if (otherwiseEntry == null) return null;
    }
    return new IfMapEntry(condition, thenEntry, otherwiseEntry)
      ..fileOffset = fileOffset;
  }

  @override
  String toString() {
    return "IfElement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(condition);
    printer.write(') ');
    printer.writeExpression(then);
    if (otherwise != null) {
      printer.write(' else ');
      printer.writeExpression(otherwise);
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
      condition = condition.accept<TreeNode>(v);
      condition?.parent = this;
    }
    transformList(updates, v, this);
    if (body != null) {
      body = body.accept<TreeNode>(v);
      body?.parent = this;
    }
  }

  @override
  MapEntry toMapEntry(void onConvertForElement(TreeNode from, TreeNode to)) {
    MapEntry bodyEntry;
    if (body is ControlFlowElement) {
      ControlFlowElement bodyElement = body;
      bodyEntry = bodyElement.toMapEntry(onConvertForElement);
    }
    if (bodyEntry == null) return null;
    ForMapEntry result =
        new ForMapEntry(variables, condition, updates, bodyEntry)
          ..fileOffset = fileOffset;
    onConvertForElement(this, result);
    return result;
  }

  @override
  String toString() {
    return "ForElement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }
}

/// A 'for-in' element in a list or set literal.
class ForInElement extends Expression with ControlFlowElement {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Expression syntheticAssignment; // May be null.
  Statement expressionEffects; // May be null.
  Expression body;
  Expression problem; // May be null.
  bool isAsync; // True if this is an 'await for' loop.

  ForInElement(this.variable, this.iterable, this.syntheticAssignment,
      this.expressionEffects, this.body, this.problem,
      {this.isAsync: false}) {
    variable?.parent = this;
    iterable?.parent = this;
    syntheticAssignment?.parent = this;
    expressionEffects?.parent = this;
    body?.parent = this;
    problem?.parent = this;
  }

  Statement get prologue => syntheticAssignment != null
      ? (new ExpressionStatement(syntheticAssignment)
        ..fileOffset = syntheticAssignment.fileOffset)
      : expressionEffects;

  visitChildren(Visitor<Object> v) {
    variable?.accept(v);
    iterable?.accept(v);
    syntheticAssignment?.accept(v);
    expressionEffects?.accept(v);
    body?.accept(v);
    problem?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
    if (iterable != null) {
      iterable = iterable.accept<TreeNode>(v);
      iterable?.parent = this;
    }
    if (syntheticAssignment != null) {
      syntheticAssignment = syntheticAssignment.accept<TreeNode>(v);
      syntheticAssignment?.parent = this;
    }
    if (expressionEffects != null) {
      expressionEffects = expressionEffects.accept<TreeNode>(v);
      expressionEffects?.parent = this;
    }
    if (body != null) {
      body = body.accept<TreeNode>(v);
      body?.parent = this;
    }
    if (problem != null) {
      problem = problem.accept<TreeNode>(v);
      problem?.parent = this;
    }
  }

  @override
  MapEntry toMapEntry(void onConvertForElement(TreeNode from, TreeNode to)) {
    MapEntry bodyEntry;
    if (body is ControlFlowElement) {
      ControlFlowElement bodyElement = body;
      bodyEntry = bodyElement.toMapEntry(onConvertForElement);
    }
    if (bodyEntry == null) return null;
    ForInMapEntry result = new ForInMapEntry(variable, iterable,
        syntheticAssignment, expressionEffects, bodyEntry, problem,
        isAsync: isAsync)
      ..fileOffset = fileOffset;
    onConvertForElement(this, result);
    return result;
  }

  @override
  String toString() {
    return "ForInElement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }
}

mixin ControlFlowMapEntry implements MapEntry {
  @override
  Expression get key {
    throw new UnsupportedError('ControlFlowMapEntry.key getter');
  }

  @override
  void set key(Expression expr) {
    throw new UnsupportedError('ControlFlowMapEntry.key setter');
  }

  @override
  Expression get value {
    throw new UnsupportedError('ControlFlowMapEntry.value getter');
  }

  @override
  void set value(Expression expr) {
    throw new UnsupportedError('ControlFlowMapEntry.value setter');
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.defaultTreeNode(this);

  @override
  String toStringInternal() => toText(defaultAstTextStrategy);

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter state = new AstPrinter(strategy);
    toTextInternal(state);
    return state.getText();
  }
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
      expression = expression.accept<TreeNode>(v);
      expression?.parent = this;
    }
  }

  @override
  String toString() {
    return "SpreadMapEntry(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
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
      condition = condition.accept<TreeNode>(v);
      condition?.parent = this;
    }
    if (then != null) {
      then = then.accept<TreeNode>(v);
      then?.parent = this;
    }
    if (otherwise != null) {
      otherwise = otherwise.accept<TreeNode>(v);
      otherwise?.parent = this;
    }
  }

  @override
  String toString() {
    return "IfMapEntry(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
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
      condition = condition.accept<TreeNode>(v);
      condition?.parent = this;
    }
    transformList(updates, v, this);
    if (body != null) {
      body = body.accept<TreeNode>(v);
      body?.parent = this;
    }
  }

  @override
  String toString() {
    return "ForMapEntry(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }
}

/// A 'for-in' element in a map literal.
class ForInMapEntry extends TreeNode with ControlFlowMapEntry {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Expression syntheticAssignment; // May be null.
  Statement expressionEffects; // May be null.
  MapEntry body;
  Expression problem; // May be null.
  bool isAsync; // True if this is an 'await for' loop.

  ForInMapEntry(this.variable, this.iterable, this.syntheticAssignment,
      this.expressionEffects, this.body, this.problem,
      {this.isAsync})
      : assert(isAsync != null) {
    variable?.parent = this;
    iterable?.parent = this;
    syntheticAssignment?.parent = this;
    expressionEffects?.parent = this;
    body?.parent = this;
    problem?.parent = this;
  }

  Statement get prologue => syntheticAssignment != null
      ? (new ExpressionStatement(syntheticAssignment)
        ..fileOffset = syntheticAssignment.fileOffset)
      : expressionEffects;

  visitChildren(Visitor<Object> v) {
    variable?.accept(v);
    iterable?.accept(v);
    syntheticAssignment?.accept(v);
    expressionEffects?.accept(v);
    body?.accept(v);
    problem?.accept(v);
  }

  transformChildren(Transformer v) {
    if (variable != null) {
      variable = variable.accept<TreeNode>(v);
      variable?.parent = this;
    }
    if (iterable != null) {
      iterable = iterable.accept<TreeNode>(v);
      iterable?.parent = this;
    }
    if (syntheticAssignment != null) {
      syntheticAssignment = syntheticAssignment.accept<TreeNode>(v);
      syntheticAssignment?.parent = this;
    }
    if (expressionEffects != null) {
      expressionEffects = expressionEffects.accept<TreeNode>(v);
      expressionEffects?.parent = this;
    }
    if (body != null) {
      body = body.accept<TreeNode>(v);
      body?.parent = this;
    }
    if (problem != null) {
      problem = problem.accept<TreeNode>(v);
      problem?.parent = this;
    }
  }

  @override
  String toString() {
    return "ForInMapEntry(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }
}

/// Convert [entry] to an [Expression], if possible. If [entry] cannot be
/// converted an error reported through [helper] and an invalid expression is
/// returned.
///
/// [onConvertForMapEntry] is called when a [ForMapEntry] or [ForInMapEntry] is
/// converted to a [ForElement] or [ForInElement], respectively.
Expression convertToElement(MapEntry entry, InferenceHelper helper,
    void onConvertForMapEntry(TreeNode from, TreeNode to)) {
  if (entry is SpreadMapEntry) {
    return new SpreadElement(entry.expression, entry.isNullAware)
      ..fileOffset = entry.expression.fileOffset;
  }
  if (entry is IfMapEntry) {
    return new IfElement(
        entry.condition,
        convertToElement(entry.then, helper, onConvertForMapEntry),
        entry.otherwise == null
            ? null
            : convertToElement(entry.otherwise, helper, onConvertForMapEntry))
      ..fileOffset = entry.fileOffset;
  }
  if (entry is ForMapEntry) {
    ForElement result = new ForElement(
        entry.variables,
        entry.condition,
        entry.updates,
        convertToElement(entry.body, helper, onConvertForMapEntry))
      ..fileOffset = entry.fileOffset;
    onConvertForMapEntry(entry, result);
    return result;
  }
  if (entry is ForInMapEntry) {
    ForInElement result = new ForInElement(
        entry.variable,
        entry.iterable,
        entry.syntheticAssignment,
        entry.expressionEffects,
        convertToElement(entry.body, helper, onConvertForMapEntry),
        entry.problem,
        isAsync: entry.isAsync)
      ..fileOffset = entry.fileOffset;
    onConvertForMapEntry(entry, result);
    return result;
  }
  return helper.buildProblem(
    templateExpectedButGot.withArguments(','),
    entry.fileOffset,
    1,
  );
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

/// Convert [element] to a [MapEntry], if possible. If [element] cannot be
/// converted an error reported through [helper] and a map entry holding an
/// invalid expression is returned.
///
/// [onConvertForElement] is called when a [ForElement] or [ForInElement] is
/// converted to a [ForMapEntry] or [ForInMapEntry], respectively.
MapEntry convertToMapEntry(Expression element, InferenceHelper helper,
    void onConvertForElement(TreeNode from, TreeNode to)) {
  if (element is SpreadElement) {
    return new SpreadMapEntry(element.expression, element.isNullAware)
      ..fileOffset = element.expression.fileOffset;
  }
  if (element is IfElement) {
    return new IfMapEntry(
        element.condition,
        convertToMapEntry(element.then, helper, onConvertForElement),
        element.otherwise == null
            ? null
            : convertToMapEntry(element.otherwise, helper, onConvertForElement))
      ..fileOffset = element.fileOffset;
  }
  if (element is ForElement) {
    ForMapEntry result = new ForMapEntry(
        element.variables,
        element.condition,
        element.updates,
        convertToMapEntry(element.body, helper, onConvertForElement))
      ..fileOffset = element.fileOffset;
    onConvertForElement(element, result);
    return result;
  }
  if (element is ForInElement) {
    ForInMapEntry result = new ForInMapEntry(
        element.variable,
        element.iterable,
        element.syntheticAssignment,
        element.expressionEffects,
        convertToMapEntry(element.body, helper, onConvertForElement),
        element.problem,
        isAsync: element.isAsync)
      ..fileOffset = element.fileOffset;
    onConvertForElement(element, result);
    return result;
  }
  return new MapEntry(
      helper.buildProblem(
        templateExpectedAfterButGot.withArguments(':'),
        element.fileOffset,
        // TODO(danrubel): what is the length of the expression?
        noLength,
      ),
      new NullLiteral()..fileOffset = element.fileOffset)
    ..fileOffset = element.fileOffset;
}
