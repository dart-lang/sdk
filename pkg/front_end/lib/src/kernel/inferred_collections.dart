// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

import 'internal_ast.dart';

sealed class InferredMapLiteralEntry({@override required final int fileOffset})
    extends TreeNode
    with InternalTreeNode {
  @override
  R accept<R>(TreeVisitor<R> v) {
    throw new UnsupportedError("$runtimeType.accept");
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    throw new UnsupportedError("$runtimeType.accept1");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO: implement toTextInternal
  }

  @override
  String toString() {
    return '$runtimeType(${toStringInternal()})';
  }
}

class InferredRegularMapLiteralEntry(
  final Expression key,
  final Expression value, {
  required super.fileOffset,
}) extends InferredMapLiteralEntry;

class InferredIfCaseMapEntry({
  required final Expression expression,
  required final PatternGuard patternGuard,
  required var InferredMapLiteralEntry then,
  required var InferredMapLiteralEntry? otherwise,

  /// The type of the expression against which this pattern is matched.
  required final DartType matchedValueType,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredMapLiteralEntry;

class InferredForMapEntry({
  required final List<VariableDeclaration> variables,
  required final Expression? condition,
  required final List<Expression> updates,
  required var InferredMapLiteralEntry body,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredMapLiteralEntry;

class InferredForInMapEntry({
  required final DeclaredVariable variable,
  required final ForInEncoding encoding,
  required final Expression iterable,
  required var InferredMapLiteralEntry body,
  required final bool isAsync,
  required final Scope? scope,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredMapLiteralEntry;

class InferredPatternForMapEntry({
  required final PatternVariableDeclaration patternVariableDeclaration,
  required final List<VariableDeclaration> intermediateVariables,
  required final List<VariableDeclaration> variables,
  required final Expression? condition,
  required final List<Expression> updates,
  required var InferredMapLiteralEntry body,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredMapLiteralEntry;

class InferredNullAwareMapEntry({
  required final bool isKeyNullAware,
  required final Expression key,
  required final bool isValueNullAware,
  required final Expression value,
  required super.fileOffset,
}) extends InferredMapLiteralEntry;

class InferredIfMapEntry({
  required final Expression condition,
  required var InferredMapLiteralEntry then,
  required var InferredMapLiteralEntry? otherwise,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredMapLiteralEntry;

class InferredSpreadMapEntry({
  required var Expression expression,

  /// The type of [expression].
  required final DartType expressionType,
  required final bool isNullAware,

  /// The type of the map entries of the map that [expression] evaluates to.
  required final DartType? entryType,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredMapLiteralEntry;

final InferredMapLiteralEntry dummyMapLiteralEntryResult =
    new InferredRegularMapLiteralEntry(
      dummyExpression,
      dummyExpression,
      fileOffset: TreeNode.noOffset,
    );

sealed class InferredElement({@override required final int fileOffset})
    extends TreeNode
    with InternalTreeNode {
  @override
  R accept<R>(TreeVisitor<R> v) {
    throw new UnsupportedError("$runtimeType.accept");
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    throw new UnsupportedError("$runtimeType.accept1");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO: implement toTextInternal
  }

  @override
  String toString() {
    return '$runtimeType(${toStringInternal()})';
  }
}

class InferredSpreadElement({
  required var Expression expression,

  /// The type of [expression].
  required final DartType expressionType,
  required final bool isNullAware,

  /// The type of the elements of the collection that [expression] evaluates to.
  required final DartType? elementType,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement;

class InferredPatternForElement({
  required final PatternVariableDeclaration patternVariableDeclaration,
  required final List<VariableDeclaration> intermediateVariables,
  required final List<VariableDeclaration> variables,
  required final Expression? condition,
  required final List<Expression> updates,
  required final InferredElement body,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement;

class InferredForElement({
  required final List<VariableDeclaration> variables,
  required final Expression? condition,
  required final List<Expression> updates,
  required final InferredElement body,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement;

class InferredIfCaseElement({
  required final Expression expression,
  required final PatternGuard patternGuard,
  required final InferredElement then,
  required final InferredElement? otherwise,

  /// The type of the expression against which this pattern is matched.
  required final DartType? matchedValueType,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement;

class InferredIfElement({
  required final Expression condition,
  required final InferredElement then,
  required final InferredElement? otherwise,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement;

class InferredForInElement({
  required final ForInEncoding encoding,
  required final DeclaredVariable variable,
  required final Expression iterable,
  required final InferredElement body,
  required final bool isAsync,
  required final Scope? scope,
  required final TreeNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement;

class InferredNullAwareElement({
  required final Expression expression,
  required super.fileOffset,
}) extends InferredElement;

class InferredExpressionElement({
  required final Expression expression,
  required super.fileOffset,
}) extends InferredElement;

final InferredElement dummyInferredElement = new InferredExpressionElement(
  expression: dummyExpression,
  fileOffset: TreeNode.noOffset,
);
