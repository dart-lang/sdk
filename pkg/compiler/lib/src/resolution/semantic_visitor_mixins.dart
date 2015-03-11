// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.semantics_visitor;

/// Mixin that implements all `errorX` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `errorX` methods.
abstract class ErrorBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandleError(Send node) {
    return bulkHandleNode(node, "Error expression `$node` unhandled.");
  }

  @override
  R errorInvalidAssert(
      Send node,
      NodeList arguments,
      A arg) {
    bulkHandleError(node);
  }

  @override
  R errorClassTypeLiteralSet(
      SendSet node,
      TypeConstantExpression constant,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorDynamicTypeLiteralSet(
      SendSet node,
      TypeConstantExpression constant,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalLocalVariableCompound(
      Send node,
      LocalVariableElement
      variable,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalStaticFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalSuperFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorFinalTopLevelFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorLocalFunctionCompound(
      Send node,
      LocalFunctionElement function,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorLocalFunctionPostfix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorLocalFunctionPrefix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorLocalFunctionSet(
      SendSet node,
      LocalFunctionElement function,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorStaticFunctionSet(
      Send node,
      MethodElement function,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorStaticGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorStaticSetterGet(
      Send node,
      FunctionElement setter,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorStaticSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorSuperGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorSuperMethodSet(
      Send node,
      MethodElement method,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorSuperSetterGet(
      Send node,
      FunctionElement setter,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorSuperSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorTopLevelFunctionSet(
      Send node,
      MethodElement function,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorTopLevelGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorTopLevelSetterGet(
      Send node,
      FunctionElement setter,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorTopLevelSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorTypeVariableTypeLiteralSet(
      SendSet node,
      TypeVariableElement element,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorTypedefTypeLiteralSet(
      SendSet node,
      TypeConstantExpression constant,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedGet(
      Send node,
      Element element,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedPostfix(
      Send node,
      Element element,
      IncDecOperator operator,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedPrefix(
      Send node,
      Element element,
      IncDecOperator operator,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedSet(
      Send node,
      Element element,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedSuperCompoundIndexSet(
      Send node,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedSuperIndexSet(
      Send node,
      Element element,
      Node index,
      Node rhs,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedSuperBinary(
      Send node,
      Element element,
      BinaryOperator operator,
      Node argument,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUnresolvedSuperUnary(
      Send node,
      UnaryOperator operator,
      Element element,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUndefinedBinaryExpression(
      Send node,
      Node left,
      Operator operator,
      Node right,
      A arg) {
    return bulkHandleError(node);
  }

  @override
  R errorUndefinedUnaryExpression(
      Send node,
      Operator operator,
      Node expression,
      A arg) {
    return bulkHandleError(node);
  }
}

/// Mixin that implements all `visitXPrefix` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXPrefix`
/// methods.
abstract class PrefixBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandlePrefix(Send node) {
    return bulkHandleNode(node, "Prefix expression `$node` unhandled.");
  }

  @override
  R visitClassTypeLiteralPrefix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitDynamicPropertyPrefix(
      Send node,
      Node receiver,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitDynamicTypeLiteralPrefix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitLocalVariablePrefix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitParameterPrefix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitStaticFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitStaticGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitStaticMethodSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitSuperFieldFieldPrefix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitSuperFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitSuperFieldSetterPrefix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitSuperGetterFieldPrefix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitSuperGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitSuperMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitThisPropertyPrefix(
      Send node,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitTopLevelFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitTopLevelGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitTopLevelMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitTypeVariableTypeLiteralPrefix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }

  @override
  R visitTypedefTypeLiteralPrefix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node);
  }
}

/// Mixin that implements all `visitXPostfix` methods of [SemanticSendVisitor]
/// by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXPostfix`
/// methods.
abstract class PostfixBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandlePostfix(Send node) {
    return bulkHandleNode(node, "Postfix expression `$node` unhandled.");
  }

  @override
  R visitClassTypeLiteralPostfix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitDynamicPropertyPostfix(
      Send node,
      Node receiver,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitDynamicTypeLiteralPostfix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitLocalVariablePostfix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitParameterPostfix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitStaticFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitStaticGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitStaticMethodSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitSuperFieldFieldPostfix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitSuperFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitSuperFieldSetterPostfix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitSuperGetterFieldPostfix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitSuperGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitSuperMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitThisPropertyPostfix(
      Send node,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitTopLevelFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitTopLevelGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitTopLevelMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitTypeVariableTypeLiteralPostfix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }

  @override
  R visitTypedefTypeLiteralPostfix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node);
  }
}

/// Mixin that implements all `visitXCompound` methods of [SemanticSendVisitor]
/// by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `xCompound`
/// methods.
abstract class CompoundBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandleCompound(Send node) {
    return bulkHandleNode(node, "Compound assignment `$node` unhandled.");
  }

  @override
  R visitClassTypeLiteralCompound(
      Send node,
      TypeConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitDynamicPropertyCompound(
      Send node,
      Node receiver,
      AssignmentOperator operator,
      Node rhs,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitDynamicTypeLiteralCompound(
      Send node,
      TypeConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitStaticGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitStaticMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitSuperFieldSetterCompound(
      Send node,
      FieldElement field,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitSuperGetterFieldCompound(
      Send node,
      FunctionElement getter,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitSuperGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitSuperMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitThisPropertyCompound(
      Send node,
      AssignmentOperator operator,
      Node rhs,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitTopLevelGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitTopLevelMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitTypeVariableTypeLiteralCompound(
      Send node,
      TypeVariableElement element,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }

  @override
  R visitTypedefTypeLiteralCompound(
      Send node,
      TypeConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleCompound(node);
  }
}

/// Mixin that implements all `visitXInvoke` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXInvoke`
/// methods.
abstract class InvokeBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandleInvoke(Send node) {
    return bulkHandleNode(node, "Invocation `$node` unhandled.");
  }

  @override
  R visitClassTypeLiteralInvoke(
      Send node,
      TypeConstantExpression constant,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitDynamicTypeLiteralInvoke(
      Send node,
      TypeConstantExpression constant,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitExpressionInvoke(
      Send node,
      Node expression,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitLocalFunctionInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitLocalVariableInvoke(
      Send node,
      LocalVariableElement variable,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitParameterInvoke(
      Send node,
      ParameterElement parameter,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitStaticFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitStaticFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitStaticGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitSuperFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitSuperGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitThisInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitThisPropertyInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitTopLevelFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitTopLevelFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitTopLevelGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitTypeVariableTypeLiteralInvoke(
      Send node,
      TypeVariableElement element,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitTypedefTypeLiteralInvoke(
      Send node,
      TypeConstantExpression constant,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }

  @override
  R visitConstantInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleInvoke(node);
  }
}

/// Mixin that implements all `visitXGet` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXGet`
/// methods.
abstract class GetBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandleGet(Node node) {
    return bulkHandleNode(node, "Read `$node` unhandled.");
  }

  @override
  R visitClassTypeLiteralGet(
      Send node,
      TypeConstantExpression constant,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitDynamicPropertyGet(
      Send node,
      Node receiver,
      Selector selector,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitDynamicTypeLiteralGet(
      Send node,
      TypeConstantExpression constant,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitLocalFunctionGet(
      Send node,
      LocalFunctionElement function,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitLocalVariableGet(
      Send node,
      LocalVariableElement variable,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitParameterGet(
      Send node,
      ParameterElement parameter,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitStaticFieldGet(
      Send node,
      FieldElement field,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitStaticFunctionGet(
      Send node,
      MethodElement function,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitStaticGetterGet(
      Send node,
      FunctionElement getter,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitSuperFieldGet(
      Send node,
      FieldElement field,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitSuperGetterGet(
      Send node,
      FunctionElement getter,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitSuperMethodGet(
      Send node,
      MethodElement method,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitThisGet(Identifier node, A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitThisPropertyGet(
      Send node,
      Selector selector,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitTopLevelFieldGet(
      Send node,
      FieldElement field,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitTopLevelFunctionGet(
      Send node,
      MethodElement function,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitTopLevelGetterGet(
      Send node,
      FunctionElement getter,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitTypeVariableTypeLiteralGet(
      Send node,
      TypeVariableElement element,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitTypedefTypeLiteralGet(
      Send node,
      TypeConstantExpression constant,
      A arg) {
    return bulkHandleGet(node);
  }

  @override
  R visitConstantGet(
      Send node,
      TypeConstantExpression constant,
      A arg) {
    return bulkHandleGet(node);
  }
}

/// Mixin that implements all `visitXSet` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXSet`
/// methods.
abstract class SetBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandleSet(Send node) {
    return bulkHandleNode(node, "Assignment `$node` unhandled.");
  }

  @override
  R visitDynamicPropertySet(
      SendSet node,
      Node receiver,
      Selector selector,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }

  @override
  R visitLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }

  @override
  R visitParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }

  @override
  R visitStaticFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }

  @override
  R visitStaticSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }

  @override
  R visitSuperFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }

  @override
  R visitSuperSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }

  @override
  R visitThisPropertySet(
      SendSet node,
      Selector selector,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }

  @override
  R visitTopLevelFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }

  @override
  R visitTopLevelSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      A arg) {
    return bulkHandleSet(node);
  }
}

/// Mixin that implements all `visitXIndexSet` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXIndexSet`
/// methods.
abstract class IndexSetBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandleIndexSet(Send node) {
    return bulkHandleNode(node, "Index set expression `$node` unhandled.");
  }

  @override
  R visitCompoundIndexSet(
      Send node,
      Node receiver,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleIndexSet(node);
  }

  @override
  R visitIndexSet(
      Send node,
      Node receiver,
      Node index,
      Node rhs,
      A arg) {
    return bulkHandleIndexSet(node);
  }

  @override
  R visitSuperCompoundIndexSet(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleIndexSet(node);
  }

  @override
  R visitSuperIndexSet(
      Send node,
      FunctionElement function,
      Node index,
      Node rhs,
      A arg) {
    return bulkHandleIndexSet(node);
  }
}

/// Mixin that implements all binary visitor methods in [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all binary visitor
/// methods.
abstract class BinaryBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandleBinary(Send node) {
    return bulkHandleNode(node, "Binary expression `$node` unhandled.");
  }

  @override
  R visitBinary(
      Send node,
      Node left,
      BinaryOperator operator,
      Node right,
      A arg) {
    return bulkHandleBinary(node);
  }

  @override
  R visitEquals(
      Send node,
      Node left,
      Node right,
      A arg) {
    return bulkHandleBinary(node);
  }

  @override
  R visitNotEquals(
      Send node,
      Node left,
      Node right,
      A arg) {
    return bulkHandleBinary(node);
  }

  @override
  R visitSuperBinary(
      Send node,
      FunctionElement function,
      BinaryOperator operator,
      Node argument,
      A arg) {
    return bulkHandleBinary(node);
  }

  @override
  R visitSuperEquals(
      Send node,
      FunctionElement function,
      Node argument,
      A arg) {
    return bulkHandleBinary(node);
  }

  @override
  R visitSuperNotEquals(
      Send node,
      FunctionElement function,
      Node argument,
      A arg) {
    return bulkHandleBinary(node);
  }
}

/// Mixin that implements all unary visitor methods in [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all unary visitor
/// methods.
abstract class UnaryBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandleUnary(Send node) {
    return bulkHandleNode(node, "Unary expression `$node` unhandled.");
  }

  @override
  R visitNot(
      Send node,
      Node expression,
      A arg) {
    return bulkHandleUnary(node);
  }

  @override
  R visitSuperUnary(Send node, UnaryOperator operator,
                    FunctionElement function, A arg) {
    return bulkHandleUnary(node);
  }

  @override
  R visitUnary(
      Send node,
      UnaryOperator operator,
      Node expression,
      A arg) {
    return bulkHandleUnary(node);
  }
}

/// Mixin that implements all purely structural visitor methods in
/// [SemanticSendVisitor] by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all purely structural
/// visitor methods.
abstract class BaseBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  @override
  R visitAs(
      Send node,
      Node expression,
      DartType type,
      A arg) {
    return bulkHandleNode(node, 'As cast `$node` unhandled.');
  }

  @override
  R visitAssert(
      Send node,
      Node expression,
      A arg) {
    return bulkHandleNode(node, 'Assert `$node` unhandled.');
  }

  @override
  R visitIs(
      Send node,
      Node expression,
      DartType type,
      A arg) {
    return bulkHandleNode(node, 'Is test `$node` unhandled.');
  }

  @override
  R visitIsNot(
      Send node,
      Node expression,
      DartType type,
      A arg) {
    return bulkHandleNode(node, 'Is not test `$node` unhandled.');
  }

  @override
  R visitLogicalAnd(
      Send node,
      Node left,
      Node right,
      A arg) {
    return bulkHandleNode(node, 'Lazy and `$node` unhandled.');
  }

  @override
  R visitLogicalOr(
      Send node,
      Node left,
      Node right,
      A arg) {
    return bulkHandleNode(node, 'Lazy or `$node` unhandled.');
  }
}

/// Mixin that implements all visitor methods for `super` calls in
/// [SemanticSendVisitor] by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for `super` calls
/// visitor methods.
abstract class SuperBulkMixin<R, A> implements SemanticSendVisitor<R, A> {
  R bulkHandleNode(Node node, String message);

  R bulkHandleSuper(Send node) {
    return bulkHandleNode(node, "Super call `$node` unhandled.");
  }

  @override
  R visitSuperBinary(
      Send node,
      FunctionElement function,
      BinaryOperator operator,
      Node argument,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperCompoundIndexSet(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperEquals(
      Send node,
      FunctionElement function,
      Node argument,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldFieldPostfix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldFieldPrefix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldGet(
      Send node,
      FieldElement field,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldSetterCompound(
      Send node,
      FieldElement field,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldSetterPostfix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperFieldSetterPrefix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperGetterFieldCompound(
      Send node,
      FunctionElement getter,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperGetterFieldPostfix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperGetterFieldPrefix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperGetterGet(
      Send node,
      FunctionElement getter,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperIndexSet(
      Send node,
      FunctionElement function,
      Node index,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperMethodGet(
      Send node,
      MethodElement method,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperNotEquals(
      Send node,
      FunctionElement function,
      Node argument,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node);
  }

  @override
  R visitSuperUnary(
      Send node,
      UnaryOperator operator,
      FunctionElement function,
      A arg) {
    return bulkHandleSuper(node);
  }
}

/// Visitor that implements [SemanticSendVisitor] by the use of `BulkX` mixins.
///
/// This class is useful in itself, but shows how to use the `BulkX` mixins and
/// tests that the union of the `BulkX` mixins implement all `visit` and `error`
/// methods of [SemanticSendVisitor].
class BulkVisitor<R, A> extends SemanticSendVisitor<R, A>
    with GetBulkMixin<R, A>,
         SetBulkMixin<R, A>,
         ErrorBulkMixin<R, A>,
         InvokeBulkMixin<R, A>,
         IndexSetBulkMixin<R, A>,
         CompoundBulkMixin<R, A>,
         UnaryBulkMixin<R, A>,
         BaseBulkMixin<R, A>,
         BinaryBulkMixin<R, A>,
         PrefixBulkMixin<R, A>,
         PostfixBulkMixin<R, A> {

  @override
  R apply(Node node, A arg) {
    throw new UnimplementedError("BulkVisitor.apply unimplemented");
  }

  @override
  R bulkHandleNode(Node node, String message) {
    throw new UnimplementedError("BulkVisitor.bulkHandleNode unimplemented");
  }
}

/// [SemanticSendVisitor] that visits subnodes.
class TraversalMixin<R, A> implements SemanticSendVisitor<R, A> {
  @override
  R apply(Node node, A arg) {
    throw new UnimplementedError("TraversalMixin.apply unimplemented");
  }

  @override
  R errorInvalidAssert(
      Send node,
      NodeList arguments,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R errorClassTypeLiteralSet(
      SendSet node,
      TypeConstantExpression constant,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorDynamicTypeLiteralSet(
      SendSet node,
      TypeConstantExpression constant,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalStaticFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalSuperFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorFinalTopLevelFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorLocalFunctionCompound(
      Send node,
      LocalFunctionElement function,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorLocalFunctionPostfix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R errorLocalFunctionPrefix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R errorLocalFunctionSet(
      SendSet node,
      LocalFunctionElement function,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorStaticFunctionSet(
      Send node,
      MethodElement function,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorStaticGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorStaticSetterGet(
      Send node,
      FunctionElement setter,
      A arg) {
    return null;
  }

  @override
  R errorStaticSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R errorSuperGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorSuperMethodSet(
      Send node,
      MethodElement method,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorSuperSetterGet(
      Send node,
      FunctionElement setter,
      A arg) {
    return null;
  }

  @override
  R errorSuperSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R errorTopLevelFunctionSet(
      Send node,
      MethodElement function,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorTopLevelGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorTopLevelSetterGet(
      Send node,
      FunctionElement setter,
      A arg) {
    return null;
  }

  @override
  R errorTopLevelSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R errorTypeVariableTypeLiteralSet(
      SendSet node,
      TypeVariableElement element,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorTypedefTypeLiteralSet(
      SendSet node,
      TypeConstantExpression constant,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitAs(
      Send node,
      Node expression,
      DartType type,
      A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitAssert(
      Send node,
      Node expression,
      A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitBinary(
      Send node,
      Node left,
      BinaryOperator operator,
      Node right,
      A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitClassTypeLiteralCompound(
      Send node,
      TypeConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitClassTypeLiteralGet(
      Send node,
      TypeConstantExpression constant,
      A arg) {
    return null;
  }

  @override
  R visitClassTypeLiteralInvoke(
      Send node,
      TypeConstantExpression constant,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitClassTypeLiteralPostfix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitClassTypeLiteralPrefix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitCompoundIndexSet(
      Send node,
      Node receiver,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(receiver, arg);
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitConstantGet(
      Send node,
      ConstantExpression constant,
      A arg) {
    return null;
  }

  @override
  R visitConstantInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitDynamicPropertyCompound(
      Send node,
      Node receiver,
      AssignmentOperator operator,
      Node rhs,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    apply(receiver, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitDynamicPropertyGet(
      Send node,
      Node receiver,
      Selector selector,
      A arg) {
    apply(receiver, arg);
    return null;
  }

  @override
  R visitDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(receiver, arg);
    apply(arguments, arg);
    return null;
  }

  @override
  R visitDynamicPropertyPostfix(
      Send node,
      Node receiver,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    apply(receiver, arg);
    return null;
  }

  @override
  R visitDynamicPropertyPrefix(
      Send node,
      Node receiver,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    apply(receiver, arg);
    return null;
  }

  @override
  R visitDynamicPropertySet(
      SendSet node,
      Node receiver,
      Selector selector,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitDynamicTypeLiteralCompound(
      Send node,
      TypeConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitDynamicTypeLiteralGet(
      Send node,
      TypeConstantExpression constant,
      A arg) {
    return null;
  }

  @override
  R visitDynamicTypeLiteralInvoke(
      Send node,
      TypeConstantExpression constant,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitDynamicTypeLiteralPostfix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitDynamicTypeLiteralPrefix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitEquals(
      Send node,
      Node left,
      Node right,
      A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitExpressionInvoke(
      Send node,
      Node expression,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(expression, arg);
    apply(arguments, arg);
    return null;
  }

  @override
  R visitIndexSet(
      Send node,
      Node receiver,
      Node index,
      Node rhs,
      A arg) {
    apply(receiver, arg);
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitIs(
      Send node,
      Node expression,
      DartType type,
      A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitIsNot(
      Send node,
      Node expression,
      DartType type,
      A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitLocalFunctionGet(
      Send node,
      LocalFunctionElement function,
      A arg) {
    return null;
  }

  @override
  R visitLocalFunctionInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitLocalVariableGet(
      Send node,
      LocalVariableElement variable,
      A arg) {
    return null;
  }

  @override
  R visitLocalVariableInvoke(
      Send node,
      LocalVariableElement variable,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitLocalVariablePostfix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitLocalVariablePrefix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitLogicalAnd(
      Send node,
      Node left,
      Node right,
      A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitLogicalOr(
      Send node,
      Node left,
      Node right,
      A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitNot(
      Send node,
      Node expression,
      A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitNotEquals(
      Send node,
      Node left,
      Node right,
      A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitParameterGet(
      Send node,
      ParameterElement parameter,
      A arg) {
    return null;
  }

  @override
  R visitParameterInvoke(
      Send node,
      ParameterElement parameter,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitParameterPostfix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitParameterPrefix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticFieldGet(
      Send node,
      FieldElement field,
      A arg) {
    return null;
  }

  @override
  R visitStaticFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitStaticFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitStaticFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitStaticFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticFunctionGet(
      Send node,
      MethodElement function,
      A arg) {
    return null;
  }

  @override
  R visitStaticFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitStaticGetterGet(
      Send node,
      FunctionElement getter,
      A arg) {
    return null;
  }

  @override
  R visitStaticGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitStaticGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitStaticGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitStaticMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticMethodSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitStaticMethodSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitStaticSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperBinary(
      Send node,
      FunctionElement function,
      BinaryOperator operator,
      Node argument,
      A arg) {
    apply(argument, arg);
    return null;
  }

  @override
  R visitSuperCompoundIndexSet(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperEquals(
      Send node,
      FunctionElement function,
      Node argument,
      A arg) {
    apply(argument, arg);
    return null;
  }

  @override
  R visitSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperFieldFieldPostfix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperFieldFieldPrefix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperFieldGet(
      Send node,
      FieldElement field,
      A arg) {
    return null;
  }

  @override
  R visitSuperFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitSuperFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperFieldSetterCompound(
      Send node,
      FieldElement field,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperFieldSetterPostfix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperFieldSetterPrefix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperGetterFieldCompound(
      Send node,
      FunctionElement getter,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperGetterFieldPostfix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperGetterFieldPrefix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperGetterGet(
      Send node,
      FunctionElement getter,
      A arg) {
    return null;
  }

  @override
  R visitSuperGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitSuperGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperIndexSet(
      Send node,
      FunctionElement function,
      Node index,
      Node rhs,
      A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperMethodGet(
      Send node,
      MethodElement method,
      A arg) {
    return null;
  }

  @override
  R visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitSuperMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitSuperNotEquals(
      Send node,
      FunctionElement function,
      Node argument,
      A arg) {
    apply(argument, arg);
    return null;
  }

  @override
  R visitSuperSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperUnary(
      Send node,
      UnaryOperator operator,
      FunctionElement function,
      A arg) {
    return null;
  }

  @override
  R visitThisGet(Identifier node, A arg) {
    return null;
  }

  @override
  R visitThisInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitThisPropertyCompound(
      Send node,
      AssignmentOperator operator,
      Node rhs,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitThisPropertyGet(
      Send node,
      Selector selector,
      A arg) {
    return null;
  }

  @override
  R visitThisPropertyInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitThisPropertyPostfix(
      Send node,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    return null;
  }

  @override
  R visitThisPropertyPrefix(
      Send node,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      A arg) {
    return null;
  }

  @override
  R visitThisPropertySet(
      SendSet node,
      Selector selector,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelFieldGet(
      Send node,
      FieldElement field,
      A arg) {
    return null;
  }

  @override
  R visitTopLevelFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTopLevelFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitTopLevelFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitTopLevelFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelFunctionGet(
      Send node,
      MethodElement function,
      A arg) {
    return null;
  }

  @override
  R visitTopLevelFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTopLevelGetterGet(
      Send node,
      FunctionElement getter,
      A arg) {
    return null;
  }

  @override
  R visitTopLevelGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTopLevelGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitTopLevelGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitTopLevelMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitTopLevelMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitTopLevelSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralCompound(
      Send node,
      TypeVariableElement element,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralGet(
      Send node,
      TypeVariableElement element,
      A arg) {
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralInvoke(
      Send node,
      TypeVariableElement element,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralPostfix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralPrefix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitTypedefTypeLiteralCompound(
      Send node,
      TypeConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTypedefTypeLiteralGet(
      Send node,
      TypeConstantExpression constant,
      A arg) {
    return null;
  }

  @override
  R visitTypedefTypeLiteralInvoke(
      Send node,
      TypeConstantExpression constant,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTypedefTypeLiteralPostfix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitTypedefTypeLiteralPrefix(
      Send node,
      TypeConstantExpression constant,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R visitUnary(
      Send node,
      UnaryOperator operator,
      Node expression,
      A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R errorUnresolvedCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorUnresolvedGet(
      Send node,
      Element element,
      A arg) {
    return null;
  }

  @override
  R errorUnresolvedInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R errorUnresolvedPostfix(
      Send node,
      Element element,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R errorUnresolvedPrefix(
      Send node,
      Element element,
      IncDecOperator operator,
      A arg) {
    return null;
  }

  @override
  R errorUnresolvedSet(
      Send node,
      Element element,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorUndefinedBinaryExpression(
      Send node,
      Node left,
      Operator operator,
      Node right,
      A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R errorUndefinedUnaryExpression(
      Send node,
      Operator operator,
      Node expression,
      A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R errorUnresolvedSuperIndexSet(
      Send node,
      Element element,
      Node index,
      Node rhs,
      A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R errorUnresolvedSuperCompoundIndexSet(
      Send node,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R errorUnresolvedSuperBinary(
      Send node,
      Element element,
      BinaryOperator operator,
      Node argument,
      A arg) {
    apply(argument, arg);
    return null;
  }

  @override
  R errorUnresolvedSuperUnary(
      Send node,
      UnaryOperator operator,
      Element element,
      A arg) {
    return null;
  }
}

/// AST visitor that visits all normal [Send] and [SendSet] nodes using the
/// [SemanticVisitor].
class TraversalVisitor<R, A> extends SemanticVisitor<R, A>
    with TraversalMixin<R, A> {
  TraversalVisitor(TreeElements elements) : super(elements);

  SemanticSendVisitor<R, A> get sendVisitor => this;

  R apply(Node node, A arg) {
    node.accept(this);
    return null;
  }

  @override
  internalError(Spannable spannable, String message) {
    throw new SpannableAssertionFailure(spannable, message);
  }

  @override
  R visitNode(Node node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNewExpression(NewExpression node) {
    // Bypass the [Send] holding the class/constructor name.
    return apply(node.send.argumentsNode, null);
  }

  void visitParameters(NodeList parameters) {

  }

  void visitInitializers(NodeList initializers) {
    // TODO(johnniwinther): Visit subnodes of initializers.
  }

  @override
  R visitFunctionExpression(FunctionExpression node) {
    if (node.parameters != null) {
      visitParameters(node.parameters);
    }
    if (node.initializers != null) {
      visitInitializers(node.initializers);
    }
    if (node.body != null) {
      apply(node.body, null);
    }
    return null;
  }
}