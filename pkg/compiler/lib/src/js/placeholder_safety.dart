// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js.safety;

import "js.dart" as js;

typedef bool PositionPredicate(int position);

/// PlaceholderSafetyAnalysis determines which placeholders in a JavaScript
/// template may be replaced with an arbitrary expression. Placeholders may be
/// replaced with an arbitrary expression providied the template ensures the
/// placeholders are evaluated in the same left-to-right order with no
/// additional effects interleaved.
///
/// The result is semi-conservative, giving reasonable results for many simple
/// JS fragments. The non-conservative part is the assumption that arithmetic
/// operators are used on 'good' operands that do not force arbitrary code to be
/// executed via conversions (valueOf() and toString() methods).
class PlaceholderSafetyAnalysis extends js.BaseVisitor<int> {
  final PositionPredicate isNullableInput;
  int nextPosition = 0;
  int maxSafePosition = -1;
  bool safe = true;

  // We do a crude abstract interpretation to find operations that might throw
  // exceptions. The possible values of expressions are represented by
  // integers. Small non-negative integers 0, 1, 2, ... represent the values of
  // the placeholders. Other values are:
  static const int NONNULL_VALUE = -1; // Unknown but not null.
  static const int UNKNOWN_VALUE = -2; // Unknown and might be null.

  PlaceholderSafetyAnalysis._(this.isNullableInput);

  /// Returns the number of placeholders that can be substituted into the
  /// template AST [node] without changing the order of observable effects.
  /// [isNullableInput] is a function that takes the 0-based index of a
  /// placeholder and returns `true` if expression at run time may be null, and
  /// `false` if the value is never null.
  static int analyze(js.Node node, PositionPredicate isNullableInput) {
    PlaceholderSafetyAnalysis analysis =
        new PlaceholderSafetyAnalysis._(isNullableInput);
    analysis.visit(node);
    return analysis.maxSafePosition + 1;
  }

  bool canBeNull(int value) {
    if (value == NONNULL_VALUE) return false;
    if (value == UNKNOWN_VALUE) return true;
    return isNullableInput(value);
  }

  int unsafe(int value) {
    safe = false;
    return value;
  }

  int visit(js.Node node) {
    return node.accept(this);
  }

  int visitNode(js.Node node) {
    safe = false;
    super.visitNode(node);
    return UNKNOWN_VALUE;
  }

  int visitLiteralNull(js.LiteralNull node) {
    return UNKNOWN_VALUE;
  }

  int visitLiteral(js.Literal node) {
    return NONNULL_VALUE;
  }

  int handleInterpolatedNode(js.InterpolatedNode node) {
    assert(node.isPositional);
    int position = nextPosition++;
    if (safe) maxSafePosition = position;
    return position;
  }

  int visitInterpolatedExpression(js.InterpolatedExpression node) {
    return handleInterpolatedNode(node);
  }

  int visitInterpolatedLiteral(js.InterpolatedLiteral node) {
    return handleInterpolatedNode(node);
  }

  int visitInterpolatedSelector(js.InterpolatedSelector node) {
    return handleInterpolatedNode(node);
  }

  int visitInterpolatedStatement(js.InterpolatedStatement node) {
    return handleInterpolatedNode(node);
  }

  int visitInterpolatedDeclaration(js.InterpolatedDeclaration node) {
    return handleInterpolatedNode(node);
  }

  int visitObjectInitializer(js.ObjectInitializer node) {
    for (js.Property property in node.properties) {
      visit(property);
    }
    return NONNULL_VALUE;
  }

  int visitProperty(js.Property node) {
    visit(node.name);
    visit(node.value);
    return UNKNOWN_VALUE;
  }

  int visitArrayInitializer(js.ArrayInitializer node) {
    node.elements.forEach(visit);
    return NONNULL_VALUE;
  }

  int visitArrayHole(js.ArrayHole node) {
    return UNKNOWN_VALUE;
  }

  int visitAccess(js.PropertyAccess node) {
    int first = visit(node.receiver);
    visit(node.selector);
    // TODO(sra): If the JS is annotated as never throwing, we can avoid this.
    if (canBeNull(first)) safe = false;
    return UNKNOWN_VALUE;
  }

