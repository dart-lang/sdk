// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.send_structure;

import 'access_semantics.dart';
import 'operators.dart';
import 'semantic_visitor.dart';
import '../dart_types.dart';
import '../constants/expressions.dart';
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../universe/universe.dart';
import '../util/util.dart';

/// Interface for the structure of the semantics of a [Send] or [NewExpression]
/// node.
abstract class SemanticSendStructure<R, A> {
  /// Calls the matching visit method on [visitor] with [node] and [arg].
  R dispatch(SemanticSendVisitor<R, A> visitor, Node node, A arg);
}

/// Interface for the structure of the semantics of a [Send] node.
///
/// Subclasses handle each of the [Send] variations; `assert(e)`, `a && b`,
/// `a.b`, `a.b(c)`, etc.
abstract class SendStructure<R, A> extends SemanticSendStructure<R, A> {
  /// Calls the matching visit method on [visitor] with [send] and [arg].
  R dispatch(SemanticSendVisitor<R, A> visitor, Send send, A arg);
}

/// The structure for a [Send] of the form `assert(e)`.
class AssertStructure<R, A> implements SendStructure<R, A> {
  const AssertStructure();

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.visitAssert(
        node,
        node.arguments.single,
        arg);
  }

  String toString() => 'assert';
}

/// The structure for a [Send] of the form an `assert` with less or more than
/// one argument.
class InvalidAssertStructure<R, A> implements SendStructure<R, A> {
  const InvalidAssertStructure();

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.errorInvalidAssert(
        node,
        node.argumentsNode,
        arg);
  }

  String toString() => 'invalid assert';
}

/// The structure for a [Send] of the form `a ?? b`.
class IfNullStructure<R, A> implements SendStructure<R, A> {
  const IfNullStructure();

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.visitIfNull(
        node,
        node.receiver,
        node.arguments.single,
        arg);
  }

  String toString() => '??';
}

/// The structure for a [Send] of the form `a && b`.
class LogicalAndStructure<R, A> implements SendStructure<R, A> {
  const LogicalAndStructure();

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.visitLogicalAnd(
        node,
        node.receiver,
        node.arguments.single,
        arg);
  }

  String toString() => '&&';
}

/// The structure for a [Send] of the form `a || b`.
class LogicalOrStructure<R, A> implements SendStructure<R, A> {
  const LogicalOrStructure();

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.visitLogicalOr(
        node,
        node.receiver,
        node.arguments.single,
        arg);
  }

  String toString() => '||';
}

/// The structure for a [Send] of the form `a is T`.
class IsStructure<R, A> implements SendStructure<R, A> {
  /// The type that the expression is tested against.
  final DartType type;

  IsStructure(this.type);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.visitIs(
        node,
        node.receiver,
        type,
        arg);
  }

  String toString() => 'is $type';
}

/// The structure for a [Send] of the form `a is! T`.
class IsNotStructure<R, A> implements SendStructure<R, A> {
  /// The type that the expression is tested against.
  final DartType type;

  IsNotStructure(this.type);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.visitIsNot(
        node,
        node.receiver,
        type,
        arg);
  }

  String toString() => 'is! $type';
}

/// The structure for a [Send] of the form `a as T`.
class AsStructure<R, A> implements SendStructure<R, A> {
  /// The type that the expression is cast to.
  final DartType type;

  AsStructure(this.type);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.visitAs(
        node,
        node.receiver,
        type,
        arg);
  }

  String toString() => 'as $type';
}

/// The structure for a [Send] that is an invocation.
class InvokeStructure<R, A> implements SendStructure<R, A> {
  /// The target of the invocation.
  final AccessSemantics semantics;

  /// The [Selector] for the invocation.
  // TODO(johnniwinther): Store this only for dynamic invocations.
  final Selector selector;

  /// The [CallStructure] of the invocation.
  // TODO(johnniwinther): Store this directly for static invocations.
  CallStructure get callStructure => selector.callStructure;

