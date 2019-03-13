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

  @override
  void visitLiteralExpression(js.LiteralExpression node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  @override
  void visitLiteralStatement(js.LiteralStatement node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  @override
  void visitAssignment(js.Assignment node) {
    sideEffects.setChangesStaticProperty();
    sideEffects.setChangesInstanceProperty();
    sideEffects.setChangesIndex();
    node.visitChildren(this);
  }

  @override
  void visitVariableInitialization(js.VariableInitialization node) {
    node.visitChildren(this);
  }

  @override
  void visitCall(js.Call node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  @override
  void visitBinary(js.Binary node) {
    node.visitChildren(this);
  }

  @override
  void visitThrow(js.Throw node) {
    // TODO(ngeoffray): Incorporate a mayThrow flag in the
    // [SideEffects] class.
    sideEffects.setAllSideEffects();
  }

  @override
  void visitNew(js.New node) {
    sideEffects.setAllSideEffects();
    sideEffects.setDependsOnSomething();
    node.visitChildren(this);
  }

  @override
  void visitPrefix(js.Prefix node) {
    if (node.op == 'delete') {
      sideEffects.setChangesStaticProperty();
      sideEffects.setChangesInstanceProperty();
      sideEffects.setChangesIndex();
    }
    node.visitChildren(this);
  }

  @override
  void visitVariableUse(js.VariableUse node) {
    sideEffects.setDependsOnStaticPropertyStore();
  }

  @override
  void visitPostfix(js.Postfix node) {
    node.visitChildren(this);
  }

  @override
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

  /// Returns the combined behavior of sequential execution of code having
  /// behavior [first] followed by code having behavior [second].
  static NativeThrowBehavior sequence(
      NativeThrowBehavior first, NativeThrowBehavior second) {
    return first.then(second);
  }

  /// Returns the combined behavior of a choice between two paths with behaviors
  /// [first] and [second].
  static NativeThrowBehavior choice(
      NativeThrowBehavior first, NativeThrowBehavior second) {
    return first.or(second);
  }

  NativeThrowBehavior visit(js.Node node) {
    return node.accept(this);
  }

  @override
  NativeThrowBehavior visitNode(js.Node node) {
    return NativeThrowBehavior.MAY;
  }

  @override
  NativeThrowBehavior visitLiteral(js.Literal node) {
    return NativeThrowBehavior.NEVER;
  }

  @override
  NativeThrowBehavior visitInterpolatedExpression(js.InterpolatedNode node) {
    return NativeThrowBehavior.NEVER;
  }

  @override
  NativeThrowBehavior visitInterpolatedSelector(js.InterpolatedNode node) {
    return NativeThrowBehavior.NEVER;
  }

  @override
  NativeThrowBehavior visitArrayInitializer(js.ArrayInitializer node) {
    return node.elements.map(visit).fold(NativeThrowBehavior.NEVER, sequence);
  }

  @override
  NativeThrowBehavior visitArrayHole(js.ArrayHole node) {
    return NativeThrowBehavior.NEVER;
  }

  @override
  NativeThrowBehavior visitObjectInitializer(js.ObjectInitializer node) {
    return node.properties.map(visit).fold(NativeThrowBehavior.NEVER, sequence);
  }

  @override
  NativeThrowBehavior visitProperty(js.Property node) {
    return sequence(visit(node.name), visit(node.value));
  }

  @override
  NativeThrowBehavior visitAssignment(js.Assignment node) {
    // TODO(sra): Can we make "#.p = #" be null(1)?
    return NativeThrowBehavior.MAY;
  }

  @override
  NativeThrowBehavior visitCall(js.Call node) {
    js.Expression target = node.target;
    if (target is js.PropertyAccess && _isFirstInterpolatedProperty(target)) {
      // #.f(...): Evaluate selector 'f', dereference, evaluate arguments, and
      // finally call target.
      NativeThrowBehavior result =
          sequence(visit(target.selector), NativeThrowBehavior.NULL_NSM);
      for (js.Expression argument in node.arguments) {
        result = sequence(result, visit(argument));
      }
      return sequence(result, NativeThrowBehavior.MAY); // Target may throw.
    }
    return NativeThrowBehavior.MAY;
  }

  @override
  NativeThrowBehavior visitNew(js.New node) {
    // TODO(sra): `new Array(x)` where `x` is a small number.
    return NativeThrowBehavior.MAY;
  }

  @override
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

  @override
  NativeThrowBehavior visitThrow(js.Throw node) {
    return sequence(visit(node.expression), NativeThrowBehavior.MAY);
  }

  @override
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

  @override
  NativeThrowBehavior visitVariableUse(js.VariableUse node) {
    // We could get a ReferenceError unless the variable is in scope. The AST
    // could distinguish in-scope and out-of scope references. For JS fragments,
    // the only use of VariableUse should be for global references. Certain
    // global names are almost certainly not reference errors, e.g 'Array'.
    switch (node.name) {
      case 'Array':
      case 'Math':
      case 'Object':
        return NativeThrowBehavior.NEVER;
      default:
        return NativeThrowBehavior.MAY;
    }
  }

  @override
  NativeThrowBehavior visitAccess(js.PropertyAccess node) {
    js.Node receiver = node.receiver;
    NativeThrowBehavior first = visit(receiver);
    NativeThrowBehavior second = visit(node.selector);

    if (_isFirstInterpolatedProperty(node)) {
      first = NativeThrowBehavior.NULL_NSM;
    } else {
      first = NativeThrowBehavior.MAY;
    }

    return sequence(first, second);
  }

  bool _isFirstInterpolatedProperty(js.PropertyAccess node) {
    js.Node receiver = node.receiver;
    if (receiver is js.InterpolatedExpression &&
        receiver.isPositional &&
        receiver.nameOrPosition == 0) {
      return true;
    }
    return false;
  }
}
