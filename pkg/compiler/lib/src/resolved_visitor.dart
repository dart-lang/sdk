// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

/// Enum for the visit methods added in [ResolvedVisitor].
// TODO(johnniwinther): Remove this.
enum ResolvedKind {
  ASSERT,
  TYPE_LITERAL,
  SUPER,
  OPERATOR,
  TYPE_PREFIX,
  GETTER,
  STATIC,
  CLOSURE,
  DYNAMIC,
  ERROR,
  SEND_SET,
  NEW,
  SUPER_CONSTRUCTOR,
}

/// Abstract interface for a [ResolvedVisitor].
// TODO(johnniwinther): Remove this.
abstract class ResolvedKindVisitor<R> {
  @deprecated
  R visitSuperSend(Send node);

  @deprecated
  R visitOperatorSend(Send node);
  R visitGetterSend(Send node);

  @deprecated
  R visitClosureSend(Send node);
  @deprecated
  R visitDynamicSend(Send node);
  R visitStaticSend(Send node);

  R handleSuperConstructorInvoke(Send node);
  R handleSendSet(SendSet node);
  R handleNewExpression(NewExpression node);

  /// Visitor callback for a type literal.
  @deprecated
  R visitTypeLiteralSend(Send node);

  /// Visitor callback for the class prefix of a static access, like `Foo` in
  /// `Foo.staticField`.
  // TODO(johnniwinther): Remove this when not needed by the inferrer.
  @deprecated
  R visitTypePrefixSend(Send node);

  @deprecated
  R visitAssertSend(Send node);

  internalError(Spannable node, String reason);
}

/// Visitor that returns the [ResolvedKind] corresponding to the called visitor
/// method.
class ResolvedKindComputer implements ResolvedKindVisitor {
  const ResolvedKindComputer();

  ResolvedKind visitSuperSend(Send node) => ResolvedKind.SUPER;
  ResolvedKind visitOperatorSend(Send node) => ResolvedKind.OPERATOR;
  ResolvedKind visitGetterSend(Send node) => ResolvedKind.GETTER;
  ResolvedKind visitClosureSend(Send node) => ResolvedKind.CLOSURE;
  ResolvedKind visitDynamicSend(Send node) => ResolvedKind.DYNAMIC;
  ResolvedKind visitStaticSend(Send node) => ResolvedKind.STATIC;
  ResolvedKind visitTypeLiteralSend(Send node) => ResolvedKind.TYPE_LITERAL;
  ResolvedKind visitTypePrefixSend(Send node) => ResolvedKind.TYPE_PREFIX;
  ResolvedKind visitAssertSend(Send node) => ResolvedKind.ASSERT;
  ResolvedKind handleSuperConstructorInvoke(Send node) {
    return ResolvedKind.SUPER_CONSTRUCTOR;
  }
  ResolvedKind handleSendSet(SendSet node) => ResolvedKind.SEND_SET;
  ResolvedKind handleNewExpression(NewExpression node) => ResolvedKind.NEW;
  internalError(Spannable node, String reason) => ResolvedKind.ERROR;
}

abstract class ResolvedVisitor<R>
    implements Visitor<R>, ResolvedKindVisitor<R> {}

abstract class BaseResolvedVisitor<R> extends Visitor<R>
    implements ResolvedVisitor<R> {

  TreeElements elements;

  BaseResolvedVisitor(this.elements);

  /// Dispatch using the old [ResolvedVisitor] logic.
  // TODO(johnniwinther): Remove this.
  _oldDispatch(Send node, ResolvedKindVisitor visitor) {
    Element element = elements[node];
    if (elements.isAssert(node)) {
      return visitor.visitAssertSend(node);
    } else if (elements.isTypeLiteral(node)) {
      return visitor.visitTypeLiteralSend(node);
    } else if (node.isSuperCall) {
      if (element != null && element.isConstructor) {
        return visitor.handleSuperConstructorInvoke(node);
      }
      return visitor.visitSuperSend(node);
    } else if (node.isOperator) {
      return visitor.visitOperatorSend(node);
    } else if (node.isPropertyAccess) {
      if (!Elements.isUnresolved(element) && element.impliesType) {
        return visitor.visitTypePrefixSend(node);
      } else {
        return visitor.visitGetterSend(node);
      }
    } else if (element != null && Initializers.isConstructorRedirect(node)) {
      return visitor.visitStaticSend(node);
    } else if (Elements.isClosureSend(node, element)) {
      return visitor.visitClosureSend(node);
    } else {
      if (node.isConditional) {
        return visitor.visitDynamicSend(node);
      } else if (Elements.isUnresolved(element)) {
        if (element == null) {
          // Example: f() with 'f' unbound.
          // This can only happen inside an instance method.
          return visitor.visitDynamicSend(node);
        } else {
          return visitor.visitStaticSend(node);
        }
      } else if (element.isInstanceMember) {
        // Example: f() with 'f' bound to instance method.
        return visitor.visitDynamicSend(node);
      } else if (!element.isInstanceMember) {
        // Example: A.f() or f() with 'f' bound to a static function.
        // Also includes new A() or new A.named() which is treated like a
        // static call to a factory.
        return visitor.visitStaticSend(node);
      } else {
        return visitor.internalError(node, "Cannot generate code for send");
      }
    }
  }

  internalError(Spannable node, String reason);

  R visitNode(Node node) {
    internalError(node, "Unhandled node");
    return null;
  }
}

