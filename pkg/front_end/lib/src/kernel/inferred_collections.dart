// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

import '../type_inference/element_inference.dart';
import 'internal_ast.dart';

/// Base class for [InternalElement] that have been inferred.
///
/// These are created during inference to hold the inferred types along with
/// the lowered [Expression]s contained within the corresponding
/// [InternalElement]s.
///
/// The lowering of [InternalElement]s can't be performed directly during
/// inference because the element type of the enclosing literal can't be
/// determined until all elements have been inferred. Therefore
/// [InferredElement] is created as an intermediate result of inference, which
/// is the later used to compute the lowering once the literal has been fully
/// inferred.
sealed class InferredElement({required super.fileOffset}) extends InternalNode;

/// Inferred [SpreadElement] in a list, set, or map literal.
class InferredSpreadElement({
  /// The spread expression.
  required final Expression expression,

  /// The internal node for [expression].
  required final InternalExpression expressionNode,

  /// The type of [expression].
  required final DartType expressionType,

  /// Whether the spread is null-aware, i.e. using `...?` instead of `...`.
  required final bool isNullAware,

  /// The type of the elements of the collection that [expression] evaluates to.
  required final ElementType elementType,

  /// [InternalNode] from which this inferred element was derived.
  ///
  /// This is used for passing internal compiler information to tests.
  required final InternalNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement {
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

/// Inferred [PatternForElement] in a list, set, or map literal.
class InferredPatternForElement({
  /// The pattern variable declaration occurring in the for element initializer.
  required final PatternVariableDeclaration patternVariableDeclaration,

  /// Intermediate variables needed for the lowering of the pattern for-element.
  required final List<VariableDeclaration> intermediateVariables,

  /// The variables used as the declared variable in the for-element
  /// initializer.
  ///
  /// These might be synthesized by the lowering.
  required final List<VariableDeclaration> variables,

  /// The condition expression of the for-element, if present.
  required final Expression? condition,

  /// The expressions occurring in the updates part of the for-element.
  required final List<Expression> updates,

  /// The body of the for-element.
  required final InferredElement body,

  /// [InternalNode] from which this inferred element was derived.
  ///
  /// This is used for passing internal compiler information to tests.
  required final InternalNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    patternVariableDeclaration.toTextInternal(printer);
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeVariableDeclaration(
        variables[index],
        includeModifiersAndType: index == 0,
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

/// Inferred [ForElement] in a list, set, or map literal.
class InferredForElement({
  /// The variables used as the declared variable in the for-element
  /// initializer.
  ///
  /// These might be synthesized by the lowering.
  required final List<VariableDeclaration> variables,

  /// The condition expression of the for-element, if present.
  required final Expression? condition,

  /// The expressions occurring in the updates part of the for-element.
  required final List<Expression> updates,

  /// The body of the for-element.
  required final InferredElement body,

  /// [InternalNode] from which this inferred element was derived.
  ///
  /// This is used for passing internal compiler information to tests.
  required final InternalNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeVariableDeclaration(
        variables[index],
        includeModifiersAndType: index == 0,
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

/// Inferred [IfCaseElement] in a list, set, or map literal.
class InferredIfCaseElement({
  /// The case expression of the if-case element.
  required final Expression expression,

  /// The pattern and optional guard of the if-case element.
  required final PatternGuard patternGuard,

  /// The then part of the if-case-element.
  required final InferredElement then,

  /// The else part of the if-case-element, if present.
  required final InferredElement? otherwise,

  /// The type of the expression against which this pattern is matched.
  required final DartType matchedValueType,

  /// [InternalNode] from which this inferred element was derived.
  ///
  /// This is used for passing internal compiler information to tests.
  required final InternalNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(expression);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }
}

/// Inferred [IfElement] in a list, set, or map literal.
class InferredIfElement({
  /// The condition expression of the if-element.
  required final Expression condition,

  /// The then part of the if-element.
  required final InferredElement then,

  /// The else part of the if-element, if present.
  required final InferredElement? otherwise,

  /// [InternalNode] from which this inferred element was derived.
  ///
  /// This is used for passing internal compiler information to tests.
  required final InternalNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(condition);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }
}

/// Inferred [ForInElement] in a list, set, or map literal.
class InferredForInElement({
  /// The encoding used for the declaration of the for-in element variable.
  required final ForInEncoding encoding,

  /// The variable used as the declared in the for-in element.
  required final DeclaredVariable variable,

  /// The iterable expression of the for-in element.
  required final Expression iterable,

  /// The body of the for-in element
  required final InferredElement body,

  /// Whether the for-in element is async, i.e. `await for` instead of `for`.
  required final bool isAsync,

  /// The scope holding the variables declared in the for-in element.
  required final Scope? scope,

  /// [InternalNode] from which this inferred element was derived.
  ///
  /// This is used for passing internal compiler information to tests.
  required final InternalNode nodeForTesting,
  required super.fileOffset,
}) extends InferredElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isAsync) {
      printer.write('async ');
    }
    printer.write('for (');
    printer.writeVariableInitialization(variable, includeInitializer: false);
    printer.write(' in ');
    printer.writeExpression(iterable);
    printer.write(') ');
    body.toTextInternal(printer);
  }
}

/// Inferred [NullAwareElement] in a list, set, or map literal.
class InferredNullAwareElement({
  /// The null-guarded expression of the element.
  required final Expression expression,
  required super.fileOffset,
}) extends InferredElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('?');
    printer.writeExpression(expression);
  }
}

/// Inferred [MapEntryElement] in a list, set, or map literal with no null-aware
/// access.
///
/// This inferred element can be added directly to a map literal and is
/// therefore separate from [InferredNullAwareMapEntryElement].
class InferredMapEntryElement({
  /// The key expression of the element.
  required final Expression key,

  /// The value expression of the element.
  required final Expression value,
  required super.fileOffset,
}) extends InferredElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(key);
    printer.write(': ');
    printer.writeExpression(value);
  }
}

/// Inferred [MapEntryElement] in a list, set, or map literal with either
/// null-aware key or value access.
///
/// This inferred element can't be added directly to a map literal and is
/// therefore separate from [InferredMapEntryElement].
class InferredNullAwareMapEntryElement({
  /// Whether the key expression is guarded by a null-check.
  required final bool isKeyNullAware,

  /// The key expression of the element.
  required final Expression key,

  /// Whether the value expression is guarded by a null-check.
  required final bool isValueNullAware,

  /// The value expression of the element.
  required final Expression value,
  required super.fileOffset,
}) extends InferredElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isKeyNullAware) {
      printer.write('?');
    }
    printer.writeExpression(key);
    printer.write(': ');
    if (isValueNullAware) {
      printer.write('?');
    }
    printer.writeExpression(value);
  }
}

/// Common superclass for inferred elements that can be added directly to a
/// list or set literal.
sealed class InferredExpressionElementBase({required super.fileOffset})
    extends InferredElement {
  /// The expression of the element.
  Expression get expression;
}

/// Inferred [ExpressionElement] in a list, set, or map literal.
class InferredExpressionElement({
  /// The expression of the element.
  @override required final Expression expression,
  required super.fileOffset,
}) extends InferredExpressionElementBase {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression);
  }
}

/// Element created for an inference error.
class InferredInvalidElement({
  /// The error for which this element was created.
  @override required final InvalidExpression expression,
  required super.fileOffset,
}) extends InferredExpressionElementBase {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression);
  }
}

final InferredElement dummyInferredElement = new InferredExpressionElement(
  expression: dummyExpression,
  fileOffset: TreeNode.noOffset,
);
