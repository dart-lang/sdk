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

/// Interface for the structure of the semantics of a [Send] node.
///
/// Subclasses handle each of the [Send] variations; `assert(e)`, `a && b`,
/// `a.b`, `a.b(c)`, etc.
abstract class SendStructure<R, A> {
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
  final Selector selector;

  InvokeStructure(this.semantics, this.selector);

  R dispatch(SemanticSendVisitor<R, A> visitor, Send node, A arg) {
    switch (semantics.kind) {
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
            new Selector.callClosureFrom(selector),
            arg);
      case AccessKind.LOCAL_VARIABLE:
        return visitor.visitLocalVariableInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            // TODO(johnniwinther): Store the call selector instead of the
            // selector using the name of the variable.
            new Selector.callClosureFrom(selector),
            arg);
      case AccessKind.PARAMETER:
        return visitor.visitParameterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            // TODO(johnniwinther): Store the call selector instead of the
            // selector using the name of the parameter.
            new Selector.callClosureFrom(selector),
            arg);
      case AccessKind.STATIC_FIELD:
        return visitor.visitStaticFieldInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.STATIC_METHOD:
        return visitor.visitStaticFunctionInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.STATIC_GETTER:
        return visitor.visitStaticGetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.STATIC_SETTER:
        return visitor.errorStaticSetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.TOPLEVEL_FIELD:
        return visitor.visitTopLevelFieldInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.TOPLEVEL_METHOD:
        return visitor.visitTopLevelFunctionInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.TOPLEVEL_GETTER:
        return visitor.visitTopLevelGetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.TOPLEVEL_SETTER:
        return visitor.errorTopLevelSetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.visitClassTypeLiteralInvoke(
            node,
            semantics.constant,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.visitTypedefTypeLiteralInvoke(
            node,
            semantics.constant,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.visitDynamicTypeLiteralInvoke(
            node,
            semantics.constant,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.visitTypeVariableTypeLiteralInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
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
            selector,
            arg);
      case AccessKind.THIS_PROPERTY:
        return visitor.visitThisPropertyInvoke(
            node,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.SUPER_FIELD:
        return visitor.visitSuperFieldInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.SUPER_METHOD:
        return visitor.visitSuperMethodInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.SUPER_GETTER:
        return visitor.visitSuperGetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.SUPER_SETTER:
        return visitor.errorSuperSetterInvoke(
            node,
            semantics.element,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.CONSTANT:
        return visitor.visitConstantInvoke(
            node,
            semantics.constant,
            node.argumentsNode,
            selector,
            arg);
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedInvoke(
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

  String toString() => 'invoke($selector,$semantics)';
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
        return visitor.visitLocalVariableGet(
            node,
            semantics.element,
            arg);
      case AccessKind.PARAMETER:
        return visitor.visitParameterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.STATIC_FIELD:
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
        return visitor.errorStaticSetterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.TOPLEVEL_FIELD:
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
        return visitor.errorTopLevelSetterGet(
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
        return visitor.errorSuperSetterGet(
            node,
            semantics.element,
            arg);
      case AccessKind.CONSTANT:
        return visitor.visitConstantGet(
            node,
            semantics.constant,
            arg);
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedGet(
            node,
            semantics.element,
            arg);
      case AccessKind.COMPOUND:
        // This is not a valid case.
        break;
    }
    throw new SpannableAssertionFailure(node, "Invalid getter: ${semantics}");
  }

  String toString() => 'get($selector,$semantics)';
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
      case AccessKind.DYNAMIC_PROPERTY:
          return visitor.visitDynamicPropertySet(
            node,
            node.receiver,
            selector,
            node.arguments.single,
            arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.errorLocalFunctionSet(
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
      case AccessKind.PARAMETER:
        return visitor.visitParameterSet(
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
      case AccessKind.STATIC_METHOD:
        return visitor.errorStaticFunctionSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.STATIC_GETTER:
        return visitor.errorStaticGetterSet(
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
      case AccessKind.TOPLEVEL_METHOD:
        return visitor.errorTopLevelFunctionSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.TOPLEVEL_GETTER:
        return visitor.errorTopLevelGetterSet(
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
        return visitor.errorClassTypeLiteralSet(
            node,
            semantics.constant,
            node.arguments.single,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.errorTypedefTypeLiteralSet(
            node,
            semantics.constant,
            node.arguments.single,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.errorDynamicTypeLiteralSet(
            node,
            semantics.constant,
            node.arguments.single,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.errorTypeVariableTypeLiteralSet(
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
      case AccessKind.SUPER_METHOD:
        return visitor.errorSuperMethodSet(
            node,
            semantics.element,
            node.arguments.single,
            arg);
      case AccessKind.SUPER_GETTER:
        return visitor.errorSuperGetterSet(
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
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedSet(
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

  // TODO(johnniwinther): Should we store this?
  final Selector selector;

  NotStructure(this.semantics, this.selector);

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

  String toString() => 'not($selector,$semantics)';
}

/// The structure for a [Send] that is an invocation of a user definable unary
/// operator.
class UnaryStructure<R, A> implements SendStructure<R, A> {
  /// The target of the unary operation.
  final AccessSemantics semantics;

  /// The user definable unary operator.
  final UnaryOperator operator;

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the unary operator invocation.
  final Selector selector;

  UnaryStructure(this.semantics, this.operator, this.selector);

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
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedSuperUnary(
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

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the `[]` invocation.
  final Selector selector;

  IndexStructure(this.semantics, this.selector);

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
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedSuperIndex(
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

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the `==` invocation.
  final Selector selector;

  EqualsStructure(this.semantics, this.selector);

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

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the underlying `==` invocation.
  final Selector selector;

  NotEqualsStructure(this.semantics, this.selector);

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

  // TODO(johnniwinther): Should we store this?
  /// The [Selector] for the binary operator invocation.
  final Selector selector;

  BinaryStructure(this.semantics, this.operator, this.selector);

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
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedSuperBinary(
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
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedSuperIndexSet(
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
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedSuperIndexPrefix(
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
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedSuperIndexPostfix(
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
        return visitor.errorLocalFunctionCompound(
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
      case AccessKind.PARAMETER:
        return visitor.visitParameterCompound(
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
      case AccessKind.STATIC_METHOD:
        // TODO(johnniwinther): Handle this.
        break;
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
      case AccessKind.TOPLEVEL_METHOD:
        // TODO(johnniwinther): Handle this.
        break;
      case AccessKind.TOPLEVEL_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.TOPLEVEL_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.errorClassTypeLiteralCompound(
            node,
            semantics.constant,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.errorTypedefTypeLiteralCompound(
            node,
            semantics.constant,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.errorDynamicTypeLiteralCompound(
            node,
            semantics.constant,
            operator,
            node.arguments.single,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.errorTypeVariableTypeLiteralCompound(
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
      case AccessKind.SUPER_METHOD:
        // TODO(johnniwinther): Handle this.
        break;
      case AccessKind.SUPER_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.SUPER_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CONSTANT:
        // TODO(johnniwinther): Should this be a valid case?
        break;
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedCompound(
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
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedSuperCompoundIndexSet(
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
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitDynamicPropertyPrefix(
            node,
            node.receiver,
            operator,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.errorLocalFunctionPrefix(
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
      case AccessKind.PARAMETER:
        return visitor.visitParameterPrefix(
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
      case AccessKind.STATIC_METHOD:
        // TODO(johnniwinther): Handle this.
        break;
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
      case AccessKind.TOPLEVEL_METHOD:
        // TODO(johnniwinther): Handle this.
        break;
      case AccessKind.TOPLEVEL_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.TOPLEVEL_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.errorClassTypeLiteralPrefix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.errorTypedefTypeLiteralPrefix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.errorDynamicTypeLiteralPrefix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.errorTypeVariableTypeLiteralPrefix(
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
      case AccessKind.SUPER_METHOD:
        // TODO(johnniwinther): Handle this.
        break;
      case AccessKind.SUPER_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.SUPER_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CONSTANT:
        // TODO(johnniwinther): Should this be a valid case?
        break;
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedPrefix(
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
      case AccessKind.DYNAMIC_PROPERTY:
        return visitor.visitDynamicPropertyPostfix(
            node,
            node.receiver,
            operator,
            getterSelector,
            setterSelector,
            arg);
      case AccessKind.LOCAL_FUNCTION:
        return visitor.errorLocalFunctionPostfix(
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
      case AccessKind.PARAMETER:
        return visitor.visitParameterPostfix(
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
      case AccessKind.STATIC_METHOD:
        // TODO(johnniwinther): Handle this.
        break;
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
      case AccessKind.TOPLEVEL_METHOD:
        // TODO(johnniwinther): Handle this.
        break;
      case AccessKind.TOPLEVEL_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.TOPLEVEL_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CLASS_TYPE_LITERAL:
        return visitor.errorClassTypeLiteralPostfix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.TYPEDEF_TYPE_LITERAL:
        return visitor.errorTypedefTypeLiteralPostfix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.DYNAMIC_TYPE_LITERAL:
        return visitor.errorDynamicTypeLiteralPostfix(
            node,
            semantics.constant,
            operator,
            arg);
      case AccessKind.TYPE_PARAMETER_TYPE_LITERAL:
        return visitor.errorTypeVariableTypeLiteralPostfix(
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
      case AccessKind.SUPER_METHOD:
        // TODO(johnniwinther): Handle this.
        break;
      case AccessKind.SUPER_GETTER:
        // This is not a valid case.
        break;
      case AccessKind.SUPER_SETTER:
        // This is not a valid case.
        break;
      case AccessKind.CONSTANT:
        // TODO(johnniwinther): Should this be a valid case?
        break;
      case AccessKind.UNRESOLVED:
        return visitor.errorUnresolvedPostfix(
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
        }
    }
    throw new SpannableAssertionFailure(node,
        "Invalid compound assigment: ${semantics}");
  }

  String toString() => 'postfix($operator,$semantics)';
}

/// The structure for a [NewExpression] of a new invocation.
abstract class NewStructure<R, A> {
  /// Calls the matching visit method on [visitor] with [node] and [arg].
  R dispatch(SemanticSendVisitor<R, A> visitor, NewExpression node, A arg);
}

/// The structure for a [NewExpression] of a new invocation. For instance
/// `new C()`.
class NewInvokeStructure<R, A> extends NewStructure<R, A> {
  final ConstructorAccessSemantics semantics;
  final Selector selector;

  NewInvokeStructure(this.semantics, this.selector);

  R dispatch(SemanticSendVisitor<R, A> visitor, NewExpression node, A arg) {
    switch (semantics.kind) {
      case ConstructorAccessKind.GENERATIVE:
        return visitor.visitGenerativeConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, selector, arg);
      case ConstructorAccessKind.REDIRECTING_GENERATIVE:
        return visitor.visitRedirectingGenerativeConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, selector, arg);
      case ConstructorAccessKind.FACTORY:
        return visitor.visitFactoryConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, selector, arg);
      case ConstructorAccessKind.REDIRECTING_FACTORY:
        return visitor.visitRedirectingFactoryConstructorInvoke(
            node, semantics.element, semantics.type,
            semantics.effectiveTargetSemantics.element,
            semantics.effectiveTargetSemantics.type,
            node.send.argumentsNode, selector, arg);
      case ConstructorAccessKind.ABSTRACT:
        return visitor.errorAbstractClassConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, selector, arg);
      case ConstructorAccessKind.ERRONEOUS:
        return visitor.errorUnresolvedConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, selector, arg);
      case ConstructorAccessKind.ERRONEOUS_REDIRECTING_FACTORY:
        return visitor.errorUnresolvedRedirectingFactoryConstructorInvoke(
            node, semantics.element, semantics.type,
            node.send.argumentsNode, selector, arg);
    }
    throw new SpannableAssertionFailure(node,
        "Unhandled constructor invocation kind: ${semantics.kind}");
  }
}

/// The structure for a [NewExpression] of a constant invocation. For instance
/// `const C()`.
class ConstInvokeStructure<R, A> extends NewStructure<R, A> {
  final ConstructedConstantExpression constant;

  ConstInvokeStructure(this.constant);

  R dispatch(SemanticSendVisitor<R, A> visitor, NewExpression node, A arg) {
    return visitor.visitConstConstructorInvoke(node, constant, arg);
  }
}

