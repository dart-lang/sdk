// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.collections;

import 'package:kernel/ast.dart';

import 'package:kernel/src/printer.dart';

import 'package:kernel/type_environment.dart' show StaticTypeContext;

import '../messages.dart'
    show noLength, templateExpectedAfterButGot, templateExpectedButGot;

import '../problems.dart' show getFileUri, unsupported;

import '../type_inference/inference_helper.dart' show InferenceHelper;

import 'internal_ast.dart';

/// Mixin for spread and control-flow elements.
///
/// Spread and control-flow elements are not truly expressions and they cannot
/// appear in arbitrary expression contexts in the Kernel program.  They can
/// only appear as elements in list or set literals.  They are translated into
/// a lower-level representation and never serialized to .dill files.
mixin ControlFlowElement on AuxiliaryExpression {
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
  R accept<R>(ExpressionVisitor<R> v) => v.visitAuxiliaryExpression(this);

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryExpression(this, arg);

  /// Returns this control flow element as a [MapLiteralEntry], or `null` if
  /// this control flow element cannot be converted into a [MapLiteralEntry].
  ///
  /// [onConvertElement] is called when a [ForElement], [ForInElement], or
  /// [IfElement] is converted to a [ForMapEntry], [ForInMapEntry], or
  /// [IfMapEntry], respectively.
  // TODO(johnniwinther): Merge this with [convertToMapEntry].
  MapLiteralEntry? toMapLiteralEntry(
      void onConvertElement(TreeNode from, TreeNode to));
}

/// A spread element in a list or set literal.
class SpreadElement extends AuxiliaryExpression with ControlFlowElement {
  Expression expression;
  bool isNullAware;

  /// The type of the elements of the collection that [expression] evaluates to.
  ///
  /// It is set during type inference and is used to add appropriate type casts
  /// during the desugaring.
  DartType? elementType;

  SpreadElement(this.expression, {required this.isNullAware}) {
    expression.parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  SpreadMapEntry toMapLiteralEntry(
      void onConvertElement(TreeNode from, TreeNode to)) {
    return new SpreadMapEntry(expression, isNullAware: isNullAware)
      ..fileOffset = fileOffset;
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
class IfElement extends AuxiliaryExpression with ControlFlowElement {
  Expression condition;
  Expression then;
  Expression? otherwise;

  IfElement(this.condition, this.then, this.otherwise) {
    condition.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    then.accept(v);
    otherwise?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    if (otherwise != null) {
      otherwise = v.transform(otherwise!);
      otherwise?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    if (otherwise != null) {
      otherwise = v.transformOrRemoveExpression(otherwise!);
      otherwise?.parent = this;
    }
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
      void onConvertElement(TreeNode from, TreeNode to)) {
    MapLiteralEntry? thenEntry;
    Expression then = this.then;
    if (then is ControlFlowElement) {
      ControlFlowElement thenElement = then;
      thenEntry = thenElement.toMapLiteralEntry(onConvertElement);
    }
    if (thenEntry == null) return null;
    MapLiteralEntry? otherwiseEntry;
    Expression? otherwise = this.otherwise;
    if (otherwise != null) {
      if (otherwise is ControlFlowElement) {
        ControlFlowElement otherwiseElement = otherwise;
        otherwiseEntry = otherwiseElement.toMapLiteralEntry(onConvertElement);
      }
      if (otherwiseEntry == null) return null;
    }
    IfMapEntry result = new IfMapEntry(condition, thenEntry, otherwiseEntry)
      ..fileOffset = fileOffset;
    onConvertElement(this, result);
    return result;
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
      printer.writeExpression(otherwise!);
    }
  }
}

/// A 'for' element in a list or set literal.
class ForElement extends AuxiliaryExpression with ControlFlowElement {
  final List<VariableDeclaration> variables; // May be empty, but not null.
  Expression? condition; // May be null.
  final List<Expression> updates; // May be empty, but not null.
  Expression body;

  ForElement(this.variables, this.condition, this.updates, this.body) {
    setParents(variables, this);
    condition?.parent = this;
    setParents(updates, this);
    body.parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(variables, this);
    if (condition != null) {
      condition = v.transform(condition!);
      condition?.parent = this;
    }
    v.transformList(updates, this);
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformVariableDeclarationList(variables, this);
    if (condition != null) {
      condition = v.transformOrRemoveExpression(condition!);
      condition?.parent = this;
    }
    v.transformExpressionList(updates, this);
    body = v.transform(body);
    body.parent = this;
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
      void onConvertElement(TreeNode from, TreeNode to)) {
    MapLiteralEntry? bodyEntry;
    Expression body = this.body;
    if (body is ControlFlowElement) {
      ControlFlowElement bodyElement = body;
      bodyEntry = bodyElement.toMapLiteralEntry(onConvertElement);
    }
    if (bodyEntry == null) return null;
    ForMapEntry result =
        new ForMapEntry(variables, condition, updates, bodyEntry)
          ..fileOffset = fileOffset;
    onConvertElement(this, result);
    return result;
  }

  @override
  String toString() {
    return "ForElement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeVariableDeclaration(variables[index],
          includeModifiersAndType: index == 0);
    }
    printer.write('; ');
    if (condition != null) {
      printer.writeExpression(condition!);
    }
    printer.write('; ');
    printer.writeExpressions(updates);
    printer.write(') ');
    printer.writeExpression(body);
  }
}

/// A 'for-in' element in a list or set literal.
class ForInElement extends AuxiliaryExpression with ControlFlowElement {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Expression? syntheticAssignment; // May be null.
  Statement? expressionEffects; // May be null.
  Expression body;
  Expression? problem; // May be null.
  bool isAsync; // True if this is an 'await for' loop.

