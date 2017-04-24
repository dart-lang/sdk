// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../js/js.dart' as js;
import '../universe/side_effects.dart' show SideEffects;
import 'behavior.dart';

class HasCapturedPlaceholders extends js.BaseVisitor {
  HasCapturedPlaceholders._();

  static bool check(js.Node node) {
    HasCapturedPlaceholders visitor = new HasCapturedPlaceholders._();
    node.accept(visitor);
    return visitor.found;
  }

  int enclosingFunctions = 0;
  bool found = false;

  @override
  visitFun(js.Fun node) {
    ++enclosingFunctions;
    node.visitChildren(this);
    --enclosingFunctions;
  }

  @override
  visitInterpolatedNode(js.InterpolatedNode node) {
    if (enclosingFunctions > 0) {
      found = true;
    }
  }
}

class SideEffectsVisitor extends js.BaseVisitor {
  final SideEffects sideEffects;
  SideEffectsVisitor(this.sideEffects);

  void visit(js.Node node) {
    node.accept(this);
  }

  void visitLiteralExpression(js.LiteralExpression node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  void visitLiteralStatement(js.LiteralStatement node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  void visitAssignment(js.Assignment node) {
    sideEffects.setChangesStaticProperty();
    sideEffects.setChangesInstanceProperty();
    sideEffects.setChangesIndex();
    node.visitChildren(this);
  }

  void visitVariableInitialization(js.VariableInitialization node) {
    node.visitChildren(this);
  }

  void visitCall(js.Call node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  void visitBinary(js.Binary node) {
    node.visitChildren(this);
  }

  void visitThrow(js.Throw node) {
    // TODO(ngeoffray): Incorporate a mayThrow flag in the
    // [SideEffects] class.
    sideEffects.setAllSideEffects();
  }

  void visitNew(js.New node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  void visitPrefix(js.Prefix node) {
    if (node.op == 'delete') {
      sideEffects.setChangesStaticProperty();
      sideEffects.setChangesInstanceProperty();
      sideEffects.setChangesIndex();
    }
    node.visitChildren(this);
  }

  void visitVariableUse(js.VariableUse node) {
    sideEffects.setDependsOnStaticPropertyStore();
  }

  void visitPostfix(js.Postfix node) {
    node.visitChildren(this);
  }

  void visitAccess(js.PropertyAccess node) {
    sideEffects.setDependsOnIndexStore();
    sideEffects.setDependsOnInstancePropertyStore();
    sideEffects.setDependsOnStaticPropertyStore();
    node.visitChildren(this);
  }
}

/// ThrowBehaviorVisitor generates a NativeThrowBehavior describing the
/// exception behavior of a JavaScript expression.
///
/// The result is semi-conservative, giving reasonable results for many simple
/// JS fragments. The non-conservative part is the assumption that binary
/// operators are used on 'good' operands that do not force arbitrary code to be
/// executed via conversions (valueOf() and toString() methods).
///
/// In many cases a JS fragment has more precise behavior. In these cases the
/// behavior should be described as a property of the JS fragment. For example,
/// Object.keys(#) has a TypeError on null / undefined, which can only be known
/// in the calling context.
///
class ThrowBehaviorVisitor extends js.BaseVisitor<NativeThrowBehavior> {
  ThrowBehaviorVisitor();

  NativeThrowBehavior analyze(js.Node node) {
    return visit(node);
  }

  // TODO(sra): Add [sequence] functionality to NativeThrowBehavior.
  /// Returns the combined behavior of sequential execution of code having
  /// behavior [first] followed by code having behavior [second].
  static NativeThrowBehavior sequence(
      NativeThrowBehavior first, NativeThrowBehavior second) {
    if (first == NativeThrowBehavior.MUST) return first;
    if (second == NativeThrowBehavior.MUST) return second;
    if (second == NativeThrowBehavior.NEVER) return first;
    if (first == NativeThrowBehavior.NEVER) return second;
    // Both are one of MAY or MAY_THROW_ONLY_ON_FIRST_ARGUMENT_ACCESS.
    return NativeThrowBehavior.MAY;
  }

  // TODO(sra): Add [choice] functionality to NativeThrowBehavior.
  /// Returns the combined behavior of a choice between two paths with behaviors
  /// [first] and [second].
  static NativeThrowBehavior choice(
      NativeThrowBehavior first, NativeThrowBehavior second) {
    if (first == second) return first; // Both paths have same behaviour.
    return NativeThrowBehavior.MAY;
  }

  NativeThrowBehavior visit(js.Node node) {
    return node.accept(this);
  }

  NativeThrowBehavior visitNode(js.Node node) {
    return NativeThrowBehavior.MAY;
  }

  NativeThrowBehavior visitLiteral(js.Literal node) {
    return NativeThrowBehavior.NEVER;
  }

  NativeThrowBehavior visitInterpolatedExpression(js.InterpolatedNode node) {
    return NativeThrowBehavior.NEVER;
  }

  NativeThrowBehavior visitInterpolatedSelector(js.InterpolatedNode node) {
    return NativeThrowBehavior.NEVER;
  }

  NativeThrowBehavior visitObjectInitializer(js.ObjectInitializer node) {
    NativeThrowBehavior result = NativeThrowBehavior.NEVER;
    for (js.Property property in node.properties) {
      result = sequence(result, visit(property));
    }
    return result;
  }

  NativeThrowBehavior visitProperty(js.Property node) {
    return sequence(visit(node.name), visit(node.value));
  }

  NativeThrowBehavior visitAssignment(js.Assignment node) {
    // TODO(sra): Can we make "#.p = #" be null(1)?
    return NativeThrowBehavior.MAY;
  }

  NativeThrowBehavior visitCall(js.Call node) {
    return NativeThrowBehavior.MAY;
  }

  NativeThrowBehavior visitNew(js.New node) {
    // TODO(sra): `new Array(x)` where `x` is a small number.
    return NativeThrowBehavior.MAY;
  }

  NativeThrowBehavior visitBinary(js.Binary node) {
    NativeThrowBehavior left = visit(node.left);
    NativeThrowBehavior right = visit(node.right);
    switch (node.op) {
      // We make the non-conservative assumption that these operations are not
      // used in ways that force calling arbitrary code via valueOf or
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
        return sequence(left, right);

      case ',':
        return sequence(left, right);

      case "&&":
      case "||":
        return choice(left, sequence(left, right));

      case "instanceof":
      case "in":
      default:
        return NativeThrowBehavior.MAY;
    }
  }

  NativeThrowBehavior visitThrow(js.Throw node) {
    return NativeThrowBehavior.MUST;
  }

  NativeThrowBehavior visitPrefix(js.Prefix node) {
    if (node.op == 'typeof' && node.argument is js.VariableUse)
      return NativeThrowBehavior.NEVER;
    NativeThrowBehavior result = visit(node.argument);
    switch (node.op) {
      case '+':
      case '-':
      case '!':
      case '~':
      case 'void':
      case 'typeof':
        return result;
      default:
        return NativeThrowBehavior.MAY;
    }
  }

  NativeThrowBehavior visitVariableUse(js.VariableUse node) {
    // We could get a ReferenceError unless the variable is in scope. The AST
    // could distinguish in-scope and out-of scope references. For JS fragments,
    // the only use of VariableUse should be for global references. Certain
    // global names are almost certainly not reference errors, e.g 'Array'.
    switch (node.name) {
      case 'Array':
      case 'Object':
        return NativeThrowBehavior.NEVER;
      default:
        return NativeThrowBehavior.MAY;
    }
  }

  NativeThrowBehavior visitAccess(js.PropertyAccess node) {
    // TODO(sra): We need a representation where the nsm guard behaviour is
    // maintained when combined with other throwing behaviour.
    js.Node receiver = node.receiver;
    NativeThrowBehavior first = visit(receiver);
    NativeThrowBehavior second = visit(node.selector);

    if (receiver is js.InterpolatedExpression &&
        receiver.isPositional &&
        receiver.nameOrPosition == 0) {
      first = NativeThrowBehavior.MAY_THROW_ONLY_ON_FIRST_ARGUMENT_ACCESS;
    } else {
      first = NativeThrowBehavior.MAY;
    }

    return sequence(first, second);
  }
}