  InvokeStructure(this.semantics, this.selector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
        return visitor.visitIfNotNullDynamicPropertyInvoke(
            node,
            node.receiver,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitDynamicPropertyInvoke(
            node,
            node.receiver,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.visitLocalFunctionInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            // TODO(johnniwinther): Store the call selector instead of the
            // selector using the name of the function.
            callStructure,
            arg);
      case AccessKind.LOCAL_VARIABLE:
      case AccessKind.FINAL_LOCAL_VARIABLE:
        return visitor.visitLocalVariableInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            // TODO(johnniwinther): Store the call selector instead of the
            // selector using the name of the variable.
            callStructure,
            arg);
      case AccessKind.PARAMETER:
      case AccessKind.FINAL_PARAMETER:
        return visitor.visitParameterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            // TODO(johnniwinther): Store the call selector instead of the
            // selector using the name of the parameter.
            callStructure,
            arg);
      case AccessKind.STATIC_FIELD:
      case AccessKind.FINAL_STATIC_FIELD:
        return visitor.visitStaticFieldInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.STATIC_METHOD:
        return visitor.visitStaticFunctionInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.STATIC_GETTER:
        return visitor.visitStaticGetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.STATIC_SETTER:
        return visitor.visitStaticSetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.TOPLEVEL_FIELD:
      case AccessKind.FINAL_TOPLEVEL_FIELD:
        return visitor.visitTopLevelFieldInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.TOPLEVEL_METHOD:
        return visitor.visitTopLevelFunctionInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.TOPLEVEL_GETTER:
        return visitor.visitTopLevelGetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.TOPLEVEL_SETTER:
        return visitor.visitTopLevelSetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.visitClassTypeLiteralInvoke(
            node,
            semantics.constant,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.visitTypedefTypeLiteralInvoke(
            node,
            semantics.constant,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.visitDynamicTypeLiteralInvoke(
            node,
            semantics.constant,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.visitTypeVariableTypeLiteralInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.EXPRESSION:
        return visitor.visitExpressionInvoke(
            node,
            node.selector,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.THIS:
        return visitor.visitThisInvoke(
            node,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.THIS_PROPERTY:
        return visitor.visitThisPropertyInvoke(
            node,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.SUPER_FIELD:
      case AccessKind.SUPER_FINAL_FIELD:
        return visitor.visitSuperFieldInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperMethodInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.SUPER_GETTER:
        return visitor.visitSuperGetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.SUPER_SETTER:
        return visitor.visitSuperSetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.CONSTANT:
        return visitor.visitConstantInvoke(
            node,
            semantics.constant,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.UNRESOLVED:
        return visitor.visitUnresolvedInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.COMPOUND:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(node, "Invalid invoke: ${semantics}");
  }

  String toString() => 'invoke($selector, $semantics)';
}

/// The structure for a [Send] that is an incompatible invocation, i.e. an
/// invocation of a known target where the call structure does not match.
class IncompatibleInvokeStructure<R, A> implements SendStructure<R, A> {
  /// The target of the invocation.
  final AccessSemantics semantics;

  /// The [Selector] for the invocation.
  // TODO(johnniwinther): Store this only for dynamic invocations.
  final Selector selector;

  /// The [CallStructure] of the invocation.
  // TODO(johnniwinther): Store this directly for static invocations.
  CallStructure get callStructure => selector.callStructure;

  IncompatibleInvokeStructure(this.semantics, this.selector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.STATIC_METHOD:
        return visitor.visitStaticFunctionIncompatibleInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperMethodIncompatibleInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.TOPLEVEL_METHOD:
        return visitor.visitTopLevelFunctionIncompatibleInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.visitLocalFunctionIncompatibleInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            callStructure,
            arg);
     default:
        // TODO(johnniwinther): Support more variants of this invoke structure.
        break;
    }
    throw new SpannableAssertionFailure(
        node, "Invalid incompatible invoke: ${semantics}");
  }

  String toString() => 'incompatible-invoke($selector, $semantics)';
}

/// The structure for a [Send] that is a read access.
class GetStructure<R, A> implements SendStructure<R, A> {
  /// The target of the read access.
  final AccessSemantics semantics;

  /// The [Selector] for the getter invocation.
  final Selector selector;

  GetStructure(this.semantics, this.selector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
        return visitor.visitIfNotNullDynamicPropertyGet(
            node,
            node.receiver,
            selector,
            arg);
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitDynamicPropertyGet(
            node,
            node.receiver,
            selector,
            arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.visitLocalFunctionGet(
            node,
            semantics.element,
            arg);
      case AccessKind.LOCAL_VARIABLE:
      case AccessKind.FINAL_LOCAL_VARIABLE:
        return visitor.visitLocalVariableGet(
            node,
            semantics.element,
            arg);
      case AccessKind.PARAMETER:
      case AccessKind.FINAL_PARAMETER:
        return visitor.visitParameterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.STATIC_FIELD:
      case AccessKind.FINAL_STATIC_FIELD:
        return visitor.visitStaticFieldGet(
            node,
            semantics.element,
            arg);
      case AccessKind.STATIC_METHOD:
        return visitor.visitStaticFunctionGet(
            node,
            semantics.element,
            arg);
      case AccessKind.STATIC_GETTER:
        return visitor.visitStaticGetterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.STATIC_SETTER:
        return visitor.visitStaticSetterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.TOPLEVEL_FIELD:
      case AccessKind.FINAL_TOPLEVEL_FIELD:
        return visitor.visitTopLevelFieldGet(
            node,
            semantics.element,
            arg);
      case AccessKind.TOPLEVEL_METHOD:
        return visitor.visitTopLevelFunctionGet(
            node,
            semantics.element,
            arg);
      case AccessKind.TOPLEVEL_GETTER:
        return visitor.visitTopLevelGetterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.TOPLEVEL_SETTER:
        return visitor.visitTopLevelSetterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.visitClassTypeLiteralGet(
            node,
            semantics.constant,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.visitTypedefTypeLiteralGet(
            node,
            semantics.constant,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.visitDynamicTypeLiteralGet(
            node,
            semantics.constant,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.visitTypeVariableTypeLiteralGet(
            node,
            semantics.element,
            arg);
      case AccessKind.EXPRESSION:
        // This is not a valid case.
        break;
      case AccessKind.THIS:
        // TODO(johnniwinther): Handle this when `this` is a [Send].
        break;
      case AccessKind.THIS_PROPERTY:
        return visitor.visitThisPropertyGet(
            node,
            selector,
            arg);
      case AccessKind.SUPER_FIELD:
      case AccessKind.SUPER_FINAL_FIELD:
        return visitor.visitSuperFieldGet(
            node,
            semantics.element,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperMethodGet(
            node,
            semantics.element,
            arg);
      case AccessKind.SUPER_GETTER:
        return visitor.visitSuperGetterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.SUPER_SETTER:
        return visitor.visitSuperSetterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.CONSTANT:
        return visitor.visitConstantGet(
            node,
            semantics.constant,
            arg);
      case AccessKind.UNRESOLVED:
        return visitor.visitUnresolvedGet(
            node,
            semantics.element,
            arg);
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperGet(
            node,
            semantics.element,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidGet(
            node,
            semantics.element,
            arg);
      case AccessKind.COMPOUND:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(node, "Invalid getter: ${semantics}");
  }

  String toString() => 'get($selector, $semantics)';
}

/// The structure for a [Send] that is an assignment.
class SetStructure<R, A> implements SendStructure<R, A> {
  /// The target of the assignment.
  final AccessSemantics semantics;

  /// The [Selector] for the setter invocation.
  final Selector selector;

  SetStructure(this.semantics, this.selector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
        return visitor.visitIfNotNullDynamicPropertySet(
          node,
          node.receiver,
          selector,
          node.arguments.single,
          arg);
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitDynamicPropertySet(
          node,
          node.receiver,
          selector,
          node.arguments.single,
          arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.visitLocalFunctionSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.LOCAL_VARIABLE:
        return visitor.visitLocalVariableSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.FINAL_LOCAL_VARIABLE:
        return visitor.visitFinalLocalVariableSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.PARAMETER:
        return visitor.visitParameterSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.FINAL_PARAMETER:
        return visitor.visitFinalParameterSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.STATIC_FIELD:
        return visitor.visitStaticFieldSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.FINAL_STATIC_FIELD:
        return visitor.visitFinalStaticFieldSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.STATIC_METHOD:
        return visitor.visitStaticFunctionSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.STATIC_GETTER:
        return visitor.visitStaticGetterSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.STATIC_SETTER:
        return visitor.visitStaticSetterSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.TOPLEVEL_FIELD:
        return visitor.visitTopLevelFieldSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.FINAL_TOPLEVEL_FIELD:
        return visitor.visitFinalTopLevelFieldSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.TOPLEVEL_METHOD:
        return visitor.visitTopLevelFunctionSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.TOPLEVEL_GETTER:
        return visitor.visitTopLevelGetterSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.TOPLEVEL_SETTER:
        return visitor.visitTopLevelSetterSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.visitClassTypeLiteralSet(
            node,
            semantics.constant,
            node.arguments.single,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.visitTypedefTypeLiteralSet(
            node,
            semantics.constant,
            node.arguments.single,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.visitDynamicTypeLiteralSet(
            node,
            semantics.constant,
            node.arguments.single,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.visitTypeVariableTypeLiteralSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.EXPRESSION:
        // This is not a valid case.
        break;
      case AccessKind.THIS:
        // This is not a valid case.
        break;
      case AccessKind.THIS_PROPERTY:
        return visitor.visitThisPropertySet(
            node,
            selector,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_FIELD:
        return visitor.visitSuperFieldSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_FINAL_FIELD:
        return visitor.visitFinalSuperFieldSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperMethodSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_GETTER:
        return visitor.visitSuperGetterSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_SETTER:
        return visitor.visitSuperSetterSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.CONSTANT:
        // TODO(johnniwinther): Should this be a valid case?
        break;
      case AccessKind.UNRESOLVED_SUPER:
        // TODO(johnniwinther): Handle this separately.
      case AccessKind.UNRESOLVED:
        return visitor.visitUnresolvedSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.COMPOUND:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(node, "Invalid setter: ${semantics}");
  }

  String toString() => 'set($selector,$semantics)';
}

/// The structure for a [Send] that is a negation, i.e. of the form `!e`.
class NotStructure<R, A> implements SendStructure<R, A> {
  /// The target of the negation.
  final AccessSemantics semantics;

  NotStructure(this.semantics);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitNot(
            node,
            node.receiver,
            arg);
     default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(node, "Invalid setter: ${semantics}");
  }

  String toString() => 'not($semantics)';
}

/// The structure for a [Send] that is an invocation of a user definable unary
/// operator.
class UnaryStructure<R, A> implements SendStructure<R, A> {
  /// The target of the unary operation.
  final AccessSemantics semantics;

  /// The user definable unary operator.
  final UnaryOperator operator;

  UnaryStructure(this.semantics, this.operator);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitUnary(
            node,
            operator,
            node.receiver,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperUnary(
            node,
            operator,
            semantics.element,
            arg);
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperUnary(
            node,
            operator,
            semantics.element,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidUnary(
            node,
            operator,
            semantics.element,
            arg);
      default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(node, "Invalid setter: ${semantics}");
  }

  String toString() => 'unary($operator,$semantics)';
}

/// The structure for a [Send] that is an invocation of a undefined unary
/// operator.
class InvalidUnaryStructure<R, A> implements SendStructure<R, A> {
  const InvalidUnaryStructure();

  @override
  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.errorUndefinedUnaryExpression(
        node,
        node.selector,
        node.receiver,
        arg);
  }

  String toString() => 'invalid unary';
}

/// The structure for a [Send] that is an index expression, i.e. of the form
/// `a[b]`.
class IndexStructure<R, A> implements SendStructure<R, A> {
  /// The target of the left operand.
  final AccessSemantics semantics;

  IndexStructure(this.semantics);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitIndex(
            node,
            node.receiver,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperIndex(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperIndex(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidIndex(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(node, "Invalid index: ${semantics}");
  }
}

/// The structure for a [Send] that is an equals test, i.e. of the form
/// `a == b`.
class EqualsStructure<R, A> implements SendStructure<R, A> {
  /// The target of the left operand.
  final AccessSemantics semantics;

  EqualsStructure(this.semantics);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitEquals(
            node,
            node.receiver,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperEquals(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidEquals(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(node, "Invalid equals: ${semantics}");
  }

  String toString() => '==($semantics)';
}

/// The structure for a [Send] that is a not-equals test, i.e. of the form
/// `a != b`.
class NotEqualsStructure<R, A> implements SendStructure<R, A> {
  /// The target of the left operand.
  final AccessSemantics semantics;

  NotEqualsStructure(this.semantics);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitNotEquals(
            node,
            node.receiver,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperNotEquals(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidNotEquals(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(
        node, "Invalid not equals: ${semantics}");
  }

  String toString() => '!=($semantics)';
}

/// The structure for a [Send] that is an invocation of a user-definable binary
/// operator.
class BinaryStructure<R, A> implements SendStructure<R, A> {
  /// The target of the left operand.
  final AccessSemantics semantics;

  /// The user definable binary operator.
  final BinaryOperator operator;

  BinaryStructure(this.semantics, this.operator);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitBinary(
            node,
            node.receiver,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperBinary(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperBinary(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidBinary(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(
        node, "Invalid binary: ${semantics}");
  }

  String toString() => 'binary($operator,$semantics)';
}

/// The structure for a [Send] that is an invocation of a undefined binary
/// operator.
class InvalidBinaryStructure<R, A> implements SendStructure<R, A> {
  const InvalidBinaryStructure();

  @override
  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    return visitor.errorUndefinedBinaryExpression(
        node,
        node.receiver,
        node.selector,
        node.arguments.single,
        arg);
  }

  String toString() => 'invalid binary';
}

/// The structure for a [Send] that is of the form `a[b] = c`.
class IndexSetStructure<R, A> implements SendStructure<R, A> {
  /// The target of the index set operation.
  final AccessSemantics semantics;

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the `[]=` operator invocation.
  final Selector selector;

  IndexSetStructure(this.semantics, this.selector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitIndexSet(
            node,
            node.receiver,
            node.arguments.first,
            node.arguments.tail.head,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperIndexSet(
            node,
            semantics.element,
            node.arguments.first,
            node.arguments.tail.head,
            arg);
      case AccessKind.UNRESOLVED_SUPER:
      case AccessKind.UNRESOLVED:
        return visitor.visitUnresolvedSuperIndexSet(
            node,
            semantics.element,
            node.arguments.first,
            node.arguments.tail.head,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidIndexSet(
            node,
            semantics.element,
            node.arguments.first,
            node.arguments.tail.head,
            arg);
      default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(
        node, "Invalid index set: ${semantics}");
  }

  String toString() => '[]=($semantics)';
}

/// The structure for a [Send] that is an prefix operation on an index
/// expression, i.e. of the form `--a[b]`.
class IndexPrefixStructure<R, A> implements SendStructure<R, A> {
  /// The target of the left operand.
  final AccessSemantics semantics;

  /// The `++` or `--` operator used in the operation.
  final IncDecOperator operator;

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the `[]` invocation.
  final Selector getterSelector;

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the `[]=` invocation.
  final Selector setterSelector;

  IndexPrefixStructure(this.semantics,
                       this.operator,
                       this.getterSelector,
                       this.setterSelector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitIndexPrefix(
            node,
            node.receiver,
            node.arguments.single,
            operator,
            arg);
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperIndexPrefix(
            node,
            semantics.element,
            node.arguments.single,
            operator,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidIndexPrefix(
            node,
            semantics.element,
            node.arguments.single,
            operator,
            arg);
      case AccessKind.COMPOUND:
        CompoundAccessSemantics compoundSemantics = semantics;
        switch (compoundSemantics.compoundAccessKind) {
          case CompoundAccessKind.SUPER_GETTER_SETTER:
            return visitor.visitSuperIndexPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                node.arguments.single,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_GETTER:
            return visitor.visitUnresolvedSuperGetterIndexPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                node.arguments.single,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_SETTER:
            return visitor.visitUnresolvedSuperSetterIndexPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                node.arguments.single,
                operator,
                arg);
          default:
            // This is not a valid case.
            break;
        }
        break;
      default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(
        node, "Invalid index prefix: ${semantics}");
  }
}

/// The structure for a [Send] that is an postfix operation on an index
/// expression, i.e. of the form `a[b]++`.
class IndexPostfixStructure<R, A> implements SendStructure<R, A> {
  /// The target of the left operand.
  final AccessSemantics semantics;

  /// The `++` or `--` operator used in the operation.
  final IncDecOperator operator;

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the `[]` invocation.
  final Selector getterSelector;

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the `[]=` invocation.
  final Selector setterSelector;

  IndexPostfixStructure(this.semantics,
                        this.operator,
                        this.getterSelector,
                        this.setterSelector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitIndexPostfix(
            node,
            node.receiver,
            node.arguments.single,
            operator,
            arg);
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperIndexPostfix(
            node,
            semantics.element,
            node.arguments.single,
            operator,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidIndexPostfix(
            node,
            semantics.element,
            node.arguments.single,
            operator,
            arg);
      case AccessKind.COMPOUND:
        CompoundAccessSemantics compoundSemantics = semantics;
        switch (compoundSemantics.compoundAccessKind) {
          case CompoundAccessKind.SUPER_GETTER_SETTER:
            return visitor.visitSuperIndexPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                node.arguments.single,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_GETTER:
            return visitor.visitUnresolvedSuperGetterIndexPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                node.arguments.single,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_SETTER:
            return visitor.visitUnresolvedSuperSetterIndexPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                node.arguments.single,
                operator,
                arg);
          default:
            // This is not a valid case.
            break;
        }
        break;
      default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(
        node, "Invalid index postfix: ${semantics}");
  }
}

/// The structure for a [Send] that is a compound assignment. For instance
/// `a += b`.
class CompoundStructure<R, A> implements SendStructure<R, A> {
  /// The target of the compound assignment, i.e. the left-hand side.
  final AccessSemantics semantics;

  /// The assignment operator used in the compound assignment.
  final AssignmentOperator operator;

  /// The [Selector] for the getter invocation.
  final Selector getterSelector;

  /// The [Selector] for the setter invocation.
  final Selector setterSelector;

  CompoundStructure(this.semantics,
                    this.operator,
                    this.getterSelector,
                    this.setterSelector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
        return visitor.visitIfNotNullDynamicPropertyCompound(
            node,
            node.receiver,
            operator,
            node.arguments.single,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitDynamicPropertyCompound(
            node,
            node.receiver,
            operator,
            node.arguments.single,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.visitLocalFunctionCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.LOCAL_VARIABLE:
        return visitor.visitLocalVariableCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.FINAL_LOCAL_VARIABLE:
        return visitor.visitFinalLocalVariableCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.PARAMETER:
        return visitor.visitParameterCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.FINAL_PARAMETER:
        return visitor.visitFinalParameterCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.STATIC_FIELD:
        return visitor.visitStaticFieldCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.FINAL_STATIC_FIELD:
        return visitor.visitFinalStaticFieldCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.STATIC_METHOD:
        return visitor.visitStaticMethodCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.STATIC_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.STATIC_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.TOPLEVEL_FIELD:
        return visitor.visitTopLevelFieldCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.FINAL_TOPLEVEL_FIELD:
        return visitor.visitFinalTopLevelFieldCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.TOPLEVEL_METHOD:
        return visitor.visitTopLevelMethodCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.TOPLEVEL_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.TOPLEVEL_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.visitClassTypeLiteralCompound(
            node,
            semantics.constant,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.visitTypedefTypeLiteralCompound(
            node,
            semantics.constant,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.visitDynamicTypeLiteralCompound(
            node,
            semantics.constant,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.visitTypeVariableTypeLiteralCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.EXPRESSION:
        // This is not a valid case.
        break;
      case AccessKind.THIS:
        // This is not a valid case.
        break;
      case AccessKind.THIS_PROPERTY:
        return visitor.visitThisPropertyCompound(
            node,
            operator,
            node.arguments.single,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.SUPER_FIELD:
        return visitor.visitSuperFieldCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_FINAL_FIELD:
        return visitor.visitFinalSuperFieldCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperMethodCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.SUPER_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CONSTANT:
        // TODO(johnniwinther): Should this be a valid case?
        break;
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.UNRESOLVED:
        return visitor.visitUnresolvedCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidCompound(
            node,
            semantics.element,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.COMPOUND:
        CompoundAccessSemantics compoundSemantics = semantics;
        switch (compoundSemantics.compoundAccessKind) {
          case CompoundAccessKind.STATIC_GETTER_SETTER:
            return visitor.visitStaticGetterSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.STATIC_METHOD_SETTER:
            return visitor.visitStaticMethodSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.UNRESOLVED_STATIC_GETTER:
            return visitor.visitUnresolvedStaticGetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.UNRESOLVED_STATIC_SETTER:
            return visitor.visitUnresolvedStaticSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.TOPLEVEL_GETTER_SETTER:
            return visitor.visitTopLevelGetterSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.TOPLEVEL_METHOD_SETTER:
            return visitor.visitTopLevelMethodSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.UNRESOLVED_TOPLEVEL_GETTER:
            return visitor.visitUnresolvedTopLevelGetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.UNRESOLVED_TOPLEVEL_SETTER:
            return visitor.visitUnresolvedTopLevelSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.SUPER_FIELD_FIELD:
            // TODO(johnniwinther): Handle this.
            break;
          case CompoundAccessKind.SUPER_GETTER_SETTER:
            return visitor.visitSuperGetterSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.SUPER_GETTER_FIELD:
            return visitor.visitSuperGetterFieldCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.SUPER_METHOD_SETTER:
            return visitor.visitSuperMethodSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.SUPER_FIELD_SETTER:
            return visitor.visitSuperFieldSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_GETTER:
            return visitor.visitUnresolvedSuperGetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_SETTER:
            return visitor.visitUnresolvedSuperSetterCompound(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                node.arguments.single,
                arg);
        }
        break;
    }
    throw new SpannableAssertionFailure(node,
        "Invalid compound assigment: ${semantics}");
  }

  String toString() => 'compound($operator,$semantics)';
}

/// The structure for a [Send] that is a compound assignment on the index
/// operator. For instance `a[b] += c`.
class CompoundIndexSetStructure<R, A> implements SendStructure<R, A> {
  /// The target of the index operations.
  final AccessSemantics semantics;

  /// The assignment operator used in the compound assignment.
  final AssignmentOperator operator;

  /// The [Selector] for the `[]` operator invocation.
  final Selector getterSelector;

  /// The [Selector] for the `[]=` operator invocation.
  final Selector setterSelector;

  CompoundIndexSetStructure(this.semantics, this.operator,
                            this.getterSelector,
                            this.setterSelector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitCompoundIndexSet(
            node,
            node.receiver,
            node.arguments.first,
            operator,
            node.arguments.tail.head,
            arg);
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperCompoundIndexSet(
            node,
            semantics.element,
            node.arguments.first,
            operator,
            node.arguments.tail.head,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidCompoundIndexSet(
            node,
            semantics.element,
            node.arguments.first,
            operator,
            node.arguments.tail.head,
            arg);
      case AccessKind.COMPOUND:
        CompoundAccessSemantics compoundSemantics = semantics;
        switch (compoundSemantics.compoundAccessKind) {
          case CompoundAccessKind.SUPER_GETTER_SETTER:
            return visitor.visitSuperCompoundIndexSet(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                node.arguments.first,
                operator,
                node.arguments.tail.head,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_GETTER:
            return visitor.visitUnresolvedSuperGetterCompoundIndexSet(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                node.arguments.first,
                operator,
                node.arguments.tail.head,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_SETTER:
            return visitor.visitUnresolvedSuperSetterCompoundIndexSet(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                node.arguments.first,
                operator,
                node.arguments.tail.head,
                arg);
          default:
            // This is not a valid case.
            break;
        }
        break;
      default:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(
        node, "Invalid compound index set: ${semantics}");
  }

  String toString() => 'compound []=($operator,$semantics)';
}

/// The structure for a [Send] that is a prefix operations. For instance
/// `++a`.
class PrefixStructure<R, A> implements SendStructure<R, A> {
  /// The target of the prefix operation.
  final AccessSemantics semantics;

  /// The `++` or `--` operator used in the operation.
  final IncDecOperator operator;

  /// The [Selector] for the getter invocation.
  final Selector getterSelector;

  /// The [Selector] for the setter invocation.
  final Selector setterSelector;

  PrefixStructure(this.semantics,
                  this.operator,
                  this.getterSelector,
                  this.setterSelector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
        return visitor.visitIfNotNullDynamicPropertyPrefix(
            node,
            node.receiver,
            operator,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitDynamicPropertyPrefix(
            node,
            node.receiver,
            operator,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.visitLocalFunctionPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.LOCAL_VARIABLE:
        return visitor.visitLocalVariablePrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.FINAL_LOCAL_VARIABLE:
        return visitor.visitFinalLocalVariablePrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.PARAMETER:
        return visitor.visitParameterPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.FINAL_PARAMETER:
        return visitor.visitFinalParameterPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.STATIC_FIELD:
        return visitor.visitStaticFieldPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.FINAL_STATIC_FIELD:
        return visitor.visitFinalStaticFieldPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.STATIC_METHOD:
        return visitor.visitStaticMethodPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.STATIC_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.STATIC_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.TOPLEVEL_FIELD:
        return visitor.visitTopLevelFieldPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.FINAL_TOPLEVEL_FIELD:
        return visitor.visitFinalTopLevelFieldPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.TOPLEVEL_METHOD:
        return visitor.visitTopLevelMethodPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.TOPLEVEL_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.TOPLEVEL_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.visitClassTypeLiteralPrefix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.visitTypedefTypeLiteralPrefix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.visitDynamicTypeLiteralPrefix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.visitTypeVariableTypeLiteralPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.EXPRESSION:
        // This is not a valid case.
        break;
      case AccessKind.THIS:
        // This is not a valid case.
        break;
      case AccessKind.THIS_PROPERTY:
        return visitor.visitThisPropertyPrefix(
            node,
            operator,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.SUPER_FIELD:
        return visitor.visitSuperFieldPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.SUPER_FINAL_FIELD:
        return visitor.visitFinalSuperFieldPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperMethodPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.SUPER_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.SUPER_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CONSTANT:
        // TODO(johnniwinther): Should this be a valid case?
        break;
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.UNRESOLVED:
        return visitor.visitUnresolvedPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidPrefix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.COMPOUND:
        CompoundAccessSemantics compoundSemantics = semantics;
        switch (compoundSemantics.compoundAccessKind) {
          case CompoundAccessKind.STATIC_GETTER_SETTER:
            return visitor.visitStaticGetterSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.STATIC_METHOD_SETTER:
            return visitor.visitStaticMethodSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_STATIC_GETTER:
            return visitor.visitUnresolvedStaticGetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_STATIC_SETTER:
            return visitor.visitUnresolvedStaticSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.STATIC_METHOD_SETTER:
            return visitor.visitStaticMethodSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.TOPLEVEL_GETTER_SETTER:
            return visitor.visitTopLevelGetterSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.TOPLEVEL_METHOD_SETTER:
            return visitor.visitTopLevelMethodSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_TOPLEVEL_GETTER:
            return visitor.visitUnresolvedTopLevelGetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_TOPLEVEL_SETTER:
            return visitor.visitUnresolvedTopLevelSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_FIELD_FIELD:
            return visitor.visitSuperFieldFieldPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_GETTER_SETTER:
            return visitor.visitSuperGetterSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_GETTER_FIELD:
            return visitor.visitSuperGetterFieldPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_METHOD_SETTER:
            return visitor.visitSuperMethodSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_FIELD_SETTER:
            return visitor.visitSuperFieldSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_GETTER:
            return visitor.visitUnresolvedSuperGetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_SETTER:
            return visitor.visitUnresolvedSuperSetterPrefix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
        }
    }
    throw new SpannableAssertionFailure(node,
        "Invalid compound assigment: ${semantics}");
  }

  String toString() => 'prefix($operator,$semantics)';
}

/// The structure for a [Send] that is a postfix operations. For instance
/// `a++`.
class PostfixStructure<R, A> implements SendStructure<R, A> {
  /// The target of the postfix operation.
  final AccessSemantics semantics;

  /// The `++` or `--` operator used in the operation.
  final IncDecOperator operator;

  /// The [Selector] for the getter invocation.
  final Selector getterSelector;

  /// The [Selector] for the setter invocation.
  final Selector setterSelector;

  PostfixStructure(this.semantics,
                   this.operator,
                   this.getterSelector,
                   this.setterSelector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
      case AccessKind.CONDITIONAL_DYNAMIC_PROPERTY:
        return visitor.visitIfNotNullDynamicPropertyPostfix(
            node,
            node.receiver,
            operator,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitDynamicPropertyPostfix(
            node,
            node.receiver,
            operator,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.visitLocalFunctionPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.LOCAL_VARIABLE:
        return visitor.visitLocalVariablePostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.FINAL_LOCAL_VARIABLE:
        return visitor.visitFinalLocalVariablePostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.PARAMETER:
        return visitor.visitParameterPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.FINAL_PARAMETER:
        return visitor.visitFinalParameterPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.STATIC_FIELD:
        return visitor.visitStaticFieldPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.FINAL_STATIC_FIELD:
        return visitor.visitFinalStaticFieldPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.STATIC_METHOD:
        return visitor.visitStaticMethodPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.STATIC_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.STATIC_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.TOPLEVEL_FIELD:
        return visitor.visitTopLevelFieldPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.FINAL_TOPLEVEL_FIELD:
        return visitor.visitFinalTopLevelFieldPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.TOPLEVEL_METHOD:
        return visitor.visitTopLevelMethodPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.TOPLEVEL_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.TOPLEVEL_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.visitClassTypeLiteralPostfix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.visitTypedefTypeLiteralPostfix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.visitDynamicTypeLiteralPostfix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.visitTypeVariableTypeLiteralPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.EXPRESSION:
        // This is not a valid case.
        break;
      case AccessKind.THIS:
        // This is not a valid case.
        break;
      case AccessKind.THIS_PROPERTY:
        return visitor.visitThisPropertyPostfix(
            node,
            operator,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.SUPER_FIELD:
        return visitor.visitSuperFieldPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.SUPER_FINAL_FIELD:
        return visitor.visitFinalSuperFieldPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperMethodPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.SUPER_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.SUPER_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CONSTANT:
        // TODO(johnniwinther): Should this be a valid case?
        break;
      case AccessKind.UNRESOLVED_SUPER:
        return visitor.visitUnresolvedSuperPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.UNRESOLVED:
        return visitor.visitUnresolvedPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.INVALID:
        return visitor.errorInvalidPostfix(
            node,
            semantics.element,
            operator,
            arg);
      case AccessKind.COMPOUND:
        CompoundAccessSemantics compoundSemantics = semantics;
        switch (compoundSemantics.compoundAccessKind) {
          case CompoundAccessKind.STATIC_GETTER_SETTER:
            return visitor.visitStaticGetterSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_STATIC_GETTER:
            return visitor.visitUnresolvedStaticGetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_STATIC_SETTER:
            return visitor.visitUnresolvedStaticSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.STATIC_METHOD_SETTER:
            return visitor.visitStaticMethodSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.TOPLEVEL_GETTER_SETTER:
            return visitor.visitTopLevelGetterSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.TOPLEVEL_METHOD_SETTER:
            return visitor.visitTopLevelMethodSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_TOPLEVEL_GETTER:
            return visitor.visitUnresolvedTopLevelGetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_TOPLEVEL_SETTER:
            return visitor.visitUnresolvedTopLevelSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_FIELD_FIELD:
            return visitor.visitSuperFieldFieldPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_GETTER_SETTER:
            return visitor.visitSuperGetterSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_GETTER_FIELD:
            return visitor.visitSuperGetterFieldPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_METHOD_SETTER:
            return visitor.visitSuperMethodSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.SUPER_FIELD_SETTER:
            return visitor.visitSuperFieldSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_GETTER:
            return visitor.visitUnresolvedSuperGetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
          case CompoundAccessKind.UNRESOLVED_SUPER_SETTER:
            return visitor.visitUnresolvedSuperSetterPostfix(
                node,
                compoundSemantics.getter,
                compoundSemantics.setter,
                operator,
                arg);
        }
    }
    throw new SpannableAssertionFailure(node,
        "Invalid compound assigment: ${semantics}");
  }

  String toString() => 'postfix($operator,$semantics)';
}


/// The structure for a [Send] whose prefix is a prefix for a deferred library.
/// For instance `deferred.a` where `deferred` is a deferred prefix.
class DeferredPrefixStructure<R, A> implements SendStructure<R, A> {
  /// The deferred prefix element.
  final PrefixElement prefix;

  /// The send structure for the whole [Send] node. For instance a
  /// [GetStructure] for `deferred.a` where `a` is a top level member of the
  /// deferred library.
  final SendStructure sendStructure;

  DeferredPrefixStructure(this.prefix, this.sendStructure) {
    assert(sendStructure != null);
  }

  @override
  R dispatch(SemanticSendVisitor<R, A> visitor, Send send, A arg) {
    visitor.previsitDeferredAccess(send, prefix, arg);
    return sendStructure.dispatch(visitor, send, arg);
  }
}


/// The structure for a [NewExpression] of a new invocation.
abstract class NewStructure<R, A> implements SemanticSendStructure<R, A> {
  /// Calls the matching visit method on [visitor] with [node] and [arg].
  R dispatch(SemanticSendVisitor<R, A> visitor, NewExpression node, A arg);
}

/// The structure for a [NewExpression] of a new invocation. For instance
/// `new C()`.
class NewInvokeStructure<R, A> extends NewStructure<R, A> {
  final ConstructorAccessSemantics semantics;
  final Selector selector;

  NewInvokeStructure(this.semantics, this.selector);

  CallStructure get callStructure => selector.callStructure;

  R dispatch(SemanticSendVisitor<R, A> visitor, NewExpression node, A arg) {
    switch (semantics.kind) {
      case ConstructorAccessKind.GENERATIVE:
        return visitor.visitGenerativeConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, callStructure, arg);
      case ConstructorAccessKind.REDIRECTING_GENERATIVE:
        return visitor.visitRedirectingGenerativeConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, callStructure, arg);
      case ConstructorAccessKind.FACTORY:
        return visitor.visitFactoryConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, callStructure, arg);
      case ConstructorAccessKind.REDIRECTING_FACTORY:
        return visitor.visitRedirectingFactoryConstructorInvoke(
            node, semantics.element, semantics.type,
            semantics.effectiveTargetSemantics.element,
            semantics.effectiveTargetSemantics.type,
            node.send.argumentsNode, callStructure, arg);
      case ConstructorAccessKind.ABSTRACT:
        return visitor.visitAbstractClassConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, callStructure, arg);
      case ConstructorAccessKind.UNRESOLVED_CONSTRUCTOR:
        return visitor.visitUnresolvedConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, selector, arg);
      case ConstructorAccessKind.UNRESOLVED_TYPE:
        return visitor.visitUnresolvedClassConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, selector, arg);
      case ConstructorAccessKind.NON_CONSTANT_CONSTRUCTOR:
        return visitor.errorNonConstantConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, callStructure, arg);
      case ConstructorAccessKind.ERRONEOUS_REDIRECTING_FACTORY:
        return visitor.visitUnresolvedRedirectingFactoryConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, callStructure, arg);
      case ConstructorAccessKind.INCOMPATIBLE:
        return visitor.visitConstructorIncompatibleInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, callStructure, arg);
    }
    throw new SpannableAssertionFailure(node,
        "Unhandled constructor invocation kind: ${semantics.kind}");
  }

  String toString() => 'new($semantics,$selector)';
}

enum ConstantInvokeKind {
  CONSTRUCTED,
  BOOL_FROM_ENVIRONMENT,
  INT_FROM_ENVIRONMENT,
  STRING_FROM_ENVIRONMENT,
}

/// The structure for a [NewExpression] of a constant invocation. For instance
/// `const C()`.
class ConstInvokeStructure<R, A> extends NewStructure<R, A> {
  final ConstantInvokeKind kind;
  final ConstantExpression constant;

  ConstInvokeStructure(this.kind, this.constant);

  R dispatch(SemanticSendVisitor<R, A> visitor, NewExpression node, A arg) {
    switch (kind) {
      case ConstantInvokeKind.CONSTRUCTED:
        return visitor.visitConstConstructorInvoke(node, constant, arg);
      case ConstantInvokeKind.BOOL_FROM_ENVIRONMENT:
        return visitor.visitBoolFromEnvironmentConstructorInvoke(
            node, constant, arg);
      case ConstantInvokeKind.INT_FROM_ENVIRONMENT:
        return visitor.visitIntFromEnvironmentConstructorInvoke(
            node, constant, arg);
      case ConstantInvokeKind.STRING_FROM_ENVIRONMENT:
        return visitor.visitStringFromEnvironmentConstructorInvoke(
            node, constant, arg);
    }
  }
}

/// The structure of a parameter declaration.
abstract class ParameterStructure<R, A> {
  final VariableDefinitions definitions;
  final Node node;
  final ParameterElement parameter;

  ParameterStructure(this.definitions, this.node, this.parameter);

  /// Calls the matching visit method on [visitor] with [definitions] and [arg].
  R dispatch(SemanticDeclarationVisitor<R, A> visitor, A arg);
}

/// The structure of a required parameter declaration.
class RequiredParameterStructure<R, A> extends ParameterStructure<R, A> {
  final int index;

  RequiredParameterStructure(
      VariableDefinitions definitions,
      Node node,
      ParameterElement parameter,
      this.index)
      : super(definitions, node, parameter);

  @override
  R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             A arg) {
    if (parameter.isInitializingFormal) {
      return visitor.visitInitializingFormalDeclaration(
          definitions, node, parameter, index, arg);
    } else {
      return visitor.visitParameterDeclaration(
          definitions, node, parameter, index, arg);
    }
  }
}

/// The structure of a optional positional parameter declaration.
class OptionalParameterStructure<R, A> extends ParameterStructure<R, A> {
  final ConstantExpression defaultValue;
  final int index;

  OptionalParameterStructure(
       VariableDefinitions definitions,
       Node node,
       ParameterElement parameter,
       this.defaultValue,
       this.index)
       : super(definitions, node, parameter);

   @override
   R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             A arg) {
    if (parameter.isInitializingFormal) {
      return visitor.visitOptionalInitializingFormalDeclaration(
          definitions, node, parameter, defaultValue, index, arg);
    } else {
      return visitor.visitOptionalParameterDeclaration(
          definitions, node, parameter, defaultValue, index, arg);
    }
  }
}

/// The structure of a optional named parameter declaration.
class NamedParameterStructure<R, A> extends ParameterStructure<R, A> {
  final ConstantExpression defaultValue;

  NamedParameterStructure(
      VariableDefinitions definitions,
      Node node,
      ParameterElement parameter,
      this.defaultValue)
      : super(definitions, node, parameter);

  @override
  R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             A arg) {
    if (parameter.isInitializingFormal) {
      return visitor.visitNamedInitializingFormalDeclaration(
          definitions, node, parameter, defaultValue, arg);
    } else {
      return visitor.visitNamedParameterDeclaration(
          definitions, node, parameter, defaultValue, arg);
    }
  }
}


enum VariableKind {
  TOP_LEVEL_FIELD,
  STATIC_FIELD,
  INSTANCE_FIELD,
  LOCAL_VARIABLE,
}

abstract class VariableStructure<R, A> {
  final VariableKind kind;
  final Node node;
  final VariableElement variable;

  VariableStructure(this.kind, this.node, this.variable);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             VariableDefinitions definitions,
             A arg);
}

class NonConstantVariableStructure<R, A>
    extends VariableStructure<R, A> {
  NonConstantVariableStructure(
      VariableKind kind, Node node, VariableElement variable)
      : super(kind, node, variable);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             VariableDefinitions definitions,
             A arg) {
    switch (kind) {
      case VariableKind.TOP_LEVEL_FIELD:
        return visitor.visitTopLevelFieldDeclaration(
            definitions, node, variable, variable.initializer, arg);
      case VariableKind.STATIC_FIELD:
        return visitor.visitStaticFieldDeclaration(
            definitions, node, variable, variable.initializer, arg);
      case VariableKind.INSTANCE_FIELD:
        return visitor.visitInstanceFieldDeclaration(
            definitions, node, variable, variable.initializer, arg);
      case VariableKind.LOCAL_VARIABLE:
        return visitor.visitLocalVariableDeclaration(
            definitions, node, variable, variable.initializer, arg);
    }
  }
}

class ConstantVariableStructure<R, A>
    extends VariableStructure<R, A> {
  final ConstantExpression constant;

  ConstantVariableStructure(
      VariableKind kind, Node node, VariableElement variable, this.constant)
      : super(kind, node, variable);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor,
             VariableDefinitions definitions,
             A arg) {
    switch (kind) {
      case VariableKind.TOP_LEVEL_FIELD:
        return visitor.visitTopLevelConstantDeclaration(
            definitions, node, variable, constant, arg);
      case VariableKind.STATIC_FIELD:
        return visitor.visitStaticConstantDeclaration(
            definitions, node, variable, constant, arg);
      case VariableKind.LOCAL_VARIABLE:
        return visitor.visitLocalConstantDeclaration(
            definitions, node, variable, constant, arg);
      default:
    }
    throw new SpannableAssertionFailure(
        node, "Invalid constant variable: $variable");
  }
}

class InitializersStructure<R, A> {
  final List<InitializerStructure<R, A>> initializers;

  InitializersStructure(this.initializers);
}

abstract class InitializerStructure<R, A> {
  R dispatch(SemanticDeclarationVisitor<R, A> visitor, A arg);

  bool get isConstructorInvoke => false;
}

class FieldInitializerStructure<R, A> extends InitializerStructure<R, A> {
  final Send node;
  final FieldElement field;

  FieldInitializerStructure(this.node, this.field);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor, A arg) {
    return visitor.visitFieldInitializer(
        node, field, node.arguments.single, arg);
  }
}

class SuperConstructorInvokeStructure<R, A> extends InitializerStructure<R, A> {
  final Send node;
  final ConstructorElement constructor;
  final InterfaceType type;
  final CallStructure callStructure;

  SuperConstructorInvokeStructure(
      this.node, this.constructor, this.type, this.callStructure);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor, A arg) {
    return visitor.visitSuperConstructorInvoke(
        node, constructor, type, node.argumentsNode, callStructure, arg);
  }

  bool get isConstructorInvoke => true;
}

class ImplicitSuperConstructorInvokeStructure<R, A>
    extends InitializerStructure<R, A> {
  final FunctionExpression node;
  final ConstructorElement constructor;
  final InterfaceType type;

  ImplicitSuperConstructorInvokeStructure(
      this.node, this.constructor, this.type);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor, A arg) {
    return visitor.visitImplicitSuperConstructorInvoke(
        node, constructor, type, arg);
  }

  bool get isConstructorInvoke => true;
}

class ThisConstructorInvokeStructure<R, A> extends InitializerStructure<R, A> {
  final Send node;
  final ConstructorElement constructor;
  final CallStructure callStructure;

  ThisConstructorInvokeStructure(
      this.node, this.constructor, this.callStructure);

  R dispatch(SemanticDeclarationVisitor<R, A> visitor, A arg) {
    return visitor.visitThisConstructorInvoke(
        node, constructor, node.argumentsNode, callStructure, arg);
  }

  bool get isConstructorInvoke => true;
}