  ForInElement(this.variable, this.iterable, this.syntheticAssignment,
      this.expressionEffects, this.body, this.problem,
      {this.isAsync = false}) {
    variable.parent = this;
    iterable.parent = this;
    syntheticAssignment?.parent = this;
    expressionEffects?.parent = this;
    body.parent = this;
    problem?.parent = this;
  }

  Statement? get prologue => syntheticAssignment != null
      ? (new ExpressionStatement(syntheticAssignment!)
        ..fileOffset = syntheticAssignment!.fileOffset)
      : expressionEffects;

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
    iterable.accept(v);
    syntheticAssignment?.accept(v);
    expressionEffects?.accept(v);
    body.accept(v);
    problem?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    iterable = v.transform(iterable);
    iterable.parent = this;
    if (syntheticAssignment != null) {
      syntheticAssignment = v.transform(syntheticAssignment!);
      syntheticAssignment?.parent = this;
    }
    if (expressionEffects != null) {
      expressionEffects = v.transform(expressionEffects!);
      expressionEffects?.parent = this;
    }
    body = v.transform(body);
    body.parent = this;
    if (problem != null) {
      problem = v.transform(problem!);
      problem?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    iterable = v.transform(iterable);
    iterable.parent = this;
    if (syntheticAssignment != null) {
      syntheticAssignment = v.transformOrRemoveExpression(syntheticAssignment!);
      syntheticAssignment?.parent = this;
    }
    if (expressionEffects != null) {
      expressionEffects = v.transformOrRemoveStatement(expressionEffects!);
      expressionEffects?.parent = this;
    }
    body = v.transform(body);
    body.parent = this;
    if (problem != null) {
      problem = v.transformOrRemoveExpression(problem!);
      problem?.parent = this;
    }
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
      void onConvertElement(TreeNode from, TreeNode to)) {
    MapLiteralEntry? bodyEntry;
    Expression body = this.body;
    if (body is ControlFlowElement) {
      bodyEntry = body.toMapLiteralEntry(onConvertElement);
    }
    if (bodyEntry == null) return null;
    ForInMapEntry result = new ForInMapEntry(variable, iterable,
        syntheticAssignment, expressionEffects, bodyEntry, problem,
        isAsync: isAsync)
      ..fileOffset = fileOffset;
    onConvertElement(this, result);
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

mixin ControlFlowMapEntry implements MapLiteralEntry {
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
  R accept<R>(TreeVisitor<R> v) => v.visitMapLiteralEntry(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitMapLiteralEntry(this, arg);

  @override
  String toStringInternal() => toText(defaultAstTextStrategy);
}

/// A spread element in a map literal.
class SpreadMapEntry extends TreeNode with ControlFlowMapEntry {
  Expression expression;
  bool isNullAware;

  /// The type of the map entries of the map that [expression] evaluates to.
  ///
  /// It is set during type inference and is used to add appropriate type casts
  /// during the desugaring.
  DartType? entryType;

  SpreadMapEntry(this.expression, {required this.isNullAware}) {
    expression.parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  String toString() {
    return "SpreadMapEntry(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    expression.toTextInternal(printer);
  }
}

/// An 'if' element in a map literal.
class IfMapEntry extends TreeNode with ControlFlowMapEntry {
  Expression condition;
  MapLiteralEntry then;
  MapLiteralEntry? otherwise;

  IfMapEntry(this.condition, this.then, this.otherwise) {
    condition.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    then.accept(v);
    otherwise?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    if (otherwise != null) {
      otherwise = v.transform(otherwise!);
      otherwise?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    if (otherwise != null) {
      otherwise = v.transformOrRemove(otherwise!, dummyMapLiteralEntry);
      otherwise?.parent = this;
    }
  }

  @override
  String toString() {
    return "IfMapEntry(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    condition.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }
}

/// A 'for' element in a map literal.
class ForMapEntry extends TreeNode with ControlFlowMapEntry {
  final List<VariableDeclaration> variables; // May be empty, but not null.
  Expression? condition; // May be null.
  final List<Expression> updates; // May be empty, but not null.
  MapLiteralEntry body;

  ForMapEntry(this.variables, this.condition, this.updates, this.body) {
    setParents(variables, this);
    condition?.parent = this;
    setParents(updates, this);
    body.parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(variables, this);
    if (condition != null) {
      condition = v.transform(condition!);
      condition?.parent = this;
    }
    v.transformList(updates, this);
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformVariableDeclarationList(variables, this);
    if (condition != null) {
      condition = v.transformOrRemoveExpression(condition!);
      condition?.parent = this;
    }
    v.transformExpressionList(updates, this);
    body = v.transform(body);
    body.parent = this;
  }

  @override
  String toString() {
    return "ForMapEntry(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeVariableDeclaration(variables[index],
          includeModifiersAndType: index == 0);
    }
    printer.write('; ');
    if (condition != null) {
      printer.writeExpression(condition!);
    }
    printer.write('; ');
    printer.writeExpressions(updates);
    printer.write(') ');
    body.toTextInternal(printer);
  }
}

/// A 'for-in' element in a map literal.
class ForInMapEntry extends TreeNode with ControlFlowMapEntry {
  VariableDeclaration variable; // Has no initializer.
  Expression iterable;
  Expression? syntheticAssignment; // May be null.
  Statement? expressionEffects; // May be null.
  MapLiteralEntry body;
  Expression? problem; // May be null.
  bool isAsync; // True if this is an 'await for' loop.

  ForInMapEntry(this.variable, this.iterable, this.syntheticAssignment,
      this.expressionEffects, this.body, this.problem,
      {required this.isAsync}) {
    variable.parent = this;
    iterable.parent = this;
    syntheticAssignment?.parent = this;
    expressionEffects?.parent = this;
    body.parent = this;
    problem?.parent = this;
  }

  Statement? get prologue => syntheticAssignment != null
      ? (new ExpressionStatement(syntheticAssignment!)
        ..fileOffset = syntheticAssignment!.fileOffset)
      : expressionEffects;

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
    iterable.accept(v);
    syntheticAssignment?.accept(v);
    expressionEffects?.accept(v);
    body.accept(v);
    problem?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    iterable = v.transform(iterable);
    iterable.parent = this;
    if (syntheticAssignment != null) {
      syntheticAssignment = v.transform(syntheticAssignment!);
      syntheticAssignment?.parent = this;
    }
    if (expressionEffects != null) {
      expressionEffects = v.transform(expressionEffects!);
      expressionEffects?.parent = this;
    }
    body = v.transform(body);
    body.parent = this;
    if (problem != null) {
      problem = v.transform(problem!);
      problem?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    iterable = v.transform(iterable);
    iterable.parent = this;
    if (syntheticAssignment != null) {
      syntheticAssignment = v.transformOrRemoveExpression(syntheticAssignment!);
      syntheticAssignment?.parent = this;
    }
    if (expressionEffects != null) {
      expressionEffects = v.transformOrRemoveStatement(expressionEffects!);
      expressionEffects?.parent = this;
    }
    body = v.transform(body);
    body.parent = this;
    if (problem != null) {
      problem = v.transformOrRemoveExpression(problem!);
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
/// [onConvertMapEntry] is called when a [ForMapEntry], [ForInMapEntry], or
/// [IfMapEntry] is converted to a [ForElement], [ForInElement], or [IfElement],
/// respectively.
Expression convertToElement(
  MapLiteralEntry entry,
  InferenceHelper? helper,
  void onConvertMapEntry(TreeNode from, TreeNode to), {
  DartType? actualType,
}) {
  if (entry is SpreadMapEntry) {
    return new SpreadElement(entry.expression, isNullAware: entry.isNullAware)
      ..elementType = actualType
      ..fileOffset = entry.expression.fileOffset;
  }
  if (entry is IfMapEntry) {
    IfElement result = new IfElement(
        entry.condition,
        convertToElement(entry.then, helper, onConvertMapEntry),
        entry.otherwise == null
            ? null
            : convertToElement(entry.otherwise!, helper, onConvertMapEntry))
      ..fileOffset = entry.fileOffset;
    onConvertMapEntry(entry, result);
    return result;
  }
  if (entry is IfCaseMapEntry) {
    IfCaseElement result = new IfCaseElement(
        prelude: entry.prelude,
        expression: entry.expression,
        patternGuard: entry.patternGuard,
        then: convertToElement(entry.then, helper, onConvertMapEntry),
        otherwise: entry.otherwise == null
            ? null
            : convertToElement(entry.otherwise!, helper, onConvertMapEntry))
      ..matchedValueType = entry.matchedValueType
      ..fileOffset = entry.fileOffset;
    onConvertMapEntry(entry, result);
    return result;
  }
  if (entry is ForMapEntry) {
    if (entry is PatternForMapEntry) {
      PatternForElement result = new PatternForElement(
          patternVariableDeclaration: entry.patternVariableDeclaration,
          intermediateVariables: entry.intermediateVariables,
          variables: entry.variables,
          condition: entry.condition,
          updates: entry.updates,
          body: convertToElement(entry.body, helper, onConvertMapEntry))
        ..fileOffset = entry.fileOffset;
      onConvertMapEntry(entry, result);
      return result;
    } else {
      ForElement result = new ForElement(
          entry.variables,
          entry.condition,
          entry.updates,
          convertToElement(entry.body, helper, onConvertMapEntry))
        ..fileOffset = entry.fileOffset;
      onConvertMapEntry(entry, result);
      return result;
    }
  }
  if (entry is ForInMapEntry) {
    ForInElement result = new ForInElement(
        entry.variable,
        entry.iterable,
        entry.syntheticAssignment,
        entry.expressionEffects,
        convertToElement(entry.body, helper, onConvertMapEntry),
        entry.problem,
        isAsync: entry.isAsync)
      ..fileOffset = entry.fileOffset;
    onConvertMapEntry(entry, result);
    return result;
  }
  Expression key = entry.key;
  if (key is InvalidExpression) {
    Expression value = entry.value;
    if (value is NullLiteral && value.fileOffset == TreeNode.noOffset) {
      // entry arose from an error.  Don't build another error.
      return key;
    }
  }
  // TODO(johnniwinther): How can this be triggered? This will fail if
  // encountered in top level inference.
  return helper!.buildProblem(
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
            isConvertibleToMapEntry(element.otherwise!));
  }
  if (element is IfCaseElement) {
    return isConvertibleToMapEntry(element.then) &&
        (element.otherwise == null ||
            isConvertibleToMapEntry(element.otherwise!));
  }
  if (element is ForElement) {
    return isConvertibleToMapEntry(element.body);
  }
  if (element is PatternForElement) {
    return isConvertibleToMapEntry(element.body);
  }
  if (element is ForInElement) {
    return isConvertibleToMapEntry(element.body);
  }
  return false;
}

/// Convert [element] to a [MapLiteralEntry], if possible. If [element] cannot
/// be converted an error reported through [helper] and a map entry holding an
/// invalid expression is returned.
///
/// [onConvertElement] is called when a [ForElement], [ForInElement], or
/// [IfElement] is converted to a [ForMapEntry], [ForInMapEntry], or
/// [IfMapEntry], respectively.
MapLiteralEntry convertToMapEntry(Expression element, InferenceHelper helper,
    void onConvertElement(TreeNode from, TreeNode to)) {
  if (element is SpreadElement) {
    return new SpreadMapEntry(element.expression,
        isNullAware: element.isNullAware)
      ..fileOffset = element.expression.fileOffset;
  }
  if (element is IfElement) {
    IfMapEntry result = new IfMapEntry(
        element.condition,
        convertToMapEntry(element.then, helper, onConvertElement),
        element.otherwise == null
            ? null
            : convertToMapEntry(element.otherwise!, helper, onConvertElement))
      ..fileOffset = element.fileOffset;
    onConvertElement(element, result);
    return result;
  }
  if (element is IfCaseElement) {
    IfCaseMapEntry result = new IfCaseMapEntry(
        prelude: [],
        expression: element.expression,
        patternGuard: element.patternGuard,
        then: convertToMapEntry(element.then, helper, onConvertElement),
        otherwise: element.otherwise == null
            ? null
            : convertToMapEntry(element.otherwise!, helper, onConvertElement))
      ..matchedValueType = element.matchedValueType
      ..fileOffset = element.fileOffset;
    onConvertElement(element, result);
    return result;
  }
  if (element is ForElement) {
    if (element is PatternForElement) {
      PatternForMapEntry result = new PatternForMapEntry(
          patternVariableDeclaration: element.patternVariableDeclaration,
          intermediateVariables: element.intermediateVariables,
          variables: element.variables,
          condition: element.condition,
          updates: element.updates,
          body: convertToMapEntry(element.body, helper, onConvertElement))
        ..fileOffset = element.fileOffset;
      onConvertElement(element, result);
      return result;
    }
    ForMapEntry result = new ForMapEntry(
        element.variables,
        element.condition,
        element.updates,
        convertToMapEntry(element.body, helper, onConvertElement))
      ..fileOffset = element.fileOffset;
    onConvertElement(element, result);
    return result;
  }
  if (element is ForInElement) {
    ForInMapEntry result = new ForInMapEntry(
        element.variable,
        element.iterable,
        element.syntheticAssignment,
        element.expressionEffects,
        convertToMapEntry(element.body, helper, onConvertElement),
        element.problem,
        isAsync: element.isAsync)
      ..fileOffset = element.fileOffset;
    onConvertElement(element, result);
    return result;
  }
  return new MapLiteralEntry(
      helper.buildProblem(
        templateExpectedAfterButGot.withArguments(':'),
        element.fileOffset,
        // TODO(danrubel): what is the length of the expression?
        noLength,
      ),
      new NullLiteral()..fileOffset = element.fileOffset)
    ..fileOffset = element.fileOffset;
}