abstract class NewResolvedVisitor<R> extends BaseResolvedVisitor<R>
    with SendResolverMixin,
         GetBulkMixin<R, dynamic>,
         SetBulkMixin<R, dynamic>,
         ErrorBulkMixin<R, dynamic>,
         InvokeBulkMixin<R, dynamic>,
         IndexSetBulkMixin<R, dynamic>,
         CompoundBulkMixin<R, dynamic>,
         UnaryBulkMixin<R, dynamic>,
         BaseBulkMixin<R, dynamic>,
         BinaryBulkMixin<R, dynamic>,
         PrefixBulkMixin<R, dynamic>,
         PostfixBulkMixin<R, dynamic>,
         NewBulkMixin<R, dynamic> {

  final ResolvedSemanticDispatcher<R> _semanticDispatcher =
      new ResolvedSemanticDispatcher<R>();

  final ResolvedSemanticDispatcher<ResolvedKind> _resolvedKindDispatcher =
      new ResolvedSemanticDispatcher<ResolvedKind>();

  NewResolvedVisitor(TreeElements elements) : super(elements);

  /// Dispatch using the new [SemanticSendVisitor] logic.
  _newDispatch(Send node,
               ResolvedKindVisitor kindVisitor,
               SemanticSendVisitor sendVisitor) {
    Element element = elements[node];
    if (element != null && element.isConstructor) {
      if (node.isSuperCall) {
        return kindVisitor.handleSuperConstructorInvoke(node);
      } else {
        return kindVisitor.visitStaticSend(node);
      }
    } else if (element != null && element.isPrefix) {
      return kindVisitor.visitGetterSend(node);
    } else if (!elements.isTypeLiteral(node) &&
               node.isPropertyAccess &&
               !Elements.isUnresolved(element) &&
               element.impliesType) {
      return kindVisitor.visitTypePrefixSend(node);
    } else {
      SendStructure sendStructure = computeSendStructure(node);
      if (sendStructure != null) {
        var arg = sendVisitor == _resolvedKindDispatcher
            ? kindVisitor : sendStructure;
        return sendStructure.dispatch(sendVisitor, node, arg);
      } else {
        return kindVisitor.visitStaticSend(node);
      }
    }
  }

  @override
  R visitDynamicSend(Send node) {
    return internalError(node, "visitDynamicSend is deprecated");
  }

  @override
  R visitSuperSend(Send node) {
    return internalError(node, "visitSuperSend is deprecated");
  }

  @override
  R visitOperatorSend(Send node) {
    return internalError(node, "visitOperaterSend is deprecated");
  }

  @override
  R visitClosureSend(Send node) {
    return internalError(node, "visitClosureSend is deprecated");
  }

  @override
  R visitTypeLiteralSend(Send node) {
    return internalError(node, "visitTypeLiteralSend is deprecated");
  }

  @override
  R visitTypePrefixSend(Send node) {
    return internalError(node, "visitTypePrefixSend is deprecated");
  }

  @override
  R visitAssertSend(Send node) {
    return internalError(node, "visitAssertSend is deprecated");
  }

  bool checkResolvedKind(Node node,
                         ResolvedKind oldKind,
                         ResolvedKind newKind) {
    return invariant(node, oldKind == newKind,
        message: 'old=$oldKind != new=$newKind');
  }

  ResolvedKind computeResolvedKindFromStructure(
      Node node, SemanticSendStructure structure) {
    return structure.dispatch(
        _resolvedKindDispatcher, node, const ResolvedKindComputer());
  }

  @override
  R visitSend(Send node) {
    assert(checkResolvedKind(
        node,
        _oldDispatch(node, const ResolvedKindComputer()),
        _newDispatch(node, const ResolvedKindComputer(),
            _resolvedKindDispatcher)));
    return _newDispatch(node, this, this);
  }

  @override
  R visitSendSet(Send node) {
    SendStructure structure = computeSendStructure(node);
    if (structure == null) {
      return internalError(node, 'No structure for $node');
    } else {
      assert(checkResolvedKind(node,
          ResolvedKind.SEND_SET,
          computeResolvedKindFromStructure(node, structure)));
      return structure.dispatch(this, node, structure);
    }
  }

  @override
  R visitNewExpression(NewExpression node) {
    NewStructure structure = computeNewStructure(node);
    if (structure == null) {
      return internalError(node, 'No structure for $node');
    } else {
      assert(checkResolvedKind(node,
          ResolvedKind.NEW,
          computeResolvedKindFromStructure(node, structure)));
      return structure.dispatch(this, node, structure);
    }
  }

  @override
  R apply(Node node, arg) {
    return visitNode(node);
  }

  @override
  R bulkHandleNode(
      Node node,
      String message,
      SemanticSendStructure structure) {
    return structure.dispatch(_semanticDispatcher, node, this);
  }
}

