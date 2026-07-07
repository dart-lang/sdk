// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/type_environment.dart' show StaticTypeContext;

import '../base/compiler_context.dart';
import '../base/messages.dart' show noLength, ProblemReporting;
import '../base/problems.dart' show getFileUri, unsupported;
import '../source/check_helper.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/inference_visitor.dart';
import 'internal_ast.dart';
import 'internal_ast_helper.dart' as intern;

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
    void onConvertElement(TreeNode from, TreeNode to),
  );
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
class SpreadElement extends ControlFlowElement
    with InternalTreeNode, ControlFlowElementMixin {
  Expression expression;
  bool isNullAware;

  /// The type of the elements of the collection that [expression] evaluates to.
  ///
  /// It is set during type inference and is used to add appropriate type casts
  /// during the desugaring.
  DartType? elementType;

  new(this.expression, {required this.isNullAware}) {
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
    void onConvertElement(TreeNode from, TreeNode to),
  ) {
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

class NullAwareElement extends ControlFlowElement
    with InternalTreeNode, ControlFlowElementMixin {
  Expression expression;

  new(this.expression);

  @override
  // Coverage-ignore(suite): Not run.
  MapLiteralEntry? toMapLiteralEntry(
    void Function(TreeNode from, TreeNode to) onConvertElement,
  ) {
    return unsupported("toMapLiteralEntry", fileOffset, getFileUri(this));
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('?');
    printer.writeExpression(expression);
  }

  @override
  String toString() {
    return "NullAwareElement(${toStringInternal()})";
  }
}

/// An 'if' element in a list or set literal.
class IfElement extends ControlFlowElement
    with InternalTreeNode, ControlFlowElementMixin {
  Expression condition;
  Expression then;
  Expression? otherwise;

  new(this.condition, this.then, this.otherwise) {
    condition.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
    void onConvertElement(TreeNode from, TreeNode to),
  ) {
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
class ForElement extends ControlFlowElement
    with InternalTreeNode, ControlFlowElementMixin
    implements ForElementBase {
  // May be empty, but not null.
  @override
  final List<InternalVariableDeclaration> internalVariables;

  @override
  Expression? condition; // May be null.

  @override
  final List<Expression> updates; // May be empty, but not null.

  @override
  Expression body;

  @override
  late List<VariableDeclaration> variables;

  new(this.internalVariables, this.condition, this.updates, this.body) {
    setParents(internalVariables, this);
    condition?.parent = this;
    setParents(updates, this);
    body.parent = this;
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
    void onConvertElement(TreeNode from, TreeNode to),
  ) {
    MapLiteralEntry? bodyEntry;
    Expression body = this.body;
    if (body is ControlFlowElement) {
      ControlFlowElement bodyElement = body;
      bodyEntry = bodyElement.toMapLiteralEntry(onConvertElement);
    }
    if (bodyEntry == null) return null;
    ForMapEntry result = new ForMapEntry(
      internalVariables,
      condition,
      updates,
      bodyEntry,
    )..fileOffset = fileOffset;
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
    for (int index = 0; index < internalVariables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      internalVariables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: internalVariables[index].initializer,
      );
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
class ForInElement extends ControlFlowElement
    with InternalTreeNode, ControlFlowElementMixin {
  final InternalForInElement element;
  Expression iterable;
  Expression body;
  final bool isAsync; // True if this is an 'await for' loop.

  /// File offset for the `for` keyword.
  final int forOffset;

  /// Variable [Scope] of this [ForInElement].
  ///
  /// Since [ForInElement] is desugared, its [scope] is passed on to other
  /// [ScopeProvider] nodes in the output.
  Scope? scope;

  late DeclaredVariable variable;

  ForInEncoding? encoding;

  new(
    this.element,
    this.iterable,
    this.body, {
    required this.isAsync,
    required int fileOffset,
    required this.forOffset,
    this.encoding,
  }) {
    this.fileOffset = fileOffset;
    iterable.parent = this;
    body.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }

  @override
  String toString() {
    return "ForInElement(${toStringInternal()})";
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
    void Function(TreeNode from, TreeNode to) onConvertElement,
  ) {
    MapLiteralEntry? bodyEntry;
    Expression body = this.body;
    if (body is ControlFlowElement) {
      bodyEntry = body.toMapLiteralEntry(onConvertElement);
    }
    if (bodyEntry == null) return null;
    ForInMapEntry result = new ForInMapEntry(
      element,
      iterable,
      bodyEntry,
      isAsync: isAsync,
      fileOffset: fileOffset,
      forOffset: forOffset,
      encoding: encoding,
    );
    onConvertElement(this, result);
    return result;
  }
}

class IfCaseElement extends ControlFlowElementImpl
    with ControlFlowElementMixin {
  Expression expression;
  InternalPatternGuard internalPatternGuard;
  Expression then;
  Expression? otherwise;
  List<Statement> prelude;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  /// [PatternGuard] computed after inference of [internalPatternGuard].
  late PatternGuard patternGuard;

  new({
    required this.prelude,
    required this.expression,
    required this.internalPatternGuard,
    required this.then,
    this.otherwise,
  }) {
    setParents(prelude, this);
    expression.parent = this;
    internalPatternGuard.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    throw new UnsupportedError("IfCaseElement.acceptInference");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(expression);
    printer.write(' case ');
    internalPatternGuard.toTextInternal(printer);
    printer.write(') ');
    printer.writeExpression(then);
    if (otherwise != null) {
      printer.write(' else ');
      printer.writeExpression(otherwise!);
    }
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
    void Function(TreeNode from, TreeNode to) onConvertElement,
  ) {
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
    IfCaseMapEntry result =
        new IfCaseMapEntry(
            prelude: prelude,
            expression: expression,
            internalPatternGuard: internalPatternGuard,
            then: thenEntry,
            otherwise: otherwiseEntry,
          )
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

abstract interface class ForElementBase implements AuxiliaryExpression {
  List<InternalVariableDeclaration> get internalVariables;

  abstract Expression? condition;

  List<Expression> get updates;

  abstract Expression body;

  /// [VariableDeclaration]s computed after inference of [internalVariables].
  abstract List<VariableDeclaration> variables;
}

class PatternForElement extends ControlFlowElementImpl
    with ControlFlowElementMixin
    implements ForElementBase {
  InternalPatternVariableDeclaration internalPatternVariableDeclaration;
  List<InternalVariableDeclaration> intermediateVariables;

  // May be empty, but not null.
  @override
  final List<InternalVariableDeclaration> internalVariables;

  @override
  Expression? condition; // May be null.

  @override
  final List<Expression> updates; // May be empty, but not null.

  @override
  Expression body;

  /// [PatternVariableDeclaration] computed after inference of
  /// [internalPatternVariableDeclaration].
  late PatternVariableDeclaration patternVariableDeclaration;

  @override
  late List<VariableDeclaration> variables;

  new({
    required this.internalPatternVariableDeclaration,
    required this.intermediateVariables,
    required this.internalVariables,
    required this.condition,
    required this.updates,
    required this.body,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    throw new UnsupportedError("PatternForElement.acceptInference");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    internalPatternVariableDeclaration.toTextInternal(printer);
    printer.write('for (');
    for (int index = 0; index < internalVariables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      internalVariables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: internalVariables[index].initializer,
      );
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
    void Function(TreeNode from, TreeNode to) onConvertElement,
  ) {
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
    with InternalTreeNode, ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
  /// `true` if the key expression is null-aware, that is, marked with `?`.
  bool isKeyNullAware;

  @override
  Expression key;

  /// `true` if the value expression is null-aware, that is, marked with `?`.
  bool isValueNullAware;

  @override
  Expression value;

  new({
    required this.isKeyNullAware,
    required this.key,
    required this.isValueNullAware,
    required this.value,
  });

  @override
  // Coverage-ignore(suite): Not run.
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
}

/// A spread element in a map literal.
class SpreadMapEntry extends TreeNode
    with InternalTreeNode, ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
  Expression expression;
  bool isNullAware;

  /// The type of the map entries of the map that [expression] evaluates to.
  ///
  /// It is set during type inference and is used to add appropriate type casts
  /// during the desugaring.
  DartType? entryType;

  new(this.expression, {required this.isNullAware}) {
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
    with InternalTreeNode, ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
  Expression condition;
  MapLiteralEntry then;
  MapLiteralEntry? otherwise;

  new(this.condition, this.then, this.otherwise) {
    condition.parent = this;
    then.parent = this;
    otherwise?.parent = this;
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
  List<InternalVariableDeclaration> get internalVariables;

  abstract Expression? condition;

  List<Expression> get updates;

  abstract MapLiteralEntry body;

  /// [VariableDeclaration]s computed after inference of [internalVariables].
  abstract List<VariableDeclaration> variables;
}

/// A 'for' element in a map literal.
class ForMapEntry extends TreeNode
    with InternalTreeNode, ControlFlowMapEntryMixin
    implements ForMapEntryBase, ControlFlowMapEntry {
  // May be empty, but not null.
  @override
  final List<InternalVariableDeclaration> internalVariables;

  @override
  Expression? condition; // May be null.

  @override
  final List<Expression> updates; // May be empty, but not null.

  @override
  MapLiteralEntry body;

  @override
  late List<VariableDeclaration> variables;

  new(this.internalVariables, this.condition, this.updates, this.body) {
    setParents(internalVariables, this);
    condition?.parent = this;
    setParents(updates, this);
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
    for (int index = 0; index < internalVariables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      internalVariables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: internalVariables[index].initializer,
      );
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
  InternalPatternVariableDeclaration internalPatternVariableDeclaration;
  List<InternalVariableDeclaration> intermediateVariables;

  @override
  final List<InternalVariableDeclaration> internalVariables;

  @override
  Expression? condition;

  @override
  final List<Expression> updates;

  @override
  MapLiteralEntry body;

  /// [PatternVariableDeclaration] computed after inference of
  /// [internalPatternVariableDeclaration].
  late PatternVariableDeclaration patternVariableDeclaration;

  @override
  late List<VariableDeclaration> variables;

  new({
    required this.internalPatternVariableDeclaration,
    required this.intermediateVariables,
    required this.internalVariables,
    required this.condition,
    required this.updates,
    required this.body,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    internalPatternVariableDeclaration.toTextInternal(printer);
    printer.write('for (');
    for (int index = 0; index < internalVariables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      internalVariables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: internalVariables[index].initializer,
      );
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
    with InternalTreeNode, ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
  final InternalForInElement element;
  Expression iterable;
  MapLiteralEntry body;
  final bool isAsync; // True if this is an 'await for' loop.

  /// File offset for the `for` keyword.
  final int forOffset;

  /// Variable [Scope] of this [ForInMapEntry].
  ///
  /// Since [ForInMapEntry] is desugared, its [scope] is passed on to other
  /// [ScopeProvider] nodes in the output.
  Scope? scope;

  late DeclaredVariable variable;

  ForInEncoding? encoding;

  new(
    this.element,
    this.iterable,
    this.body, {
    required this.isAsync,
    required int fileOffset,
    required this.forOffset,
    this.encoding,
  }) {
    this.fileOffset = fileOffset;
    iterable.parent = this;
    body.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }

  @override
  String toString() {
    return "ForInMapEntry(${toStringInternal()})";
  }
}

class IfCaseMapEntry extends TreeNode
    with InternalTreeNode, ControlFlowMapEntryMixin
    implements ControlFlowMapEntry {
  Expression expression;
  InternalPatternGuard internalPatternGuard;
  MapLiteralEntry then;
  MapLiteralEntry? otherwise;
  List<Statement> prelude;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  DartType? matchedValueType;

  /// [PatternGuard] computed after inference of [internalPatternGuard].
  late PatternGuard patternGuard;

  new({
    required this.prelude,
    required this.expression,
    required this.internalPatternGuard,
    required this.then,
    this.otherwise,
  }) {
    expression.parent = this;
    internalPatternGuard.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    expression.toTextInternal(printer);
    printer.write(' case ');
    internalPatternGuard.toTextInternal(printer);
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
                isConvertibleToMapEntry(element.otherwise!));
      case ForElement():
        return isConvertibleToMapEntry(element.body);
      case PatternForElement():
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
MapLiteralEntry convertToMapEntry(
  Expression element,
  ProblemReporting problemReporting,
  CompilerContext compilerContext,
  Uri fileUri,
  void onConvertElement(TreeNode from, TreeNode to),
) {
  if (element is ControlFlowElement) {
    switch (element) {
      case SpreadElement():
        return new SpreadMapEntry(
          element.expression,
          isNullAware: element.isNullAware,
        )..fileOffset = element.expression.fileOffset;

      case NullAwareElement():
        // Coverage-ignore(suite): Not run.
        return _convertToErroneousMapEntry(
          element,
          problemReporting,
          compilerContext,
          fileUri,
        );

      case IfElement():
        IfMapEntry result = new IfMapEntry(
          element.condition,
          convertToMapEntry(
            element.then,
            problemReporting,
            compilerContext,
            fileUri,
            onConvertElement,
          ),
          element.otherwise == null
              ? null
              : convertToMapEntry(
                  element.otherwise!,
                  problemReporting,
                  compilerContext,
                  fileUri,
                  onConvertElement,
                ),
        )..fileOffset = element.fileOffset;
        onConvertElement(element, result);
        return result;

      case IfCaseElement():
        IfCaseMapEntry result =
            new IfCaseMapEntry(
                prelude: [],
                expression: element.expression,
                internalPatternGuard: element.internalPatternGuard,
                then: convertToMapEntry(
                  element.then,
                  problemReporting,
                  compilerContext,
                  fileUri,
                  onConvertElement,
                ),
                otherwise: element.otherwise == null
                    ? null
                    : convertToMapEntry(
                        element.otherwise!,
                        problemReporting,
                        compilerContext,
                        fileUri,
                        onConvertElement,
                      ),
              )
              ..matchedValueType = element.matchedValueType
              ..fileOffset = element.fileOffset;
        onConvertElement(element, result);
        return result;

      case PatternForElement():
        PatternForMapEntry result = new PatternForMapEntry(
          internalPatternVariableDeclaration:
              element.internalPatternVariableDeclaration,
          intermediateVariables: element.intermediateVariables,
          internalVariables: element.internalVariables,
          condition: element.condition,
          updates: element.updates,
          body: convertToMapEntry(
            element.body,
            problemReporting,
            compilerContext,
            fileUri,
            onConvertElement,
          ),
        )..fileOffset = element.fileOffset;
        onConvertElement(element, result);
        return result;

      case ForElement():
        ForMapEntry result = new ForMapEntry(
          element.internalVariables,
          element.condition,
          element.updates,
          convertToMapEntry(
            element.body,
            problemReporting,
            compilerContext,
            fileUri,
            onConvertElement,
          ),
        )..fileOffset = element.fileOffset;
        onConvertElement(element, result);
        return result;

      case ForInElement():
        ForInMapEntry result = new ForInMapEntry(
          element.element,
          element.iterable,
          convertToMapEntry(
            element.body,
            problemReporting,
            compilerContext,
            fileUri,
            onConvertElement,
          ),
          fileOffset: element.fileOffset,
          forOffset: element.forOffset,
          isAsync: element.isAsync,
          encoding: element.encoding,
        );
        onConvertElement(element, result);
        return result;
    }
  } else {
    // Coverage-ignore-block(suite): Not run.
    return _convertToErroneousMapEntry(
      element,
      problemReporting,
      compilerContext,
      fileUri,
    );
  }
}

MapLiteralEntry _convertToErroneousMapEntry(
  Expression element,
  ProblemReporting problemReporting,
  CompilerContext compilerContext,
  Uri fileUri,
) {
  return intern.createMapLiteralEntry(
    problemReporting.buildProblem(
      compilerContext: compilerContext,
      message: diag.expectedAfterButGot.withArguments(expected: ':'),
      fileUri: fileUri,
      fileOffset: element.fileOffset,
      // TODO(danrubel): what is the length of the expression?
      length: noLength,
    ),
    intern.createNullLiteral(element.fileOffset),
    fileOffset: element.fileOffset,
  );
}
