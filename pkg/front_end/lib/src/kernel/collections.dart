// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.collections;

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/type_environment.dart' show StaticTypeContext;

import '../base/messages.dart'
    show noLength, templateExpectedAfterButGot, templateExpectedButGot;
import '../base/problems.dart' show getFileUri, unsupported;
import '../type_inference/inference_helper.dart' show InferenceHelper;
import '../type_inference/inference_results.dart';
import '../type_inference/inference_visitor.dart';
import 'internal_ast.dart';

/// Base class for all control-flow elements.
sealed class ControlFlowElement extends AuxiliaryExpression {
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

/// Base class for control-flow elements with default internal implementations.
///
/// Such elements are, for example, control-flow elements containing patterns.
sealed class ControlFlowElementImpl extends InternalExpression
    implements ControlFlowElement {}

/// Mixin for spread and control-flow elements.
///
/// Spread and control-flow elements are not truly expressions and they cannot
/// appear in arbitrary expression contexts in the Kernel program.  They can
/// only appear as elements in list or set literals.  They are translated into
/// a lower-level representation and never serialized to .dill files.
///
/// [ControlFlowElementMixin] doesn't use [ControlFlowElement] as its `on`-type
/// to avoid being required in switch-statements over [ControlFlowElement]s.
mixin ControlFlowElementMixin on AuxiliaryExpression {
  /// Spread and control-flow elements are not expressions and do not have a
  /// static type.
  @override
  // Coverage-ignore(suite): Not run.
  DartType getStaticType(StaticTypeContext context) {
    return unsupported("getStaticType", fileOffset, getFileUri(this));
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType getStaticTypeInternal(StaticTypeContext context) {
    return unsupported("getStaticTypeInternal", fileOffset, getFileUri(this));
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(ExpressionVisitor<R> v) => v.visitAuxiliaryExpression(this);

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(ExpressionVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryExpression(this, arg);
}

/// A spread element in a list or set literal.
class SpreadElement extends ControlFlowElement with ControlFlowElementMixin {
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
  // Coverage-ignore(suite): Not run.
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    if (isNullAware) {
      printer.write('?');
    }
    printer.writeExpression(expression);
  }
}

class NullAwareElement extends ControlFlowElement with ControlFlowElementMixin {
  Expression expression;

  NullAwareElement(this.expression);

  @override
  MapLiteralEntry? toMapLiteralEntry(
      void Function(TreeNode from, TreeNode to) onConvertElement) {
    return unsupported("toMapLiteralEntry", fileOffset, getFileUri(this));
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('?');
    printer.writeExpression(expression);
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
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  String toString() {
    return "NullAwareElement(${toStringInternal()})";
  }
}

/// An 'if' element in a list or set literal.
class IfElement extends ControlFlowElement with ControlFlowElementMixin {
  Expression condition;
  Expression then;
  Expression? otherwise;

  IfElement(this.condition, this.then, this.otherwise) {
    condition.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitChildren(Visitor v) {
    condition.accept(v);
    then.accept(v);
    otherwise?.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
      // Coverage-ignore-block(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
class ForElement extends ControlFlowElement with ControlFlowElementMixin {
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
  // Coverage-ignore(suite): Not run.
  void visitChildren(Visitor v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
class ForInElement extends ControlFlowElement with ControlFlowElementMixin {
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
    problem
        // Coverage-ignore(suite): Not run.
        ?.parent = this;
  }

  Statement? get prologue => syntheticAssignment != null
      ? (new ExpressionStatement(syntheticAssignment!)
        ..fileOffset = syntheticAssignment!.fileOffset)
      : expressionEffects;

  @override
  // Coverage-ignore(suite): Not run.
  void visitChildren(Visitor v) {
    variable.accept(v);
    iterable.accept(v);
    syntheticAssignment?.accept(v);
    expressionEffects?.accept(v);
    body.accept(v);
    problem?.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }
}

class IfCaseElement extends ControlFlowElementImpl
    with ControlFlowElementMixin {
  Expression expression;
  PatternGuard patternGuard;
  Expression then;
  Expression? otherwise;
  List<Statement> prelude;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  IfCaseElement(
      {required this.prelude,
      required this.expression,
      required this.patternGuard,
      required this.then,
      this.otherwise}) {
    setParents(prelude, this);
    expression.parent = this;
    patternGuard.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    throw new UnsupportedError("IfCaseElement.acceptInference");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(expression);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    printer.writeExpression(then);
    if (otherwise != null) {
      printer.write(' else ');
      printer.writeExpression(otherwise!);
    }
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
      void Function(TreeNode from, TreeNode to) onConvertElement) {
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
      // Coverage-ignore-block(suite): Not run.
      if (otherwise is ControlFlowElement) {
        ControlFlowElement otherwiseElement = otherwise;
        otherwiseEntry = otherwiseElement.toMapLiteralEntry(onConvertElement);
      }
      if (otherwiseEntry == null) return null;
    }
    IfCaseMapEntry result = new IfCaseMapEntry(
        prelude: prelude,
        expression: expression,
        patternGuard: patternGuard,
        then: thenEntry,
        otherwise: otherwiseEntry)
      ..matchedValueType = matchedValueType
      ..fileOffset = fileOffset;
    onConvertElement(this, result);
    return result;
  }

  @override
  String toString() {
    return "IfCaseElement(${toStringInternal()})";
  }
}

class PatternForElement extends ControlFlowElementImpl
    with ControlFlowElementMixin
    implements ForElement {
  PatternVariableDeclaration patternVariableDeclaration;
  List<VariableDeclaration> intermediateVariables;

  @override
  final List<VariableDeclaration> variables; // May be empty, but not null.

  @override
  Expression? condition; // May be null.

  @override
  final List<Expression> updates; // May be empty, but not null.

  @override
  Expression body;

  PatternForElement(
      {required this.patternVariableDeclaration,
      required this.intermediateVariables,
      required this.variables,
      required this.condition,
      required this.updates,
      required this.body});

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    throw new UnsupportedError("PatternForElement.acceptInference");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    patternVariableDeclaration.toTextInternal(printer);
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

  @override
  MapLiteralEntry? toMapLiteralEntry(
      void Function(TreeNode from, TreeNode to) onConvertElement) {
    throw new UnimplementedError("toMapLiteralEntry");
  }

  @override
  String toString() {
    return "PatternForElement(${toStringInternal()})";
  }
}

/// Base class for all control-flow map entries.
sealed class ControlFlowMapEntry implements MapLiteralEntry {}

mixin ControlFlowMapEntryMixin implements MapLiteralEntry {
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
  // Coverage-ignore(suite): Not run.
  R accept<R>(TreeVisitor<R> v) => v.visitMapLiteralEntry(this);

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) =>
      v.visitMapLiteralEntry(this, arg);

  @override
  // Coverage-ignore(suite): Not run.
  String toStringInternal() => toText(defaultAstTextStrategy);
}

/// A null-aware entry in a map literal.
class NullAwareMapEntry extends TreeNode
    with ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
  /// `true` if the key expression is null-aware, that is, marked with `?`.
  bool isKeyNullAware;

  @override
  Expression key;

  /// `true` if the value expression is null-aware, that is, marked with `?`.
  bool isValueNullAware;

  @override
  Expression value;

  NullAwareMapEntry(
      {required this.isKeyNullAware,
      required this.key,
      required this.isValueNullAware,
      required this.value});

  @override
  void toTextInternal(AstPrinter printer) {
    if (isKeyNullAware) {
      printer.write('?');
    }
    key.toTextInternal(printer);
    printer.write(': ');
    if (isValueNullAware) {
      printer.write('?');
    }
    value.toTextInternal(printer);
  }

  @override
  void transformChildren(Transformer v) {
    key = v.transform(key);
    key.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    key = v.transform(key);
    key.parent = this;
    value = v.transform(value);
    value.parent = this;
  }

  @override
  void visitChildren(Visitor v) {
    key.accept(v);
    value.accept(v);
  }
}

/// A spread element in a map literal.
class SpreadMapEntry extends TreeNode
    with ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
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
  // Coverage-ignore(suite): Not run.
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  String toString() {
    return "SpreadMapEntry(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    expression.toTextInternal(printer);
  }
}

/// An 'if' element in a map literal.
class IfMapEntry extends TreeNode
    with ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
  Expression condition;
  MapLiteralEntry then;
  MapLiteralEntry? otherwise;

  IfMapEntry(this.condition, this.then, this.otherwise) {
    condition.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitChildren(Visitor v) {
    condition.accept(v);
    then.accept(v);
    otherwise?.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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

abstract interface class ForMapEntryBase implements TreeNode, MapLiteralEntry {
  List<VariableDeclaration> get variables;

  abstract Expression? condition;

  List<Expression> get updates;

  abstract MapLiteralEntry body;
}

/// A 'for' element in a map literal.
class ForMapEntry extends TreeNode
    with ControlFlowMapEntryMixin
    implements ForMapEntryBase, ControlFlowMapEntry {
  @override
  final List<VariableDeclaration> variables; // May be empty, but not null.

  @override
  Expression? condition; // May be null.

  @override
  final List<Expression> updates; // May be empty, but not null.

  @override
  MapLiteralEntry body;

  ForMapEntry(this.variables, this.condition, this.updates, this.body) {
    setParents(variables, this);
    condition?.parent = this;
    setParents(updates, this);
    body.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitChildren(Visitor v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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

class PatternForMapEntry extends TreeNode
    with InternalTreeNode, ControlFlowMapEntryMixin
    implements ForMapEntryBase, ControlFlowMapEntry {
  PatternVariableDeclaration patternVariableDeclaration;
  List<VariableDeclaration> intermediateVariables;

  @override
  final List<VariableDeclaration> variables;

  @override
  Expression? condition;

  @override
  final List<Expression> updates;

  @override
  MapLiteralEntry body;

  PatternForMapEntry(
      {required this.patternVariableDeclaration,
      required this.intermediateVariables,
      required this.variables,
      required this.condition,
      required this.updates,
      required this.body});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    patternVariableDeclaration.toTextInternal(printer);
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

  @override
  String toString() {
    return "PatternForMapEntry(${toStringInternal()})";
  }
}

/// A 'for-in' element in a map literal.
class ForInMapEntry extends TreeNode
    with ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
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
    problem
        // Coverage-ignore(suite): Not run.
        ?.parent = this;
  }

  Statement? get prologue => syntheticAssignment != null
      ? (new ExpressionStatement(syntheticAssignment!)
        ..fileOffset = syntheticAssignment!.fileOffset)
      : expressionEffects;

  @override
  // Coverage-ignore(suite): Not run.
  void visitChildren(Visitor v) {
    variable.accept(v);
    iterable.accept(v);
    syntheticAssignment?.accept(v);
    expressionEffects?.accept(v);
    body.accept(v);
    problem?.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }
}

class IfCaseMapEntry extends TreeNode
    with InternalTreeNode, ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
  Expression expression;
  PatternGuard patternGuard;
  MapLiteralEntry then;
  MapLiteralEntry? otherwise;
  List<Statement> prelude;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  IfCaseMapEntry(
      {required this.prelude,
      required this.expression,
      required this.patternGuard,
      required this.then,
      this.otherwise}) {
    expression.parent = this;
    patternGuard.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    expression.toTextInternal(printer);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }

  @override
  String toString() {
    return "IfCaseMapEntry(${toStringInternal()})";
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
  if (entry is ControlFlowMapEntry) {
    switch (entry) {
      case SpreadMapEntry():
        return new SpreadElement(entry.expression,
            isNullAware: entry.isNullAware)
          ..elementType = actualType
          ..fileOffset = entry.expression.fileOffset;
      case IfMapEntry():
        IfElement result = new IfElement(
            entry.condition,
            convertToElement(entry.then, helper, onConvertMapEntry),
            entry.otherwise == null
                ? null
                :
                // Coverage-ignore(suite): Not run.
                convertToElement(entry.otherwise!, helper, onConvertMapEntry))
          ..fileOffset = entry.fileOffset;
        onConvertMapEntry(entry, result);
        return result;
      case NullAwareMapEntry():
        return _convertToErroneousElement(entry, helper);
      case IfCaseMapEntry():
        IfCaseElement result = new IfCaseElement(
            prelude: entry.prelude,
            expression: entry.expression,
            patternGuard: entry.patternGuard,
            then: convertToElement(entry.then, helper, onConvertMapEntry),
            otherwise: entry.otherwise == null
                ? null
                :
                // Coverage-ignore(suite): Not run.
                convertToElement(entry.otherwise!, helper, onConvertMapEntry))
          ..matchedValueType = entry.matchedValueType
          ..fileOffset = entry.fileOffset;
        onConvertMapEntry(entry, result);
        return result;
      case PatternForMapEntry():
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
      case ForMapEntry():
        ForElement result = new ForElement(
            entry.variables,
            entry.condition,
            entry.updates,
            convertToElement(entry.body, helper, onConvertMapEntry))
          ..fileOffset = entry.fileOffset;
        onConvertMapEntry(entry, result);
        return result;
      case ForInMapEntry():
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
  } else {
    return _convertToErroneousElement(entry, helper);
  }
}

Expression _convertToErroneousElement(
    MapLiteralEntry entry, InferenceHelper? helper) {
  Expression key = entry.key;
  if (key is InvalidExpression) {
    Expression value = entry.value;
    if (value is NullLiteral && value.fileOffset == TreeNode.noOffset) {
      // entry arose from an error.  Don't build another error.
      return key;
    }
  }
  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): How can this be triggered? This will fail if
  // encountered in top level inference.
  return helper!.buildProblem(
    templateExpectedButGot.withArguments(','),
    entry.fileOffset,
    1,
  );
}

bool isConvertibleToMapEntry(Expression element) {
  if (element is ControlFlowElement) {
    switch (element) {
      case SpreadElement():
        return true;
      case NullAwareElement():
        return false;
      case IfElement():
        return isConvertibleToMapEntry(element.then) &&
            (element.otherwise == null ||
                isConvertibleToMapEntry(element.otherwise!));
      case IfCaseElement():
        return isConvertibleToMapEntry(element.then) &&
            (element.otherwise == null ||
                // Coverage-ignore(suite): Not run.
                isConvertibleToMapEntry(element.otherwise!));
      case ForElement():
        return isConvertibleToMapEntry(element.body);
      case ForInElement():
        return isConvertibleToMapEntry(element.body);
    }
  } else {
    return false;
  }
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
  if (element is ControlFlowElement) {
    switch (element) {
      case SpreadElement():
        return new SpreadMapEntry(element.expression,
            isNullAware: element.isNullAware)
          ..fileOffset = element.expression.fileOffset;

      case NullAwareElement():
        return _convertToErroneousMapEntry(element, helper);

      case IfElement():
        IfMapEntry result = new IfMapEntry(
            element.condition,
            convertToMapEntry(element.then, helper, onConvertElement),
            element.otherwise == null
                ? null
                : convertToMapEntry(
                    element.otherwise!, helper, onConvertElement))
          ..fileOffset = element.fileOffset;
        onConvertElement(element, result);
        return result;

      case IfCaseElement():
        IfCaseMapEntry result = new IfCaseMapEntry(
            prelude: [],
            expression: element.expression,
            patternGuard: element.patternGuard,
            then: convertToMapEntry(element.then, helper, onConvertElement),
            otherwise: element.otherwise == null
                ? null
                :
                // Coverage-ignore(suite): Not run.
                convertToMapEntry(element.otherwise!, helper, onConvertElement))
          ..matchedValueType = element.matchedValueType
          ..fileOffset = element.fileOffset;
        onConvertElement(element, result);
        return result;

      case PatternForElement():
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

      case ForElement():
        ForMapEntry result = new ForMapEntry(
            element.variables,
            element.condition,
            element.updates,
            convertToMapEntry(element.body, helper, onConvertElement))
          ..fileOffset = element.fileOffset;
        onConvertElement(element, result);
        return result;

      case ForInElement():
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
  } else {
    return _convertToErroneousMapEntry(element, helper);
  }
}

MapLiteralEntry _convertToErroneousMapEntry(
    Expression element, InferenceHelper helper) {
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