/// Visitor that dispatches [SemanticSendVisitor] calls to the corresponding
/// visit methods in [ResolvedVisitor].
class ResolvedSemanticDispatcher<R> extends Object
    with GetBulkMixin<R, ResolvedKindVisitor<R>>,
         SetBulkMixin<R, ResolvedKindVisitor<R>>,
         InvokeBulkMixin<R, ResolvedKindVisitor<R>>,
         PrefixBulkMixin<R, ResolvedKindVisitor<R>>,
         PostfixBulkMixin<R, ResolvedKindVisitor<R>>,
         SuperBulkMixin<R, ResolvedKindVisitor<R>>,
         CompoundBulkMixin<R, ResolvedKindVisitor<R>>,
         IndexSetBulkMixin<R, ResolvedKindVisitor<R>>,
         NewBulkMixin<R, ResolvedKindVisitor<R>>,
         ErrorBulkMixin<R, ResolvedKindVisitor<R>>
    implements SemanticSendVisitor<R, ResolvedKindVisitor<R>> {

  ResolvedSemanticDispatcher();

  @override
  R apply(Node node, ResolvedKindVisitor<R> visitor) {
    return visitor.internalError(
        node, "ResolvedSemanticDispatcher.apply unsupported.");
  }

  @override
  R bulkHandleNode(
      Node node,
      String message,
      ResolvedKindVisitor<R> visitor) {
    return bulkHandleError(node, visitor);
  }

  R bulkHandleError(Node node, ResolvedKindVisitor<R> visitor) {
    if (node.asSendSet() != null) {
      return visitor.handleSendSet(node);
    } else if (node.asNewExpression() != null) {
      return visitor.handleNewExpression(node);
    }
    return visitor.internalError(node, "No resolved kind for $node.");
  }

  @override
  R bulkHandleGet(Node node, ResolvedKindVisitor<R> visitor) {
    return visitor.visitGetterSend(node);
  }

  @override
  R bulkHandleInvoke(Node node, ResolvedKindVisitor<R> visitor) {
    // Most invokes are static.
    return visitor.visitStaticSend(node);
  }

  @override
  R bulkHandlePrefix(Node node, ResolvedKindVisitor<R> visitor) {
    return visitor.handleSendSet(node);
  }

  @override
  R bulkHandlePostfix(Node node, ResolvedKindVisitor<R> visitor) {
    return visitor.handleSendSet(node);
  }

  @override
  R bulkHandleSuper(Node node, ResolvedKindVisitor<R> visitor) {
    if (node.asSendSet() != null) {
      return visitor.handleSendSet(node);
    }
    return visitor.visitSuperSend(node);
  }

  @override
  R bulkHandleSet(SendSet node, ResolvedKindVisitor<R> visitor) {
    return visitor.handleSendSet(node);
  }

  @override
  R bulkHandleCompound(SendSet node, ResolvedKindVisitor<R> visitor) {
    return visitor.handleSendSet(node);
  }

  @override
  R bulkHandleIndexSet(SendSet node, ResolvedKindVisitor<R> visitor) {
    return visitor.handleSendSet(node);
  }

  @override
  R bulkHandleNew(NewExpression node, ResolvedKindVisitor<R> visitor) {
    return visitor.handleNewExpression(node);
  }

  @override
  R errorInvalidAssert(
      Send node,
      NodeList arguments,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitAssertSend(node);
  }

  @override
  R visitLocalFunctionPostfix(
      Send node,
      LocalFunctionElement function,
      op.IncDecOperator operator,
      ResolvedKindVisitor<R> visitor) {
    return visitor.handleSendSet(node);
  }

  @override
  R visitLocalFunctionPrefix(
      Send node,
      LocalFunctionElement function,
      op.IncDecOperator operator,
      ResolvedKindVisitor<R> visitor) {
    return visitor.handleSendSet(node);
  }

  @override
  R visitStaticSetterGet(
      Send node,
      FunctionElement setter,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitGetterSend(node);
  }

  @override
  R visitStaticSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitStaticSend(node);
  }

  @override
  R visitSuperSetterGet(
      Send node,
      FunctionElement setter,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitSuperSend(node);
  }

  @override
  R visitSuperSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitSuperSend(node);
  }

  @override
  R visitTopLevelSetterGet(
      Send node,
      FunctionElement setter,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitGetterSend(node);
  }

  @override
  R visitTopLevelSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitStaticSend(node);
  }

  @override
  R errorUndefinedBinaryExpression(
      Send node,
      Node left,
      Operator operator,
      Node right,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R errorUndefinedUnaryExpression(
      Send node,
      Operator operator,
      Node expression,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitUnresolvedGet(
      Send node,
      Element element,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitGetterSend(node);
  }

  @override
  R visitUnresolvedSuperGet(
      Send node,
      Element element,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitSuperSend(node);
  }

  @override
  R visitUnresolvedInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitStaticSend(node);
  }

  @override
  R visitUnresolvedPostfix(
      Send node,
      Element element,
      op.IncDecOperator operator,
      ResolvedKindVisitor<R> visitor) {
    return visitor.handleSendSet(node);
  }

  @override
  R visitUnresolvedPrefix(
      Send node,
      Element element,
      op.IncDecOperator operator,
      ResolvedKindVisitor<R> visitor) {
    return visitor.handleSendSet(node);
  }

  @override
  R visitAs(
      Send node,
      Node expression,
      DartType type,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitAssert(
      Send node,
      Node expression,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitAssertSend(node);
  }

  @override
  R visitBinary(
      Send node,
      Node left,
      op.BinaryOperator operator,
      Node right,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitEquals(
      Send node,
      Node left,
      Node right,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitIs(
      Send node,
      Node expression,
      DartType type,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitIsNot(
      Send node,
      Node expression,
      DartType type,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitIfNull(
      Send node,
      Node left,
      Node right,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitLogicalAnd(
      Send node,
      Node left,
      Node right,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitLogicalOr(
      Send node,
      Node left,
      Node right,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitNot(
      Send node,
      Node expression,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitNotEquals(
      Send node,
      Node left,
      Node right,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitUnary(
      Send node,
      op.UnaryOperator operator,
      Node expression,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitDynamicSend(node);
  }

  @override
  R visitIfNotNullDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitDynamicSend(node);
  }

  @override
  R visitThisPropertyInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitDynamicSend(node);
  }

  @override
  R visitExpressionInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitClosureSend(node);
  }

  @override
  R visitParameterInvoke(
      Send node,
      ParameterElement parameter,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitClosureSend(node);
  }

  @override
  R visitLocalVariableInvoke(
      Send node,
      LocalVariableElement variable,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitClosureSend(node);
  }

  @override
  R visitLocalFunctionInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitClosureSend(node);
  }

  @override
  R visitThisInvoke(
      Send node,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitClosureSend(node);
  }

  @override
  R visitClassTypeLiteralGet(
      Send node,
      ConstantExpression constant,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitTypeLiteralSend(node);
  }

  @override
  R visitTypedefTypeLiteralGet(
      Send node,
      ConstantExpression constant,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitTypeLiteralSend(node);
  }

  @override
  R visitDynamicTypeLiteralGet(
      Send node,
      ConstantExpression constant,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitTypeLiteralSend(node);
  }

  @override
  R visitTypeVariableTypeLiteralGet(
      Send node,
      TypeVariableElement element,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitTypeLiteralSend(node);
  }

  @override
  R visitClassTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitTypeLiteralSend(node);
  }

  @override
  R visitTypedefTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitTypeLiteralSend(node);
  }

  @override
  R visitDynamicTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitTypeLiteralSend(node);
  }

  @override
  R visitTypeVariableTypeLiteralInvoke(
      Send node,
      TypeVariableElement element,
      NodeList arguments,
      CallStructure callStructure,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitTypeLiteralSend(node);
  }

  @override
  R visitIndex(
      Send node,
      Node receiver,
      Node index,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitOperatorSend(node);
  }

  @override
  R visitSuperIndex(
      Send node,
      FunctionElement function,
      Node index,
      ResolvedKindVisitor<R> visitor) {
    return visitor.visitSuperSend(node);
  }
}