  int visitAssignment(js.Assignment node) {
    js.Expression left = node.leftHandSide;
    js.Expression right = node.value;

    int leftToRight() {
      visit(left);
      visit(right);
      return UNKNOWN_VALUE;
    }

    if (left is js.InterpolatedNode) {
      // A bare interpolated expression should not be the LHS of an assignment.
      safe = false;
      return leftToRight();
    }

    // Assignment operators dereference the LHS before evaluating the RHS.
    if (node.op != null) return leftToRight();

    // Assignment (1) evaluates the LHS as a Reference `lval`, (2) evaluates the
    // RHS as a value, (3) dereferences the `lval` in PutValue.
    if (left is js.VariableReference) {
      int value = visit(right);
      // Assignment could change an observed global or cause a ReferenceError.
      safe = false;
      return value;
    }
    if (left is js.PropertyAccess) {
      // "a.b.x = c.y" gives a TypeError for null values in this order: `a`,
      // `c`, `a.b`.
      int receiver = visit(left.receiver);
      visit(left.selector);
      int value = visit(right);
      if (canBeNull(receiver)) safe = false;
      return value;
    }
    // Be conservative with unrecognized LHS expressions.
    safe = false;
    return leftToRight();
  }

  int visitCall(js.Call node) {
    // TODO(sra): Recognize JavaScript built-ins like
    // 'Object.prototype.hasOwnProperty.call'.
    visit(node.target);
    node.arguments.forEach(visit);
    return unsafe(UNKNOWN_VALUE);
  }

  int visitNew(js.New node) {
    visit(node.target);
    node.arguments.forEach(visit);
    return unsafe(NONNULL_VALUE);
  }

  int visitBinary(js.Binary node) {
    switch (node.op) {
      // We make the non-conservative assumption that these operations are not
      // used in ways that force calling arbitrary code via valueOf() or
      // toString().
      case "*":
      case "/":
      case "%":
      case "+":
      case "-":
      case "<<":
      case ">>":
      case ">>>":
      case "<":
      case ">":
      case "<=":
      case ">=":
      case "==":
      case "===":
      case "!=":
      case "!==":
      case "&":
      case "^":
      case "|":
        visit(node.left);
        visit(node.right);
        return NONNULL_VALUE; // Number, String, Boolean.

      case ',':
        visit(node.left);
        int right = visit(node.right);
        return right;

      case "&&":
      case "||":
        visit(node.left);
        // TODO(sra): Might be safe, e.g.  "x || 0".
        safe = false;
        visit(node.right);
        return UNKNOWN_VALUE;

      case "instanceof":
      case "in":
        visit(node.left);
        visit(node.right);
        return UNKNOWN_VALUE;

      default:
        return unsafe(UNKNOWN_VALUE);
    }
  }

  int visitConditional(js.Conditional node) {
    visit(node.condition);
    // TODO(sra): Might be safe, e.g.  "# ? 1 : 2".
    safe = false;
    visit(node.then);
    visit(node.otherwise);
    return UNKNOWN_VALUE;
  }

  int visitThrow(js.Throw node) {
    visit(node.expression);
    return unsafe(UNKNOWN_VALUE);
  }

  int visitPrefix(js.Prefix node) {
    if (node.op == 'typeof') {
      // "typeof a" first evaluates to a Reference. If the Reference is to a
      // variable that is not present, "undefined" is returned without
      // dereferencing.
      if (node.argument is js.VariableUse) return NONNULL_VALUE; // A string.
    }

    visit(node.argument);

    switch (node.op) {
      case '+':
      case '-':
      case '!':
      case '~':
        // Non-conservative assumption that these operators are used on values
        // that do not call arbitrary code via valueOf() or toString().
        return NONNULL_VALUE;

      case 'typeof':
        return NONNULL_VALUE; // Always a string.

      case 'void':
        return UNKNOWN_VALUE;

      case '--':
      case '++':
        return NONNULL_VALUE; // Always a number.

      default:
        safe = false;
        return UNKNOWN_VALUE;
    }
  }

  int visitPostfix(js.Postfix node) {
    assert(node.op == '--' || node.op == '++');
    visit(node.argument);
    return NONNULL_VALUE; // Always a number, even for "(a=null, a++)".
  }

  int visitVariableUse(js.VariableUse node) {
    // We could get a ReferenceError unless the variable is in scope.  For JS
    // fragments, the only use of VariableUse outside a `function(){...}` should
    // be for global references. Certain global names are almost certainly not
    // reference errors, e.g 'Array'.
    switch (node.name) {
      case 'Array':
      case 'Date':
      case 'Function':
      case 'Math':
      case 'Number':
      case 'Object':
      case 'RegExp':
      case 'String':
      case 'self':
      case 'window':
        return NONNULL_VALUE;
      default:
        return unsafe(UNKNOWN_VALUE);
    }
  }

  int visitFun(js.Fun node) {
    bool oldSafe = safe;
    int oldNextPosition = nextPosition;
    visit(node.body);
    // Creating a function has no effect on order unless there are embedded
    // placeholders.
    safe = (nextPosition == oldNextPosition) && oldSafe;
    return NONNULL_VALUE;
  }
}
