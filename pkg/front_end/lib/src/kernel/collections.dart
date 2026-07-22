// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'internal_ast.dart';

/// Base class for all elements in a list, set or map literal.
sealed class InternalElement({required super.fileOffset}) extends InternalNode {
  /// Dispatch method called during inference to infer the type of this element.
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  );
}

/// An expression occurring as an element.
class ExpressionElement({
  /// The expression of the element.
  required final InternalExpression expression,
  required super.fileOffset,
}) extends InternalElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
  }

  @override
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  ) {
    return visitor.visitExpressionElement(this, context);
  }
}

/// A spread element in a list, set, or map literal.
class SpreadElement({
  /// The spread expression.
  required final InternalExpression expression,

  /// Whether the spread is null-aware, i.e. using `...?` instead of `...`.
  required final bool isNullAware,
  required super.fileOffset,
}) extends InternalElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    if (isNullAware) {
      printer.write('?');
    }
    expression.toTextInternal(printer);
  }

  @override
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  ) {
    return visitor.visitSpreadElement(this, context);
  }
}

/// A null-aware element in a list, set, or map literal.
class NullAwareElement({
  /// The null-guarded expression of the element.
  required final InternalExpression expression,
  required super.fileOffset,
}) extends InternalElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('?');
    expression.toTextInternal(printer);
  }

  @override
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  ) {
    return visitor.visitNullAwareElement(this, context);
  }
}

/// An 'if' element in a list, set, or map literal.
class IfElement({
  /// The condition expression of the if-element.
  required final InternalExpression condition,

  /// The then part of the if-element.
  required final InternalElement then,

  /// The else part of the if-element, if present.
  required final InternalElement? otherwise,
  required super.fileOffset,
}) extends InternalElement {
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

  @override
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  ) {
    return visitor.visitIfElement(this, context);
  }
}

/// Base class for [ForElement] and [PatternForElement].
sealed class ForElementBase({
  /// The variables declared in the for-element initializer.
  required final List<InternalVariableDeclaration> variables,

  /// The condition expression of the for-element, if present.
  required final InternalExpression? condition,

  /// The expressions occurring in the updates part of the for-element.
  required final List<InternalExpression> updates,

  /// The body of the for-element.
  required final InternalElement body,
  required super.fileOffset,
}) extends InternalElement;

/// A 'for' element in a list, set, or map literal.
class ForElement({
  required super.variables,
  required super.condition,
  required super.updates,
  required super.body,
  required super.fileOffset,
}) extends ForElementBase {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      variables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: variables[index].initializer,
      );
    }
    printer.write('; ');
    if (condition != null) {
      condition!.toTextInternal(printer);
    }
    printer.write('; ');
    updates.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }

  @override
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  ) {
    return visitor.visitForElement(this, context);
  }
}

/// A 'for-in' element in a list, set, or map literal.
class ForInElement({
  /// The element declaration in the for-in element.
  required final InternalForInElement element,

  /// The iterable expression of the for-in element.
  required final InternalExpression iterable,

  /// The body of the for-in element
  required final InternalElement body,

  /// Whether the for-in element is async, i.e. `await for` instead of `for`.
  required final bool isAsync,
  required super.fileOffset,

  /// File offset for the `for` keyword.
  required final int forOffset,
}) extends InternalElement {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isAsync) {
      printer.write('async ');
    }
    printer.write('for (');
    element.toTextInternal(printer);
    printer.write(' in ');
    iterable.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }

  @override
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  ) {
    return visitor.visitForInElement(this, context);
  }
}

/// An if-case element in a list, set, or map literal.
class IfCaseElement({
  /// The case expression of the if-case element.
  required final InternalExpression expression,

  /// The pattern and optional guard of the if-case element.
  required final InternalPatternGuard patternGuard,

  /// The then part of the if-case-element.
  required final InternalElement then,

  /// The else part of the if-case-element, if present.
  required final InternalElement? otherwise,

  required super.fileOffset,
}) extends InternalElement {
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
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  ) {
    return visitor.visitIfCaseElement(this, context);
  }
}

/// A for loop with a pattern variable declaration in a list, set, or map
/// literal.
class PatternForElement({
  /// The pattern variable declaration occurring in the for element initializer.
  required final InternalPatternVariableDeclaration patternVariableDeclaration,

  /// Intermediate variables needed for the lowering of the pattern for-element.
  required final List<InternalVariableDeclaration> intermediateVariables,

  required super.variables,
  required super.condition,
  required super.updates,
  required super.body,
  required super.fileOffset,
}) extends ForElementBase {
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    patternVariableDeclaration.toTextInternal(printer);
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      variables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: variables[index].initializer,
      );
    }
    printer.write('; ');
    if (condition != null) {
      condition!.toTextInternal(printer);
    }
    printer.write('; ');
    updates.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }

  @override
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  ) {
    return visitor.visitPatternForElement(this, context);
  }
}

/// A map entry in a list, set, or map literal.
class MapEntryElement({
  /// `true` if the key expression is null-aware, that is, marked with `?`.
  required final bool isKeyNullAware,

  /// The key expression of the map entry.
  required final InternalExpression key,

  /// `true` if the value expression is null-aware, that is, marked with `?`.
  required final bool isValueNullAware,

  /// The value expression of the map entry.
  required final InternalExpression value,
  required super.fileOffset,
}) extends InternalElement {
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

  @override
  ElementInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    ElementInferenceContext context,
  ) {
    return visitor.visitMapEntryElement(this, context);
  }
}
