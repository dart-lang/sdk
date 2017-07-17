// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.semantics_visitor;

/// Interface for bulk handling of a [Node] in a semantic visitor.
abstract class BulkHandle<R, A> {
  /// Handle [node] either regardless of semantics or to report that [node] is
  /// unhandled. [message] contains a message template for the latter case:
  /// Replace '#' in [message] by `node.toString()` to create a message for the
  /// error.
  R bulkHandleNode(Node node, String message, A arg);
}

/// Mixin that implements all `errorX` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `errorX` methods.
abstract class ErrorBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  // TODO(johnniwinther): Ensure that all error methods have an
  // [ErroneousElement].
  R bulkHandleError(Node node, ErroneousElement error, A arg) {
    return bulkHandleNode(node, "Error expression `#` unhandled.", arg);
  }

  @override
  R errorNonConstantConstructorInvoke(
      NewExpression node,
      Element element,
      ResolutionDartType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleError(node, null, arg);
  }

  @override
  R errorUndefinedUnaryExpression(
      Send node, Operator operator, Node expression, A arg) {
    return bulkHandleError(node, null, arg);
  }

  @override
  R errorUndefinedBinaryExpression(
      Send node, Node left, Operator operator, Node right, A arg) {
    return bulkHandleError(node, null, arg);
  }

  @override
  R errorInvalidCompound(Send node, ErroneousElement error,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidGet(Send node, ErroneousElement error, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidInvoke(Send node, ErroneousElement error, NodeList arguments,
      Selector selector, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidPostfix(
      Send node, ErroneousElement error, IncDecOperator operator, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidPrefix(
      Send node, ErroneousElement error, IncDecOperator operator, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidSet(Send node, ErroneousElement error, Node rhs, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidUnary(
      Send node, UnaryOperator operator, ErroneousElement error, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidEquals(Send node, ErroneousElement error, Node right, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidNotEquals(
      Send node, ErroneousElement error, Node right, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidBinary(Send node, ErroneousElement error,
      BinaryOperator operator, Node right, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidIndex(Send node, ErroneousElement error, Node index, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidIndexSet(
      Send node, ErroneousElement error, Node index, Node rhs, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidCompoundIndexSet(Send node, ErroneousElement error, Node index,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidIndexSetIfNull(
      SendSet node, ErroneousElement error, Node index, Node rhs, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidIndexPrefix(Send node, ErroneousElement error, Node index,
      IncDecOperator operator, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidIndexPostfix(Send node, ErroneousElement error, Node index,
      IncDecOperator operator, A arg) {
    return bulkHandleError(node, error, arg);
  }

  @override
  R errorInvalidSetIfNull(Send node, ErroneousElement error, Node rhs, A arg) {
    return bulkHandleError(node, error, arg);
  }
}

/// Mixin that implements all `visitXPrefix` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXPrefix`
/// methods.
abstract class PrefixBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandlePrefix(SendSet node, A arg) {
    return bulkHandleNode(node, "Prefix expression `#` unhandled.", arg);
  }

  @override
  R visitDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  R visitIfNotNullDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitIndexPrefix(
      Send node, Node receiver, Node index, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitLocalVariablePrefix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitStaticGetterSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitStaticMethodSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitSuperFieldFieldPrefix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitSuperFieldPrefix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitSuperFieldSetterPrefix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitSuperGetterFieldPrefix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitSuperGetterSetterPrefix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitSuperIndexPrefix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedSuperGetterIndexPrefix(SendSet node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedSuperSetterIndexPrefix(SendSet node, MethodElement getter,
      Element element, Node index, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedSuperIndexPrefix(
      Send node, Element element, Node index, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitSuperMethodSetterPrefix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitThisPropertyPrefix(
      Send node, Name name, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitTopLevelGetterSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitTopLevelMethodSetterPrefix(Send node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitClassTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitDynamicTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitLocalFunctionPrefix(Send node, LocalFunctionElement function,
      IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitTypeVariableTypeLiteralPrefix(
      Send node, TypeVariableElement element, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitTypedefTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedStaticGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedTopLevelGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedStaticSetterPrefix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedTopLevelSetterPrefix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitStaticMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitTopLevelMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedPrefix(
      Send node, ErroneousElement element, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitFinalLocalVariablePrefix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitFinalParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitFinalStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitFinalSuperFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitSuperMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitFinalTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedSuperPrefix(
      SendSet node, Element element, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedSuperGetterPrefix(SendSet node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }

  @override
  R visitUnresolvedSuperSetterPrefix(SendSet node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return bulkHandlePrefix(node, arg);
  }
}

/// Mixin that implements all `visitXPostfix` methods of [SemanticSendVisitor]
/// by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXPostfix`
/// methods.
abstract class PostfixBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandlePostfix(SendSet node, A arg) {
    return bulkHandleNode(node, "Postfix expression `#` unhandled.", arg);
  }

  @override
  R visitDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitIfNotNullDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  R visitIndexPostfix(
      Send node, Node receiver, Node index, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitLocalVariablePostfix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitStaticGetterSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitStaticMethodSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitSuperFieldFieldPostfix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitSuperFieldPostfix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitSuperFieldSetterPostfix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitSuperGetterFieldPostfix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitSuperGetterSetterPostfix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitSuperIndexPostfix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedSuperGetterIndexPostfix(SendSet node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedSuperSetterIndexPostfix(SendSet node, MethodElement getter,
      Element element, Node index, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedSuperIndexPostfix(
      Send node, Element element, Node index, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitSuperMethodSetterPostfix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitThisPropertyPostfix(
      Send node, Name name, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitTopLevelGetterSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitTopLevelMethodSetterPostfix(Send node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitClassTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitDynamicTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitLocalFunctionPostfix(Send node, LocalFunctionElement function,
      IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitTypeVariableTypeLiteralPostfix(
      Send node, TypeVariableElement element, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitTypedefTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedStaticGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedTopLevelGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedStaticSetterPostfix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedTopLevelSetterPostfix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitStaticMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  R visitToplevelMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedPostfix(
      Send node, ErroneousElement element, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitFinalLocalVariablePostfix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitFinalParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitFinalStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitFinalSuperFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitSuperMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitFinalTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitTopLevelMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedSuperPostfix(
      SendSet node, Element element, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedSuperGetterPostfix(SendSet node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }

  @override
  R visitUnresolvedSuperSetterPostfix(SendSet node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return bulkHandlePostfix(node, arg);
  }
}

/// Mixin that implements all `visitXCompound` methods of [SemanticSendVisitor]
/// by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `xCompound`
/// methods.
abstract class CompoundBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleCompound(SendSet node, A arg) {
    return bulkHandleNode(node, "Compound assignment `#` unhandled.", arg);
  }

  @override
  R visitDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitIfNotNullDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitStaticGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitStaticMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitSuperFieldSetterCompound(Send node, FieldElement field,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitSuperGetterFieldCompound(Send node, GetterElement getter,
      FieldElement field, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitSuperGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitSuperMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitThisPropertyCompound(
      Send node, Name name, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitTopLevelGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitTopLevelMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitFinalParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitClassTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitDynamicTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitFinalLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitFinalStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitFinalSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitFinalTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitLocalFunctionCompound(Send node, LocalFunctionElement function,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitTypeVariableTypeLiteralCompound(Send node, TypeVariableElement element,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitTypedefTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitUnresolvedStaticGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitUnresolvedTopLevelGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitUnresolvedStaticSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitUnresolvedTopLevelSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitStaticMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitTopLevelMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitUnresolvedCompound(Send node, ErroneousElement element,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitSuperFieldFieldCompound(Send node, FieldElement readField,
      FieldElement writtenField, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitSuperMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitUnresolvedSuperCompound(Send node, Element element,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitUnresolvedSuperGetterCompound(SendSet node, Element element,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }

  @override
  R visitUnresolvedSuperSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleCompound(node, arg);
  }
}

/// Mixin that implements all `visitXSetIfNull` methods of [SemanticSendVisitor]
/// by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `xSetIfNull`
/// methods.
abstract class SetIfNullBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleSetIfNull(SendSet node, A arg) {
    return bulkHandleNode(node, "If null assignment `#` unhandled.", arg);
  }

  @override
  R visitClassTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitDynamicTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitFinalLocalVariableSetIfNull(
      Send node, LocalVariableElement variable, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitFinalParameterSetIfNull(
      Send node, ParameterElement parameter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitFinalStaticFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitFinalSuperFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitFinalTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitIfNotNullDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitLocalFunctionSetIfNull(
      Send node, LocalFunctionElement function, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitLocalVariableSetIfNull(
      Send node, LocalVariableElement variable, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitParameterSetIfNull(
      Send node, ParameterElement parameter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitStaticFieldSetIfNull(Send node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitStaticGetterSetterSetIfNull(
      Send node, GetterElement getter, SetterElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitStaticMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitStaticMethodSetterSetIfNull(
      Send node, MethodElement method, MethodElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitSuperFieldFieldSetIfNull(Send node, FieldElement readField,
      FieldElement writtenField, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitSuperFieldSetIfNull(Send node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitSuperFieldSetterSetIfNull(
      Send node, FieldElement field, SetterElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitSuperGetterFieldSetIfNull(
      Send node, GetterElement getter, FieldElement field, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitSuperGetterSetterSetIfNull(
      Send node, GetterElement getter, SetterElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitSuperMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitSuperMethodSetterSetIfNull(Send node, FunctionElement method,
      SetterElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitThisPropertySetIfNull(Send node, Name name, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitTopLevelGetterSetterSetIfNull(
      Send node, GetterElement getter, SetterElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitTopLevelMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitTopLevelMethodSetterSetIfNull(Send node, FunctionElement method,
      SetterElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitTypeVariableTypeLiteralSetIfNull(
      Send node, TypeVariableElement element, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitTypedefTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedSetIfNull(Send node, Element element, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedStaticGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedStaticSetterSetIfNull(
      Send node, GetterElement getter, Element element, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedSuperGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedSuperSetIfNull(Send node, Element element, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedSuperSetterSetIfNull(
      Send node, GetterElement getter, Element element, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedTopLevelGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedTopLevelSetterSetIfNull(
      Send node, GetterElement getter, Element element, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitIndexSetIfNull(
      SendSet node, Node receiver, Node index, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitSuperIndexSetIfNull(SendSet node, MethodElement getter,
      MethodElement setter, Node index, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedSuperGetterIndexSetIfNull(SendSet node, Element element,
      MethodElement setter, Node index, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedSuperSetterIndexSetIfNull(SendSet node, MethodElement getter,
      Element element, Node index, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }

  @override
  R visitUnresolvedSuperIndexSetIfNull(
      Send node, Element element, Node index, Node rhs, A arg) {
    return bulkHandleSetIfNull(node, arg);
  }
}

/// Mixin that implements all `visitXInvoke` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXInvoke`
/// methods.
abstract class InvokeBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleInvoke(Send node, A arg) {
    return bulkHandleNode(node, "Invocation `#` unhandled.", arg);
  }

  @override
  R visitClassTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitIfNotNullDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitDynamicTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitExpressionInvoke(Send node, Node expression, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitLocalFunctionInvoke(Send node, LocalFunctionElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitLocalFunctionIncompatibleInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitLocalVariableInvoke(Send node, LocalVariableElement variable,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitParameterInvoke(Send node, ParameterElement parameter,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitStaticFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitStaticFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitStaticFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitStaticGetterInvoke(Send node, GetterElement getter, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitSuperFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitSuperGetterInvoke(Send node, GetterElement getter, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitSuperMethodInvoke(Send node, MethodElement method, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitSuperMethodIncompatibleInvoke(Send node, MethodElement method,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitThisInvoke(
      Send node, NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitThisPropertyInvoke(
      Send node, NodeList arguments, Selector selector, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitTopLevelFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitTopLevelFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitTopLevelFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitTopLevelGetterInvoke(Send node, GetterElement getter,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitTypeVariableTypeLiteralInvoke(Send node, TypeVariableElement element,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitTypedefTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitConstantInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitUnresolvedInvoke(Send node, Element element, NodeList arguments,
      Selector selector, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitUnresolvedSuperInvoke(Send node, Element function, NodeList arguments,
      Selector selector, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitStaticSetterInvoke(Send node, SetterElement setter, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitSuperSetterInvoke(Send node, SetterElement setter, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }

  @override
  R visitTopLevelSetterInvoke(Send node, SetterElement setter,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInvoke(node, arg);
  }
}

/// Mixin that implements all `visitXGet` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXGet`
/// methods.
abstract class GetBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleGet(Node node, A arg) {
    return bulkHandleNode(node, "Read `#` unhandled.", arg);
  }

  @override
  R visitClassTypeLiteralGet(Send node, ConstantExpression constant, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitDynamicPropertyGet(Send node, Node receiver, Name name, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitIfNotNullDynamicPropertyGet(
      Send node, Node receiver, Name name, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitDynamicTypeLiteralGet(Send node, ConstantExpression constant, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitLocalFunctionGet(Send node, LocalFunctionElement function, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitLocalVariableGet(Send node, LocalVariableElement variable, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitParameterGet(Send node, ParameterElement parameter, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitStaticFieldGet(Send node, FieldElement field, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitStaticFunctionGet(Send node, MethodElement function, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitStaticGetterGet(Send node, GetterElement getter, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitSuperFieldGet(Send node, FieldElement field, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitSuperGetterGet(Send node, GetterElement getter, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitSuperMethodGet(Send node, MethodElement method, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitThisGet(Identifier node, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitThisPropertyGet(Send node, Name name, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitTopLevelFieldGet(Send node, FieldElement field, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitTopLevelFunctionGet(Send node, MethodElement function, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitTopLevelGetterGet(Send node, GetterElement getter, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitTypeVariableTypeLiteralGet(
      Send node, TypeVariableElement element, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitTypedefTypeLiteralGet(Send node, ConstantExpression constant, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitConstantGet(Send node, ConstantExpression constant, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitUnresolvedGet(Send node, Element element, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitUnresolvedSuperGet(Send node, Element element, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitStaticSetterGet(Send node, SetterElement setter, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitSuperSetterGet(Send node, SetterElement setter, A arg) {
    return bulkHandleGet(node, arg);
  }

  @override
  R visitTopLevelSetterGet(Send node, SetterElement setter, A arg) {
    return bulkHandleGet(node, arg);
  }
}

/// Mixin that implements all `visitXSet` methods of [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXSet`
/// methods.
abstract class SetBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleSet(SendSet node, A arg) {
    return bulkHandleNode(node, "Assignment `#` unhandled.", arg);
  }

  @override
  R visitDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitIfNotNullDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitParameterSet(
      SendSet node, ParameterElement parameter, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitStaticFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitStaticSetterSet(SendSet node, SetterElement setter, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitSuperFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitSuperSetterSet(SendSet node, SetterElement setter, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitThisPropertySet(SendSet node, Name name, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitTopLevelFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitTopLevelSetterSet(
      SendSet node, SetterElement setter, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitClassTypeLiteralSet(
      SendSet node, TypeConstantExpression constant, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitDynamicTypeLiteralSet(
      SendSet node, TypeConstantExpression constant, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitFinalLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitFinalParameterSet(
      SendSet node, ParameterElement parameter, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitFinalStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitFinalSuperFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitFinalTopLevelFieldSet(
      SendSet node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitLocalFunctionSet(
      SendSet node, LocalFunctionElement function, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitStaticFunctionSet(
      SendSet node, MethodElement function, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitStaticGetterSet(SendSet node, GetterElement getter, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitSuperGetterSet(SendSet node, GetterElement getter, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitSuperMethodSet(SendSet node, MethodElement method, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitTopLevelFunctionSet(
      SendSet node, MethodElement function, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitTopLevelGetterSet(
      SendSet node, GetterElement getter, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitTypeVariableTypeLiteralSet(
      SendSet node, TypeVariableElement element, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitTypedefTypeLiteralSet(
      SendSet node, TypeConstantExpression constant, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitUnresolvedSet(SendSet node, Element element, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }

  @override
  R visitUnresolvedSuperSet(Send node, Element element, Node rhs, A arg) {
    return bulkHandleSet(node, arg);
  }
}

/// Mixin that implements all `visitXIndexSet` methods of [SemanticSendVisitor]
/// by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all `visitXIndexSet`
/// methods.
abstract class IndexSetBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleIndexSet(Send node, A arg) {
    return bulkHandleNode(node, "Index set expression `#` unhandled.", arg);
  }

  @override
  R visitCompoundIndexSet(SendSet node, Node receiver, Node index,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleIndexSet(node, arg);
  }

  @override
  R visitIndexSet(SendSet node, Node receiver, Node index, Node rhs, A arg) {
    return bulkHandleIndexSet(node, arg);
  }

  @override
  R visitSuperCompoundIndexSet(
      SendSet node,
      MethodElement getter,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleIndexSet(node, arg);
  }

  @override
  R visitUnresolvedSuperGetterCompoundIndexSet(
      SendSet node,
      Element element,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleIndexSet(node, arg);
  }

  @override
  R visitUnresolvedSuperSetterCompoundIndexSet(
      SendSet node,
      MethodElement getter,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleIndexSet(node, arg);
  }

  @override
  R visitUnresolvedSuperCompoundIndexSet(SendSet node, Element element,
      Node index, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleIndexSet(node, arg);
  }

  @override
  R visitSuperIndexSet(
      SendSet node, FunctionElement function, Node index, Node rhs, A arg) {
    return bulkHandleIndexSet(node, arg);
  }

  @override
  R visitUnresolvedSuperIndexSet(
      SendSet node, ErroneousElement element, Node index, Node rhs, A arg) {
    return bulkHandleIndexSet(node, arg);
  }
}

/// Mixin that implements all binary visitor methods in [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all binary visitor
/// methods.
abstract class BinaryBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleBinary(Send node, A arg) {
    return bulkHandleNode(node, "Binary expression `#` unhandled.", arg);
  }

  @override
  R visitBinary(
      Send node, Node left, BinaryOperator operator, Node right, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitEquals(Send node, Node left, Node right, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitNotEquals(Send node, Node left, Node right, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitIndex(Send node, Node receiver, Node index, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitSuperBinary(Send node, MethodElement function, BinaryOperator operator,
      Node argument, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitSuperEquals(Send node, MethodElement function, Node argument, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitSuperNotEquals(
      Send node, MethodElement function, Node argument, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitSuperIndex(Send node, MethodElement function, Node index, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitUnresolvedSuperBinary(Send node, Element function,
      BinaryOperator operator, Node argument, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitUnresolvedSuperInvoke(Send node, Element function, NodeList arguments,
      Selector selector, A arg) {
    return bulkHandleBinary(node, arg);
  }

  @override
  R visitUnresolvedSuperIndex(Send node, Element function, Node index, A arg) {
    return bulkHandleBinary(node, arg);
  }
}

/// Mixin that implements all unary visitor methods in [SemanticSendVisitor] by
/// delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all unary visitor
/// methods.
abstract class UnaryBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleUnary(Send node, A arg) {
    return bulkHandleNode(node, "Unary expression `#` unhandled.", arg);
  }

  @override
  R visitNot(Send node, Node expression, A arg) {
    return bulkHandleUnary(node, arg);
  }

  @override
  R visitSuperUnary(
      Send node, UnaryOperator operator, MethodElement function, A arg) {
    return bulkHandleUnary(node, arg);
  }

  @override
  R visitUnary(Send node, UnaryOperator operator, Node expression, A arg) {
    return bulkHandleUnary(node, arg);
  }

  @override
  R visitUnresolvedSuperUnary(
      Send node, UnaryOperator operator, Element function, A arg) {
    return bulkHandleUnary(node, arg);
  }
}

/// Mixin that implements all purely structural visitor methods in
/// [SemanticSendVisitor] by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for all purely structural
/// visitor methods.
abstract class BaseBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  @override
  R visitAs(Send node, Node expression, ResolutionDartType type, A arg) {
    return bulkHandleNode(node, 'As cast `#` unhandled.', arg);
  }

  @override
  R visitIs(Send node, Node expression, ResolutionDartType type, A arg) {
    return bulkHandleNode(node, 'Is test `#` unhandled.', arg);
  }

  @override
  R visitIsNot(Send node, Node expression, ResolutionDartType type, A arg) {
    return bulkHandleNode(node, 'Is not test `#` unhandled.', arg);
  }

  @override
  R visitIfNull(Send node, Node left, Node right, A arg) {
    return bulkHandleNode(node, 'If-null (Lazy ?? `#`) unhandled.', arg);
  }

  @override
  R visitLogicalAnd(Send node, Node left, Node right, A arg) {
    return bulkHandleNode(node, 'Lazy and `#` unhandled.', arg);
  }

  @override
  R visitLogicalOr(Send node, Node left, Node right, A arg) {
    return bulkHandleNode(node, 'Lazy or `#` unhandled.', arg);
  }

  @override
  void previsitDeferredAccess(Send node, PrefixElement prefix, A arg) {
    bulkHandleNode(node, 'Deferred access `#` unhandled.', arg);
  }
}

/// Mixin that implements all visitor methods for `super` calls in
/// [SemanticSendVisitor] by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for `super` calls
/// visitor methods.
abstract class SuperBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleSuper(Send node, A arg) {
    return bulkHandleNode(node, "Super call `#` unhandled.", arg);
  }

  @override
  R visitSuperBinary(Send node, MethodElement function, BinaryOperator operator,
      Node argument, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperCompoundIndexSet(
      SendSet node,
      MethodElement getter,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperEquals(Send node, MethodElement function, Node argument, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldFieldPostfix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldFieldPrefix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldGet(Send node, FieldElement field, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldPostfix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldPrefix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldSetterCompound(Send node, FieldElement field,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldSetterPostfix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperFieldSetterPrefix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperGetterFieldCompound(Send node, GetterElement getter,
      FieldElement field, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperGetterFieldPostfix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperGetterFieldPrefix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperGetterGet(Send node, GetterElement getter, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperGetterInvoke(Send node, GetterElement getter, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperGetterSetterPostfix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperGetterSetterPrefix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperIndexSet(
      SendSet node, FunctionElement function, Node index, Node rhs, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperMethodGet(Send node, MethodElement method, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperMethodInvoke(Send node, MethodElement method, NodeList arguments,
      CallStructure callStructure, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperMethodIncompatibleInvoke(Send node, MethodElement method,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperMethodSetterPostfix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperMethodSetterPrefix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperNotEquals(
      Send node, MethodElement function, Node argument, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperSetterSet(SendSet node, SetterElement setter, Node rhs, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitSuperUnary(
      Send node, UnaryOperator operator, MethodElement function, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitUnresolvedSuperBinary(Send node, Element element,
      BinaryOperator operator, Node argument, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitUnresolvedSuperGet(Send node, Element element, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitUnresolvedSuperSet(Send node, Element element, Node rhs, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitUnresolvedSuperInvoke(Send node, Element function, NodeList arguments,
      Selector selector, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitUnresolvedSuperIndex(Send node, Element function, Node index, A arg) {
    return bulkHandleSuper(node, arg);
  }

  @override
  R visitUnresolvedSuperUnary(
      Send node, UnaryOperator operator, Element element, A arg) {
    return bulkHandleSuper(node, arg);
  }
}

abstract class NewBulkMixin<R, A>
    implements SemanticSendVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleNew(NewExpression node, A arg) {
    return bulkHandleNode(node, "Constructor invocation `#` unhandled.", arg);
  }

  @override
  R visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement element,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitConstConstructorInvoke(
      NewExpression node, ConstructedConstantExpression constant, A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitBoolFromEnvironmentConstructorInvoke(NewExpression node,
      BoolFromEnvironmentConstantExpression constant, A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitIntFromEnvironmentConstructorInvoke(NewExpression node,
      IntFromEnvironmentConstantExpression constant, A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitStringFromEnvironmentConstructorInvoke(NewExpression node,
      StringFromEnvironmentConstantExpression constant, A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitConstructorIncompatibleInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      ConstructorElement effectiveTarget,
      ResolutionInterfaceType effectiveTargetType,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      ErroneousElement element,
      ResolutionDartType type,
      NodeList arguments,
      Selector selector,
      A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitUnresolvedConstructorInvoke(NewExpression node, Element constructor,
      ResolutionDartType type, NodeList arguments, Selector selector, A arg) {
    return bulkHandleNew(node, arg);
  }

  @override
  R visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleNew(node, arg);
  }
}

/// Visitor that implements [SemanticSendVisitor] by the use of `BulkX` mixins.
///
/// This class is useful in itself, but shows how to use the `BulkX` mixins and
/// tests that the union of the `BulkX` mixins implement all `visit` and `error`
/// methods of [SemanticSendVisitor].
class BulkSendVisitor<R, A> extends SemanticSendVisitor<R, A>
    with
        GetBulkMixin<R, A>,
        SetBulkMixin<R, A>,
        ErrorBulkMixin<R, A>,
        InvokeBulkMixin<R, A>,
        IndexSetBulkMixin<R, A>,
        CompoundBulkMixin<R, A>,
        SetIfNullBulkMixin<R, A>,
        UnaryBulkMixin<R, A>,
        BaseBulkMixin<R, A>,
        BinaryBulkMixin<R, A>,
        PrefixBulkMixin<R, A>,
        PostfixBulkMixin<R, A>,
        NewBulkMixin<R, A> {
  @override
  R apply(Node node, A arg) {
    throw new UnimplementedError("BulkSendVisitor.apply unimplemented");
  }

  @override
  R bulkHandleNode(Node node, String message, A arg) {
    throw new UnimplementedError(
        "BulkSendVisitor.bulkHandleNode unimplemented");
  }
}

/// Mixin that implements all `visitXParameterDecl` and
/// `visitXInitializingFormalDecl` methods of [SemanticDeclarationVisitor]
/// by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for these methods.
abstract class ParameterBulkMixin<R, A>
    implements SemanticDeclarationVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleParameterDeclaration(VariableDefinitions node, A arg) {
    return bulkHandleNode(node, "Parameter declaration `#` unhandled.", arg);
  }

  @override
  R visitInitializingFormalDeclaration(VariableDefinitions node,
      Node definition, InitializingFormalElement parameter, int index, A arg) {
    return bulkHandleParameterDeclaration(node, arg);
  }

  @override
  R visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      A arg) {
    return bulkHandleParameterDeclaration(node, arg);
  }

  @override
  R visitNamedParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, ConstantExpression defaultValue, A arg) {
    return bulkHandleParameterDeclaration(node, arg);
  }

  @override
  R visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      int index,
      A arg) {
    return bulkHandleParameterDeclaration(node, arg);
  }

  @override
  R visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      A arg) {
    return bulkHandleParameterDeclaration(node, arg);
  }

  @override
  R visitParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, int index, A arg) {
    return bulkHandleParameterDeclaration(node, arg);
  }
}

/// Mixin that implements all `visitXConstructorDecl` methods of
/// [SemanticDeclarationVisitor] by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for these methods.
abstract class ConstructorBulkMixin<R, A>
    implements SemanticDeclarationVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleConstructorDeclaration(FunctionExpression node, A arg) {
    return bulkHandleNode(node, "Constructor declaration `#` unhandled.", arg);
  }

  @override
  R visitFactoryConstructorDeclaration(FunctionExpression node,
      ConstructorElement constructor, NodeList parameters, Node body, A arg) {
    return bulkHandleConstructorDeclaration(node, arg);
  }

  @override
  R visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      A arg) {
    return bulkHandleConstructorDeclaration(node, arg);
  }

  @override
  R visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      ResolutionInterfaceType redirectionType,
      ConstructorElement redirectionTarget,
      A arg) {
    return bulkHandleConstructorDeclaration(node, arg);
  }

  @override
  R visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      A arg) {
    return bulkHandleConstructorDeclaration(node, arg);
  }
}

/// Mixin that implements all constructor initializer visitor methods of
/// [SemanticDeclarationVisitor] by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for these methods.
abstract class InitializerBulkMixin<R, A>
    implements SemanticDeclarationVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleInitializer(Node node, A arg) {
    return bulkHandleNode(node, "Initializer `#` unhandled.", arg);
  }

  @override
  R errorUnresolvedFieldInitializer(
      SendSet node, Element element, Node initializer, A arg) {
    return bulkHandleInitializer(node, arg);
  }

  @override
  R errorUnresolvedSuperConstructorInvoke(Send node, Element element,
      NodeList arguments, Selector selector, A arg) {
    return bulkHandleInitializer(node, arg);
  }

  @override
  R errorUnresolvedThisConstructorInvoke(Send node, Element element,
      NodeList arguments, Selector selector, A arg) {
    return bulkHandleInitializer(node, arg);
  }

  @override
  R visitFieldInitializer(
      SendSet node, FieldElement field, Node initializer, A arg) {
    return bulkHandleInitializer(node, arg);
  }

  @override
  R visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return bulkHandleInitializer(node, arg);
  }

  @override
  R visitImplicitSuperConstructorInvoke(
      FunctionExpression node,
      ConstructorElement superConstructor,
      ResolutionInterfaceType type,
      A arg) {
    return bulkHandleInitializer(node, arg);
  }

  @override
  R visitThisConstructorInvoke(Send node, ConstructorElement thisConstructor,
      NodeList arguments, CallStructure callStructure, A arg) {
    return bulkHandleInitializer(node, arg);
  }
}

/// Mixin that implements all function declaration visitor methods of
/// [SemanticDeclarationVisitor] by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for these methods.
abstract class FunctionBulkMixin<R, A>
    implements SemanticDeclarationVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleFunctionDeclaration(FunctionExpression node, A arg) {
    return bulkHandleNode(node, "Function declaration `#` unhandled.", arg);
  }

  @override
  R visitAbstractGetterDeclaration(
      FunctionExpression node, GetterElement getter, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitAbstractMethodDeclaration(FunctionExpression node,
      MethodElement method, NodeList parameters, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitAbstractSetterDeclaration(FunctionExpression node,
      MethodElement setter, NodeList parameters, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitClosureDeclaration(FunctionExpression node,
      LocalFunctionElement closure, NodeList parameters, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitInstanceGetterDeclaration(
      FunctionExpression node, GetterElement getter, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitInstanceMethodDeclaration(FunctionExpression node,
      MethodElement method, NodeList parameters, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitInstanceSetterDeclaration(FunctionExpression node,
      MethodElement setter, NodeList parameters, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitLocalFunctionDeclaration(FunctionExpression node,
      LocalFunctionElement function, NodeList parameters, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitStaticFunctionDeclaration(FunctionExpression node,
      MethodElement function, NodeList parameters, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitStaticGetterDeclaration(
      FunctionExpression node, GetterElement getter, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitStaticSetterDeclaration(FunctionExpression node, MethodElement setter,
      NodeList parameters, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitTopLevelFunctionDeclaration(FunctionExpression node,
      MethodElement function, NodeList parameters, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitTopLevelGetterDeclaration(
      FunctionExpression node, GetterElement getter, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }

  @override
  R visitTopLevelSetterDeclaration(FunctionExpression node,
      MethodElement setter, NodeList parameters, Node body, A arg) {
    return bulkHandleFunctionDeclaration(node, arg);
  }
}

/// Mixin that implements all variable/field declaration visitor methods of
/// [SemanticDeclarationVisitor] by delegating to a bulk handler.
///
/// Use this mixin to provide a trivial implementation for these methods.
abstract class VariableBulkMixin<R, A>
    implements SemanticDeclarationVisitor<R, A>, BulkHandle<R, A> {
  R bulkHandleVariableDeclaration(VariableDefinitions node, A arg) {
    return bulkHandleNode(node, "Variable declaration `#` unhandled.", arg);
  }

  @override
  R visitInstanceFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, A arg) {
    return bulkHandleVariableDeclaration(node, arg);
  }

  @override
  R visitLocalConstantDeclaration(VariableDefinitions node, Node definition,
      LocalVariableElement variable, ConstantExpression constant, A arg) {
    return bulkHandleVariableDeclaration(node, arg);
  }

  @override
  R visitLocalVariableDeclaration(VariableDefinitions node, Node definition,
      LocalVariableElement variable, Node initializer, A arg) {
    return bulkHandleVariableDeclaration(node, arg);
  }

  @override
  R visitStaticConstantDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, ConstantExpression constant, A arg) {
    return bulkHandleVariableDeclaration(node, arg);
  }

  @override
  R visitStaticFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, A arg) {
    return bulkHandleVariableDeclaration(node, arg);
  }

  @override
  R visitTopLevelConstantDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, ConstantExpression constant, A arg) {
    return bulkHandleVariableDeclaration(node, arg);
  }

  @override
  R visitTopLevelFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, A arg) {
    return bulkHandleVariableDeclaration(node, arg);
  }
}

/// Visitor that implements [SemanticDeclarationVisitor] by the use of `BulkX`
/// mixins.
///
/// This class is useful in itself, but shows how to use the `BulkX` mixins and
/// tests that the union of the `BulkX` mixins implement all `visit` and `error`
/// methods of [SemanticDeclarationVisitor].
class BulkDeclarationVisitor<R, A> extends SemanticDeclarationVisitor<R, A>
    with
        ConstructorBulkMixin<R, A>,
        FunctionBulkMixin<R, A>,
        VariableBulkMixin<R, A>,
        ParameterBulkMixin<R, A>,
        InitializerBulkMixin<R, A> {
  @override
  R apply(Node node, A arg) {
    throw new UnimplementedError("BulkDeclVisitor.apply unimplemented");
  }

  @override
  R bulkHandleNode(Node node, String message, A arg) {
    throw new UnimplementedError(
        "BulkDeclVisitor.bulkHandleNode unimplemented");
  }

  @override
  applyInitializers(FunctionExpression constructor, A arg) {
    throw new UnimplementedError(
        "BulkDeclVisitor.applyInitializers unimplemented");
  }

  @override
  applyParameters(NodeList parameters, A arg) {
    throw new UnimplementedError(
        "BulkDeclVisitor.applyParameters unimplemented");
  }
}

/// [SemanticSendVisitor] that visits subnodes.
class TraversalSendMixin<R, A> implements SemanticSendVisitor<R, A> {
  @override
  R apply(Node node, A arg) {
    throw new UnimplementedError("TraversalMixin.apply unimplemented");
  }

  @override
  void previsitDeferredAccess(Send node, PrefixElement prefix, A arg) {}

  @override
  R errorInvalidCompound(Send node, ErroneousElement error,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorInvalidGet(Send node, ErroneousElement error, A arg) {
    return null;
  }

  @override
  R errorInvalidInvoke(Send node, ErroneousElement error, NodeList arguments,
      Selector selector, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R errorInvalidPostfix(
      Send node, ErroneousElement error, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R errorInvalidPrefix(
      Send node, ErroneousElement error, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R errorInvalidSet(Send node, ErroneousElement error, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorInvalidUnary(
      Send node, UnaryOperator operator, ErroneousElement error, A arg) {
    return null;
  }

  @override
  R errorInvalidEquals(Send node, ErroneousElement error, Node right, A arg) {
    apply(right, arg);
    return null;
  }

  @override
  R errorInvalidNotEquals(
      Send node, ErroneousElement error, Node right, A arg) {
    apply(right, arg);
    return null;
  }

  @override
  R errorInvalidBinary(Send node, ErroneousElement error,
      BinaryOperator operator, Node right, A arg) {
    apply(right, arg);
    return null;
  }

  @override
  R errorInvalidIndex(Send node, ErroneousElement error, Node index, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R errorInvalidIndexSet(
      Send node, ErroneousElement error, Node index, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R errorInvalidCompoundIndexSet(Send node, ErroneousElement error, Node index,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R errorInvalidIndexPrefix(Send node, ErroneousElement error, Node index,
      IncDecOperator operator, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R errorInvalidIndexPostfix(Send node, ErroneousElement error, Node index,
      IncDecOperator operator, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitClassTypeLiteralSet(
      SendSet node, TypeConstantExpression constant, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitDynamicTypeLiteralSet(
      SendSet node, TypeConstantExpression constant, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalParameterSet(
      SendSet node, ParameterElement parameter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalSuperFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalTopLevelFieldSet(
      SendSet node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitLocalFunctionCompound(Send node, LocalFunctionElement function,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitLocalFunctionPostfix(Send node, LocalFunctionElement function,
      IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitLocalFunctionPrefix(Send node, LocalFunctionElement function,
      IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitLocalFunctionSet(
      SendSet node, LocalFunctionElement function, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticFunctionSet(
      SendSet node, MethodElement function, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticGetterSet(SendSet node, GetterElement getter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticSetterGet(Send node, SetterElement setter, A arg) {
    return null;
  }

  @override
  R visitStaticSetterInvoke(Send node, SetterElement setter, NodeList arguments,
      CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitSuperGetterSet(SendSet node, GetterElement getter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperMethodSet(SendSet node, MethodElement method, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperSetterGet(Send node, SetterElement setter, A arg) {
    return null;
  }

  @override
  R visitSuperSetterInvoke(Send node, SetterElement setter, NodeList arguments,
      CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTopLevelFunctionSet(
      SendSet node, MethodElement function, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelGetterSet(
      SendSet node, GetterElement getter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelSetterGet(Send node, SetterElement setter, A arg) {
    return null;
  }

  @override
  R visitTopLevelSetterInvoke(Send node, SetterElement setter,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralSet(
      SendSet node, TypeVariableElement element, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTypedefTypeLiteralSet(
      SendSet node, TypeConstantExpression constant, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperIndex(Send node, Element function, Node index, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperGet(Send node, Element element, A arg) {
    return null;
  }

  @override
  R visitUnresolvedSuperSet(Send node, Element element, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperInvoke(Send node, Element function, NodeList arguments,
      Selector selector, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitAs(Send node, Node expression, ResolutionDartType type, A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitBinary(
      Send node, Node left, BinaryOperator operator, Node right, A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitClassTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitClassTypeLiteralGet(Send node, ConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitClassTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitClassTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitClassTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitCompoundIndexSet(SendSet node, Node receiver, Node index,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(receiver, arg);
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitConstantGet(Send node, ConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitConstantInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(receiver, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitIfNotNullDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(receiver, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitDynamicPropertyGet(Send node, Node receiver, Name name, A arg) {
    apply(receiver, arg);
    return null;
  }

  @override
  R visitIfNotNullDynamicPropertyGet(
      Send node, Node receiver, Name name, A arg) {
    apply(receiver, arg);
    return null;
  }

  @override
  R visitDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, A arg) {
    apply(receiver, arg);
    apply(arguments, arg);
    return null;
  }

  @override
  R visitIfNotNullDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, A arg) {
    apply(receiver, arg);
    apply(arguments, arg);
    return null;
  }

  @override
  R visitDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    apply(receiver, arg);
    return null;
  }

  @override
  R visitIfNotNullDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    apply(receiver, arg);
    return null;
  }

  @override
  R visitDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    apply(receiver, arg);
    return null;
  }

  @override
  R visitIfNotNullDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    apply(receiver, arg);
    return null;
  }

  @override
  R visitDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, A arg) {
    apply(receiver, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitIfNotNullDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, A arg) {
    apply(receiver, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitDynamicTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitDynamicTypeLiteralGet(Send node, ConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitDynamicTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitDynamicTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitDynamicTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitEquals(Send node, Node left, Node right, A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitExpressionInvoke(Send node, Node expression, NodeList arguments,
      CallStructure callStructure, A arg) {
    apply(expression, arg);
    apply(arguments, arg);
    return null;
  }

  @override
  R visitIndex(Send node, Node receiver, Node index, A arg) {
    apply(receiver, arg);
    apply(index, arg);
    return null;
  }

  @override
  R visitIndexSet(SendSet node, Node receiver, Node index, Node rhs, A arg) {
    apply(receiver, arg);
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitIs(Send node, Node expression, ResolutionDartType type, A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitIsNot(Send node, Node expression, ResolutionDartType type, A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitLocalFunctionGet(Send node, LocalFunctionElement function, A arg) {
    return null;
  }

  @override
  R visitLocalFunctionInvoke(Send node, LocalFunctionElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitLocalFunctionIncompatibleInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitLocalVariableGet(Send node, LocalVariableElement variable, A arg) {
    return null;
  }

  @override
  R visitLocalVariableInvoke(Send node, LocalVariableElement variable,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitLocalVariablePostfix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitLocalVariablePrefix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitIfNull(Send node, Node left, Node right, A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitLogicalAnd(Send node, Node left, Node right, A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitLogicalOr(Send node, Node left, Node right, A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitNot(Send node, Node expression, A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitNotEquals(Send node, Node left, Node right, A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R visitParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitParameterGet(Send node, ParameterElement parameter, A arg) {
    return null;
  }

  @override
  R visitParameterInvoke(Send node, ParameterElement parameter,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitParameterSet(
      SendSet node, ParameterElement parameter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticFieldGet(Send node, FieldElement field, A arg) {
    return null;
  }

  @override
  R visitStaticFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitStaticFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticFunctionGet(Send node, MethodElement function, A arg) {
    return null;
  }

  @override
  R visitStaticFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitStaticFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitStaticGetterGet(Send node, GetterElement getter, A arg) {
    return null;
  }

  @override
  R visitStaticGetterInvoke(Send node, GetterElement getter, NodeList arguments,
      CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitStaticGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticGetterSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitStaticGetterSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitStaticMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticMethodSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitStaticMethodSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitStaticSetterSet(SendSet node, SetterElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperBinary(Send node, MethodElement function, BinaryOperator operator,
      Node argument, A arg) {
    apply(argument, arg);
    return null;
  }

  @override
  R visitSuperCompoundIndexSet(
      SendSet node,
      MethodElement getter,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperEquals(Send node, MethodElement function, Node argument, A arg) {
    apply(argument, arg);
    return null;
  }

  @override
  R visitSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperFieldFieldPostfix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperFieldFieldPrefix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperFieldGet(Send node, FieldElement field, A arg) {
    return null;
  }

  @override
  R visitSuperFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitSuperFieldPostfix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperFieldPrefix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperFieldSetterCompound(Send node, FieldElement field,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperFieldSetterPostfix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperFieldSetterPrefix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperGetterFieldCompound(Send node, GetterElement getter,
      FieldElement field, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperGetterFieldPostfix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperGetterFieldPrefix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperGetterGet(Send node, GetterElement getter, A arg) {
    return null;
  }

  @override
  R visitSuperGetterInvoke(Send node, GetterElement getter, NodeList arguments,
      CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitSuperGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperGetterSetterPostfix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperGetterSetterPrefix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperIndex(Send node, MethodElement function, Node index, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitSuperIndexSet(
      SendSet node, FunctionElement function, Node index, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperMethodGet(Send node, MethodElement method, A arg) {
    return null;
  }

  @override
  R visitSuperMethodInvoke(Send node, MethodElement method, NodeList arguments,
      CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitSuperMethodIncompatibleInvoke(Send node, MethodElement method,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitSuperMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperMethodSetterPostfix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperMethodSetterPrefix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperNotEquals(
      Send node, MethodElement function, Node argument, A arg) {
    apply(argument, arg);
    return null;
  }

  @override
  R visitSuperSetterSet(SendSet node, SetterElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperUnary(
      Send node, UnaryOperator operator, MethodElement function, A arg) {
    return null;
  }

  @override
  R visitThisGet(Identifier node, A arg) {
    return null;
  }

  @override
  R visitThisInvoke(
      Send node, NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitThisPropertyCompound(
      Send node, Name name, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitThisPropertyGet(Send node, Name name, A arg) {
    return null;
  }

  @override
  R visitThisPropertyInvoke(
      Send node, NodeList arguments, Selector selector, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitThisPropertyPostfix(
      Send node, Name name, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitThisPropertyPrefix(
      Send node, Name name, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitThisPropertySet(SendSet node, Name name, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelFieldGet(Send node, FieldElement field, A arg) {
    return null;
  }

  @override
  R visitTopLevelFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTopLevelFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelFunctionGet(Send node, MethodElement function, A arg) {
    return null;
  }

  @override
  R visitTopLevelFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTopLevelFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTopLevelGetterGet(Send node, GetterElement getter, A arg) {
    return null;
  }

  @override
  R visitTopLevelGetterInvoke(Send node, GetterElement getter,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTopLevelGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelGetterSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTopLevelGetterSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTopLevelMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelMethodSetterPostfix(Send node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTopLevelMethodSetterPrefix(Send node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTopLevelSetterSet(
      SendSet node, SetterElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralCompound(Send node, TypeVariableElement element,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralGet(
      Send node, TypeVariableElement element, A arg) {
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralInvoke(Send node, TypeVariableElement element,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralPostfix(
      Send node, TypeVariableElement element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralPrefix(
      Send node, TypeVariableElement element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTypedefTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTypedefTypeLiteralGet(Send node, ConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitTypedefTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTypedefTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTypedefTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnary(Send node, UnaryOperator operator, Node expression, A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitUnresolvedCompound(Send node, ErroneousElement element,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedGet(Send node, Element element, A arg) {
    return null;
  }

  @override
  R visitUnresolvedInvoke(Send node, Element element, NodeList arguments,
      Selector selector, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitUnresolvedPostfix(
      Send node, ErroneousElement element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedPrefix(
      Send node, ErroneousElement element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedSet(SendSet node, Element element, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R errorUndefinedBinaryExpression(
      Send node, Node left, Operator operator, Node right, A arg) {
    apply(left, arg);
    apply(right, arg);
    return null;
  }

  @override
  R errorUndefinedUnaryExpression(
      Send node, Operator operator, Node expression, A arg) {
    apply(expression, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperIndexSet(
      SendSet node, ErroneousElement element, Node index, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperGetterCompoundIndexSet(
      SendSet node,
      Element element,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperSetterCompoundIndexSet(
      SendSet node,
      MethodElement getter,
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
  R visitUnresolvedSuperCompoundIndexSet(SendSet node, Element element,
      Node index, AssignmentOperator operator, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperBinary(Send node, Element element,
      BinaryOperator operator, Node argument, A arg) {
    apply(argument, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperUnary(
      Send node, UnaryOperator operator, Element element, A arg) {
    return null;
  }

  @override
  R visitUnresolvedSuperGetterIndexPostfix(SendSet node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperSetterIndexPostfix(SendSet node, MethodElement getter,
      Element element, Node index, IncDecOperator operator, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperIndexPostfix(
      Send node, Element element, Node index, IncDecOperator operator, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperGetterIndexPrefix(SendSet node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperSetterIndexPrefix(SendSet node, MethodElement getter,
      Element element, Node index, IncDecOperator operator, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperIndexPrefix(
      Send node, Element element, Node index, IncDecOperator operator, A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitIndexPostfix(
      Send node, Node receiver, Node index, IncDecOperator operator, A arg) {
    apply(receiver, arg);
    apply(index, arg);
    return null;
  }

  @override
  R visitIndexPrefix(
      Send node, Node receiver, Node index, IncDecOperator operator, A arg) {
    apply(receiver, arg);
    apply(index, arg);
    return null;
  }

  @override
  R visitSuperIndexPostfix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R visitSuperIndexPrefix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    apply(index, arg);
    return null;
  }

  @override
  R errorInvalidSetIfNull(Send node, ErroneousElement error, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitClassTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, A arg) {
    apply(receiver, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitDynamicTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalLocalVariableSetIfNull(
      Send node, LocalVariableElement variable, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalParameterSetIfNull(
      Send node, ParameterElement parameter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalStaticFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalSuperFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitIfNotNullDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, A arg) {
    apply(receiver, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitLocalFunctionSetIfNull(
      Send node, LocalFunctionElement function, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitLocalVariableSetIfNull(
      Send node, LocalVariableElement variable, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitParameterSetIfNull(
      Send node, ParameterElement parameter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticFieldSetIfNull(Send node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticGetterSetterSetIfNull(
      Send node, GetterElement getter, SetterElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticMethodSetterSetIfNull(
      Send node, MethodElement method, MethodElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperFieldFieldSetIfNull(Send node, FieldElement readField,
      FieldElement writtenField, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperFieldSetIfNull(Send node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperFieldSetterSetIfNull(
      Send node, FieldElement field, SetterElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperGetterFieldSetIfNull(
      Send node, GetterElement getter, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperGetterSetterSetIfNull(
      Send node, GetterElement getter, SetterElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperMethodSetterSetIfNull(Send node, FunctionElement method,
      SetterElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitThisPropertySetIfNull(Send node, Name name, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelGetterSetterSetIfNull(
      Send node, GetterElement getter, SetterElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTopLevelMethodSetterSetIfNull(Send node, FunctionElement method,
      SetterElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTypeVariableTypeLiteralSetIfNull(
      Send node, TypeVariableElement element, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitTypedefTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSetIfNull(Send node, Element element, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedStaticGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedStaticSetterSetIfNull(
      Send node, GetterElement getter, Element element, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperSetIfNull(Send node, Element element, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperSetterSetIfNull(
      Send node, GetterElement getter, Element element, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedTopLevelGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedTopLevelSetterSetIfNull(
      Send node, GetterElement getter, Element element, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitConstConstructorInvoke(
      NewExpression node, ConstructedConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitBoolFromEnvironmentConstructorInvoke(NewExpression node,
      BoolFromEnvironmentConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitIntFromEnvironmentConstructorInvoke(NewExpression node,
      IntFromEnvironmentConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitStringFromEnvironmentConstructorInvoke(NewExpression node,
      StringFromEnvironmentConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitConstructorIncompatibleInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      ErroneousElement constructor,
      ResolutionDartType type,
      NodeList arguments,
      Selector selector,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitUnresolvedConstructorInvoke(NewExpression node, Element constructor,
      ResolutionDartType type, NodeList arguments, Selector selector, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      ConstructorElement effectiveTarget,
      ResolutionInterfaceType effectiveTargetType,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement element,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R errorNonConstantConstructorInvoke(
      NewExpression node,
      Element element,
      ResolutionDartType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitUnresolvedStaticGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedTopLevelGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedStaticSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedTopLevelSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitStaticMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedStaticGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedTopLevelGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedStaticSetterPrefix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedTopLevelSetterPrefix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitStaticMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTopLevelMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedStaticGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedTopLevelGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedStaticSetterPostfix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedTopLevelSetterPostfix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitStaticMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTopLevelMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitFinalLocalVariablePostfix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitFinalLocalVariablePrefix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitFinalParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitFinalParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitFinalStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitFinalStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperFieldFieldCompound(Send node, FieldElement readField,
      FieldElement writtenField, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitFinalSuperFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitFinalSuperFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitSuperMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitFinalTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitFinalTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitTopLevelMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperCompound(Send node, Element element,
      AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperPostfix(
      SendSet node, Element element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedSuperPrefix(
      SendSet node, Element element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedSuperGetterCompound(SendSet node, Element element,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperGetterPostfix(SendSet node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedSuperGetterPrefix(SendSet node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedSuperSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperSetterPostfix(SendSet node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitUnresolvedSuperSetterPrefix(SendSet node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return null;
  }

  @override
  R visitIndexSetIfNull(
      SendSet node, Node receiver, Node index, Node rhs, A arg) {
    apply(receiver, arg);
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitSuperIndexSetIfNull(SendSet node, MethodElement getter,
      MethodElement setter, Node index, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperGetterIndexSetIfNull(SendSet node, Element element,
      MethodElement setter, Node index, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperSetterIndexSetIfNull(SendSet node, MethodElement getter,
      Element element, Node index, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R visitUnresolvedSuperIndexSetIfNull(
      Send node, Element element, Node index, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }

  @override
  R errorInvalidIndexSetIfNull(
      SendSet node, ErroneousElement error, Node index, Node rhs, A arg) {
    apply(index, arg);
    apply(rhs, arg);
    return null;
  }
}

/// [SemanticDeclarationVisitor] that visits subnodes.
class TraversalDeclarationMixin<R, A>
    implements SemanticDeclarationVisitor<R, A> {
  @override
  R apply(Node node, A arg) {
    throw new UnimplementedError("TraversalMixin.apply unimplemented");
  }

  @override
  applyInitializers(FunctionExpression constructor, A arg) {
    throw new UnimplementedError(
        "TraversalMixin.applyInitializers unimplemented");
  }

  @override
  applyParameters(NodeList parameters, A arg) {
    throw new UnimplementedError(
        "TraversalMixin.applyParameters unimplemented");
  }

  @override
  R visitAbstractMethodDeclaration(FunctionExpression node,
      MethodElement method, NodeList parameters, A arg) {
    applyParameters(parameters, arg);
    return null;
  }

  @override
  R visitClosureDeclaration(FunctionExpression node,
      LocalFunctionElement function, NodeList parameters, Node body, A arg) {
    applyParameters(parameters, arg);
    apply(body, arg);
    return null;
  }

  @override
  R visitFactoryConstructorDeclaration(FunctionExpression node,
      ConstructorElement constructor, NodeList parameters, Node body, A arg) {
    applyParameters(parameters, arg);
    apply(body, arg);
    return null;
  }

  @override
  R visitFieldInitializer(
      SendSet node, FieldElement field, Node initializer, A arg) {
    apply(initializer, arg);
    return null;
  }

  @override
  R visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      A arg) {
    applyParameters(parameters, arg);
    applyInitializers(node, arg);
    apply(body, arg);
    return null;
  }

  @override
  R visitInstanceMethodDeclaration(FunctionExpression node,
      MethodElement method, NodeList parameters, Node body, A arg) {
    applyParameters(parameters, arg);
    apply(body, arg);
    return null;
  }

  @override
  R visitLocalFunctionDeclaration(FunctionExpression node,
      LocalFunctionElement function, NodeList parameters, Node body, A arg) {
    applyParameters(parameters, arg);
    apply(body, arg);
    return null;
  }

  @override
  R visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      ResolutionInterfaceType redirectionType,
      ConstructorElement redirectionTarget,
      A arg) {
    applyParameters(parameters, arg);
    return null;
  }

  @override
  R visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      A arg) {
    applyParameters(parameters, arg);
    applyInitializers(node, arg);
    return null;
  }

  @override
  R visitStaticFunctionDeclaration(FunctionExpression node,
      MethodElement function, NodeList parameters, Node body, A arg) {
    applyParameters(parameters, arg);
    apply(body, arg);
    return null;
  }

  @override
  R visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitImplicitSuperConstructorInvoke(
      FunctionExpression node,
      ConstructorElement superConstructor,
      ResolutionInterfaceType type,
      A arg) {
    return null;
  }

  @override
  R visitThisConstructorInvoke(Send node, ConstructorElement thisConstructor,
      NodeList arguments, CallStructure callStructure, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitTopLevelFunctionDeclaration(FunctionExpression node,
      MethodElement function, NodeList parameters, Node body, A arg) {
    applyParameters(parameters, arg);
    apply(body, arg);
    return null;
  }

  @override
  R errorUnresolvedFieldInitializer(
      SendSet node, Element element, Node initializer, A arg) {
    apply(initializer, arg);
    return null;
  }

  @override
  R errorUnresolvedSuperConstructorInvoke(Send node, Element element,
      NodeList arguments, Selector selector, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R errorUnresolvedThisConstructorInvoke(Send node, Element element,
      NodeList arguments, Selector selector, A arg) {
    apply(arguments, arg);
    return null;
  }

  @override
  R visitLocalVariableDeclaration(VariableDefinitions node, Node definition,
      LocalVariableElement variable, Node initializer, A arg) {
    if (initializer != null) {
      apply(initializer, arg);
    }
    return null;
  }

  @override
  R visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      A arg) {
    return null;
  }

  @override
  R visitParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, int index, A arg) {
    return null;
  }

  @override
  R visitInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement initializingFormal,
      int index,
      A arg) {
    return null;
  }

  @override
  R visitLocalConstantDeclaration(VariableDefinitions node, Node definition,
      LocalVariableElement variable, ConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement initializingFormal,
      ConstantExpression defaultValue,
      A arg) {
    return null;
  }

  @override
  R visitNamedParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, ConstantExpression defaultValue, A arg) {
    return null;
  }

  @override
  R visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement initializingFormal,
      ConstantExpression defaultValue,
      int index,
      A arg) {
    return null;
  }

  @override
  R visitInstanceFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, A arg) {
    if (initializer != null) {
      apply(initializer, arg);
    }
    return null;
  }

  @override
  R visitStaticConstantDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, ConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitStaticFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, A arg) {
    if (initializer != null) {
      apply(initializer, arg);
    }
    return null;
  }

  @override
  R visitTopLevelConstantDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, ConstantExpression constant, A arg) {
    return null;
  }

  @override
  R visitTopLevelFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, A arg) {
    if (initializer != null) {
      apply(initializer, arg);
    }
    return null;
  }

  @override
  R visitAbstractGetterDeclaration(
      FunctionExpression node, GetterElement getter, A arg) {
    return null;
  }

  @override
  R visitAbstractSetterDeclaration(FunctionExpression node,
      MethodElement setter, NodeList parameters, A arg) {
    applyParameters(parameters, arg);
    return null;
  }

  @override
  R visitInstanceGetterDeclaration(
      FunctionExpression node, GetterElement getter, Node body, A arg) {
    apply(body, arg);
    return null;
  }

  @override
  R visitInstanceSetterDeclaration(FunctionExpression node,
      MethodElement setter, NodeList parameters, Node body, A arg) {
    applyParameters(parameters, arg);
    apply(body, arg);
    return null;
  }

  @override
  R visitStaticGetterDeclaration(
      FunctionExpression node, GetterElement getter, Node body, A arg) {
    apply(body, arg);
    return null;
  }

  @override
  R visitStaticSetterDeclaration(FunctionExpression node, MethodElement setter,
      NodeList parameters, Node body, A arg) {
    applyParameters(parameters, arg);
    apply(body, arg);
    return null;
  }

  @override
  R visitTopLevelGetterDeclaration(
      FunctionExpression node, GetterElement getter, Node body, A arg) {
    apply(body, arg);
    return null;
  }

  @override
  R visitTopLevelSetterDeclaration(FunctionExpression node,
      MethodElement setter, NodeList parameters, Node body, A arg) {
    applyParameters(parameters, arg);
    apply(body, arg);
    return null;
  }
}

/// AST visitor that visits all normal [Send] and [SendSet] nodes using the
/// [SemanticVisitor].
class TraversalVisitor<R, A> extends SemanticVisitor<R, A>
    with TraversalSendMixin<R, A>, TraversalDeclarationMixin<R, A> {
  TraversalVisitor(TreeElements elements) : super(elements);

  SemanticSendVisitor<R, A> get sendVisitor => this;

  SemanticDeclarationVisitor<R, A> get declVisitor => this;

  R apply(Node node, A arg) {
    node.accept(this);
    return null;
  }

  @override
  applyInitializers(FunctionExpression constructor, A arg) {
    visitInitializers(constructor, arg);
  }

  @override
  applyParameters(NodeList parameters, A arg) {
    visitParameters(parameters, arg);
  }

  @override
  internalError(Spannable spannable, String message) {
    failedAt(spannable, message);
  }

  @override
  R visitNode(Node node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTypeAnnotation(TypeAnnotation node) {
    // Skip [Send] contained in type annotations, like `prefix.Type`.
    return null;
  }
}

/// Mixin that groups all non-compound `visitStaticX` and `visitTopLevelX`
/// method by delegating calls to `handleStaticX` methods.
///
/// This mixin is useful for the cases where both top level members and static
/// class members are handled uniformly.
abstract class BaseImplementationOfStaticsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  R handleStaticFieldGet(Send node, FieldElement field, A arg);

  R handleStaticFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg);

  R handleStaticFieldSet(SendSet node, FieldElement field, Node rhs, A arg);

  R handleStaticFunctionGet(Send node, MethodElement function, A arg);

  R handleStaticFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg);

  R handleStaticFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg);

  R handleStaticGetterGet(Send node, GetterElement getter, A arg);

  R handleStaticGetterSet(SendSet node, GetterElement getter, Node rhs, A arg);

  R handleStaticGetterInvoke(Send node, GetterElement getter,
      NodeList arguments, CallStructure callStructure, A arg);

  R handleStaticSetterGet(SendSet node, SetterElement setter, A arg);

  R handleStaticSetterSet(SendSet node, SetterElement setter, Node rhs, A arg);

  R handleStaticSetterInvoke(Send node, SetterElement setter,
      NodeList arguments, CallStructure callStructure, A arg);

  R handleFinalStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, A arg);

  R handleStaticFunctionSet(
      SendSet node, MethodElement function, Node rhs, A arg);

  @override
  R visitStaticFieldGet(Send node, FieldElement field, A arg) {
    return handleStaticFieldGet(node, field, arg);
  }

  @override
  R visitStaticFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg) {
    return handleStaticFieldInvoke(node, field, arguments, callStructure, arg);
  }

  @override
  R visitStaticFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    return handleStaticFieldSet(node, field, rhs, arg);
  }

  @override
  R visitStaticFunctionGet(Send node, MethodElement function, A arg) {
    return handleStaticFunctionGet(node, function, arg);
  }

  @override
  R visitStaticFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleStaticFunctionInvoke(
        node, function, arguments, callStructure, arg);
  }

  @override
  R visitStaticFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleStaticFunctionIncompatibleInvoke(
        node, function, arguments, callStructure, arg);
  }

  @override
  R visitStaticGetterGet(Send node, GetterElement getter, A arg) {
    return handleStaticGetterGet(node, getter, arg);
  }

  @override
  R visitStaticGetterInvoke(Send node, GetterElement getter, NodeList arguments,
      CallStructure callStructure, A arg) {
    return handleStaticGetterInvoke(
        node, getter, arguments, callStructure, arg);
  }

  @override
  R visitStaticSetterSet(SendSet node, SetterElement setter, Node rhs, A arg) {
    return handleStaticSetterSet(node, setter, rhs, arg);
  }

  @override
  R visitTopLevelFieldGet(Send node, FieldElement field, A arg) {
    return handleStaticFieldGet(node, field, arg);
  }

  @override
  R visitTopLevelFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, A arg) {
    return handleStaticFieldInvoke(node, field, arguments, callStructure, arg);
  }

  @override
  R visitTopLevelFieldSet(SendSet node, FieldElement field, Node rhs, A arg) {
    return handleStaticFieldSet(node, field, rhs, arg);
  }

  @override
  R visitTopLevelFunctionGet(Send node, MethodElement function, A arg) {
    return handleStaticFunctionGet(node, function, arg);
  }

  @override
  R visitTopLevelFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleStaticFunctionInvoke(
        node, function, arguments, callStructure, arg);
  }

  @override
  R visitTopLevelFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleStaticFunctionIncompatibleInvoke(
        node, function, arguments, callStructure, arg);
  }

  @override
  R visitTopLevelGetterGet(Send node, GetterElement getter, A arg) {
    return handleStaticGetterGet(node, getter, arg);
  }

  @override
  R visitTopLevelGetterSet(
      SendSet node, GetterElement getter, Node rhs, A arg) {
    return handleStaticGetterSet(node, getter, rhs, arg);
  }

  @override
  R visitTopLevelGetterInvoke(Send node, GetterElement getter,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleStaticGetterInvoke(
        node, getter, arguments, callStructure, arg);
  }

  @override
  R visitTopLevelSetterSet(
      SendSet node, SetterElement setter, Node rhs, A arg) {
    return handleStaticSetterSet(node, setter, rhs, arg);
  }

  @override
  R visitStaticSetterInvoke(Send node, SetterElement setter, NodeList arguments,
      CallStructure callStructure, A arg) {
    return handleStaticSetterInvoke(
        node, setter, arguments, callStructure, arg);
  }

  @override
  R visitTopLevelSetterInvoke(Send node, SetterElement setter,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleStaticSetterInvoke(
        node, setter, arguments, callStructure, arg);
  }

  @override
  R visitStaticSetterGet(Send node, SetterElement setter, A arg) {
    return handleStaticSetterGet(node, setter, arg);
  }

  @override
  R visitStaticGetterSet(SendSet node, GetterElement getter, Node rhs, A arg) {
    return handleStaticGetterSet(node, getter, rhs, arg);
  }

  @override
  R visitTopLevelSetterGet(Send node, SetterElement setter, A arg) {
    return handleStaticSetterGet(node, setter, arg);
  }

  @override
  R visitFinalStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, A arg) {
    return handleFinalStaticFieldSet(node, field, rhs, arg);
  }

  @override
  R visitFinalTopLevelFieldSet(
      SendSet node, FieldElement field, Node rhs, A arg) {
    return handleFinalStaticFieldSet(node, field, rhs, arg);
  }

  @override
  R visitStaticFunctionSet(
      SendSet node, MethodElement function, Node rhs, A arg) {
    return handleStaticFunctionSet(node, function, rhs, arg);
  }

  @override
  R visitTopLevelFunctionSet(
      SendSet node, MethodElement function, Node rhs, A arg) {
    return handleStaticFunctionSet(node, function, rhs, arg);
  }
}

/// Mixin that groups all compounds visitors `visitStaticX` and `visitTopLevelX`
/// method by delegating calls to `handleStaticX` methods.
///
/// This mixin is useful for the cases where both top level members and static
/// class members are handled uniformly.
abstract class BaseImplementationOfStaticCompoundsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  R handleStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg);

  R handleStaticFieldPostfixPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleStaticGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg);

  R handleStaticGetterSetterPostfixPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleStaticMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg);

  R handleStaticMethodSetterPostfixPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleFinalStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg);

  R handleFinalStaticFieldPostfixPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleStaticMethodCompound(Send node, FunctionElement method,
      AssignmentOperator operator, Node rhs, A arg);

  R handleStaticMethodPostfixPrefix(
      Send node, FunctionElement method, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleUnresolvedStaticGetterCompound(Send node, Element element,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg);

  R handleUnresolvedStaticGetterPostfixPrefix(Send node, Element element,
      SetterElement setter, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleUnresolvedStaticSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg);

  R handleUnresolvedStaticSetterPostfixPrefix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg,
      {bool isPrefix});

  @override
  R visitStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticFieldCompound(node, field, operator, rhs, arg);
  }

  @override
  R visitStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticFieldPostfixPrefix(node, field, operator, arg,
        isPrefix: false);
  }

  @override
  R visitStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticFieldPostfixPrefix(node, field, operator, arg,
        isPrefix: true);
  }

  @override
  R visitStaticGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticGetterSetterCompound(
        node, getter, setter, operator, rhs, arg);
  }

  @override
  R visitStaticGetterSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticGetterSetterPostfixPrefix(
        node, getter, setter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitStaticGetterSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticGetterSetterPostfixPrefix(
        node, getter, setter, operator, arg,
        isPrefix: true);
  }

  @override
  R visitStaticMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticMethodSetterCompound(
        node, method, setter, operator, rhs, arg);
  }

  @override
  R visitStaticMethodSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticMethodSetterPostfixPrefix(
        node, getter, setter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitStaticMethodSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticMethodSetterPostfixPrefix(
        node, getter, setter, operator, arg,
        isPrefix: true);
  }

  @override
  R visitTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticFieldCompound(node, field, operator, rhs, arg);
  }

  @override
  R visitTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticFieldPostfixPrefix(node, field, operator, arg,
        isPrefix: false);
  }

  @override
  R visitTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticFieldPostfixPrefix(node, field, operator, arg,
        isPrefix: true);
  }

  @override
  R visitTopLevelGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticGetterSetterCompound(
        node, getter, setter, operator, rhs, arg);
  }

  @override
  R visitTopLevelGetterSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticGetterSetterPostfixPrefix(
        node, getter, setter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitTopLevelGetterSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticGetterSetterPostfixPrefix(
        node, getter, setter, operator, arg,
        isPrefix: true);
  }

  @override
  R visitTopLevelMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticMethodSetterCompound(
        node, method, setter, operator, rhs, arg);
  }

  @override
  R visitTopLevelMethodSetterPostfix(Send node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticMethodSetterPostfixPrefix(
        node, method, setter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitTopLevelMethodSetterPrefix(Send node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticMethodSetterPostfixPrefix(
        node, method, setter, operator, arg,
        isPrefix: true);
  }

  @override
  R visitFinalStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleFinalStaticFieldCompound(node, field, operator, rhs, arg);
  }

  @override
  R visitFinalStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleFinalStaticFieldPostfixPrefix(node, field, operator, arg,
        isPrefix: false);
  }

  @override
  R visitFinalStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleFinalStaticFieldPostfixPrefix(node, field, operator, arg,
        isPrefix: true);
  }

  @override
  R visitStaticMethodCompound(Send node, FunctionElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticMethodCompound(node, method, operator, rhs, arg);
  }

  @override
  R visitStaticMethodPostfix(
      Send node, FunctionElement method, IncDecOperator operator, A arg) {
    return handleStaticMethodPostfixPrefix(node, method, operator, arg,
        isPrefix: false);
  }

  @override
  R visitStaticMethodPrefix(
      Send node, FunctionElement method, IncDecOperator operator, A arg) {
    return handleStaticMethodPostfixPrefix(node, method, operator, arg,
        isPrefix: true);
  }

  @override
  R visitUnresolvedStaticGetterCompound(Send node, Element element,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleUnresolvedStaticGetterCompound(
        node, element, setter, operator, rhs, arg);
  }

  @override
  R visitUnresolvedStaticGetterPostfix(Send node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleUnresolvedStaticGetterPostfixPrefix(
        node, element, setter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitUnresolvedStaticGetterPrefix(Send node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleUnresolvedStaticGetterPostfixPrefix(
        node, element, setter, operator, arg,
        isPrefix: true);
  }

  @override
  R visitUnresolvedStaticSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    return handleUnresolvedStaticSetterCompound(
        node, getter, element, operator, rhs, arg);
  }

  @override
  R visitUnresolvedStaticSetterPostfix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleUnresolvedStaticSetterPostfixPrefix(
        node, getter, element, operator, arg,
        isPrefix: false);
  }

  @override
  R visitUnresolvedStaticSetterPrefix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleUnresolvedStaticSetterPostfixPrefix(
        node, getter, element, operator, arg,
        isPrefix: true);
  }
}

/// Mixin that groups all non-compound `visitLocalX` and `visitParameterX`
/// methods by delegating calls to `handleLocalX` methods.
///
/// This mixin is useful for the cases where both parameters, local variables,
/// and local functions, captured or not, are handled uniformly.
abstract class BaseImplementationOfLocalsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  R handleLocalGet(Send node, LocalElement element, A arg);

  R handleLocalInvoke(Send node, LocalElement element, NodeList arguments,
      CallStructure callStructure, A arg);

  R handleLocalSet(SendSet node, LocalElement element, Node rhs, A arg);

  R handleImmutableLocalSet(
      SendSet node, LocalElement element, Node rhs, A arg);

  @override
  R visitLocalFunctionGet(Send node, LocalFunctionElement function, A arg) {
    return handleLocalGet(node, function, arg);
  }

  @override
  R visitLocalFunctionInvoke(Send node, LocalFunctionElement function,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleLocalInvoke(node, function, arguments, callStructure, arg);
  }

  @override
  R visitLocalFunctionIncompatibleInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return handleLocalInvoke(node, function, arguments, callStructure, arg);
  }

  @override
  R visitLocalVariableGet(Send node, LocalVariableElement variable, A arg) {
    return handleLocalGet(node, variable, arg);
  }

  @override
  R visitLocalVariableInvoke(Send node, LocalVariableElement variable,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleLocalInvoke(node, variable, arguments, callStructure, arg);
  }

  @override
  R visitLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, A arg) {
    return handleLocalSet(node, variable, rhs, arg);
  }

  @override
  R visitParameterGet(Send node, ParameterElement parameter, A arg) {
    return handleLocalGet(node, parameter, arg);
  }

  @override
  R visitParameterInvoke(Send node, ParameterElement parameter,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleLocalInvoke(node, parameter, arguments, callStructure, arg);
  }

  @override
  R visitParameterSet(
      SendSet node, ParameterElement parameter, Node rhs, A arg) {
    return handleLocalSet(node, parameter, rhs, arg);
  }

  @override
  R visitFinalLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, A arg) {
    return handleImmutableLocalSet(node, variable, rhs, arg);
  }

  @override
  R visitFinalParameterSet(
      SendSet node, ParameterElement parameter, Node rhs, A arg) {
    return handleImmutableLocalSet(node, parameter, rhs, arg);
  }

  @override
  R visitLocalFunctionSet(
      SendSet node, LocalFunctionElement function, Node rhs, A arg) {
    return handleImmutableLocalSet(node, function, rhs, arg);
  }
}

/// Mixin that groups all compound `visitLocalX` and `visitParameterX` methods
/// by delegating calls to `handleLocalX` methods.
///
/// This mixin is useful for the cases where both parameters, local variables,
/// and local functions, captured or not, are handled uniformly.
abstract class BaseImplementationOfLocalCompoundsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  R handleLocalCompound(Send node, LocalElement element,
      AssignmentOperator operator, Node rhs, A arg);

  R handleLocalPostfixPrefix(
      Send node, LocalElement element, IncDecOperator operator, A arg,
      {bool isPrefix});

  @override
  R visitLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleLocalCompound(node, variable, operator, rhs, arg);
  }

  @override
  R visitLocalVariablePostfix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return handleLocalPostfixPrefix(node, variable, operator, arg,
        isPrefix: false);
  }

  @override
  R visitLocalVariablePrefix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return handleLocalPostfixPrefix(node, variable, operator, arg,
        isPrefix: true);
  }

  @override
  R visitParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleLocalCompound(node, parameter, operator, rhs, arg);
  }

  @override
  R visitParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return handleLocalPostfixPrefix(node, parameter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return handleLocalPostfixPrefix(node, parameter, operator, arg,
        isPrefix: true);
  }
}

/// Mixin that groups all `visitConstantX` and `visitXTypeLiteralY` methods for
/// constant type literals by delegating calls to `handleConstantX` methods.
///
/// This mixin is useful for the cases where expressions on constants are
/// handled uniformly.
abstract class BaseImplementationOfConstantsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  R handleConstantGet(Node node, ConstantExpression constant, A arg);

  R handleConstantInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg);

  @override
  R visitClassTypeLiteralGet(Send node, ConstantExpression constant, A arg) {
    return handleConstantGet(node, constant, arg);
  }

  @override
  R visitClassTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleConstantInvoke(node, constant, arguments, callStructure, arg);
  }

  @override
  R visitConstConstructorInvoke(
      NewExpression node, ConstructedConstantExpression constant, A arg) {
    return handleConstantGet(node, constant, arg);
  }

  @override
  R visitBoolFromEnvironmentConstructorInvoke(NewExpression node,
      BoolFromEnvironmentConstantExpression constant, A arg) {
    return handleConstantGet(node, constant, arg);
  }

  @override
  R visitIntFromEnvironmentConstructorInvoke(NewExpression node,
      IntFromEnvironmentConstantExpression constant, A arg) {
    return handleConstantGet(node, constant, arg);
  }

  @override
  R visitStringFromEnvironmentConstructorInvoke(NewExpression node,
      StringFromEnvironmentConstantExpression constant, A arg) {
    return handleConstantGet(node, constant, arg);
  }

  @override
  R visitConstantGet(Send node, ConstantExpression constant, A arg) {
    return handleConstantGet(node, constant, arg);
  }

  @override
  R visitConstantInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleConstantInvoke(node, constant, arguments, callStructure, arg);
  }

  @override
  R visitDynamicTypeLiteralGet(Send node, ConstantExpression constant, A arg) {
    return handleConstantGet(node, constant, arg);
  }

  @override
  R visitDynamicTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleConstantInvoke(node, constant, arguments, callStructure, arg);
  }

  @override
  R visitTypedefTypeLiteralGet(Send node, ConstantExpression constant, A arg) {
    return handleConstantGet(node, constant, arg);
  }

  @override
  R visitTypedefTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, A arg) {
    return handleConstantInvoke(node, constant, arguments, callStructure, arg);
  }
}

/// Mixin that groups all non-compound `visitDynamicPropertyX` and
/// `visitThisPropertyY` methods for by delegating calls to `handleDynamicX`
/// methods, providing `null` as the receiver for the this properties.
///
/// This mixin is useful for the cases where dynamic and this properties are
/// handled uniformly.
abstract class BaseImplementationOfDynamicsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  R handleDynamicGet(Send node, Node receiver, Name name, A arg);

  R handleDynamicInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, A arg);

  R handleDynamicSet(SendSet node, Node receiver, Name name, Node rhs, A arg);

  @override
  R visitDynamicPropertyGet(Send node, Node receiver, Name name, A arg) {
    return handleDynamicGet(node, receiver, name, arg);
  }

  @override
  R visitIfNotNullDynamicPropertyGet(
      Send node, Node receiver, Name name, A arg) {
    // TODO(johnniwinther): should these redirect to handleDynamicX?
    return handleDynamicGet(node, receiver, name, arg);
  }

  @override
  R visitDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, A arg) {
    return handleDynamicInvoke(node, receiver, arguments, selector, arg);
  }

  @override
  R visitIfNotNullDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, A arg) {
    return handleDynamicInvoke(node, receiver, arguments, selector, arg);
  }

  @override
  R visitDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, A arg) {
    return handleDynamicSet(node, receiver, name, rhs, arg);
  }

  @override
  R visitIfNotNullDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, A arg) {
    return handleDynamicSet(node, receiver, name, rhs, arg);
  }

  @override
  R visitThisPropertyGet(Send node, Name name, A arg) {
    return handleDynamicGet(node, null, name, arg);
  }

  @override
  R visitThisPropertyInvoke(
      Send node, NodeList arguments, Selector selector, A arg) {
    return handleDynamicInvoke(node, null, arguments, selector, arg);
  }

  @override
  R visitThisPropertySet(SendSet node, Name name, Node rhs, A arg) {
    return handleDynamicSet(node, null, name, rhs, arg);
  }
}

/// Mixin that groups all compounds of `visitDynamicPropertyX` and
/// `visitThisPropertyY` methods for by delegating calls to `handleDynamicX`
/// methods, providing `null` as the receiver for the this properties.
///
/// This mixin is useful for the cases where dynamic and this properties are
/// handled uniformly.
abstract class BaseImplementationOfDynamicCompoundsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  R handleDynamicCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, A arg);

  R handleDynamicPostfixPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleDynamicIndexPostfixPrefix(
      Send node, Node receiver, Node index, IncDecOperator operator, A arg,
      {bool isPrefix});

  @override
  R visitDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleDynamicCompound(node, receiver, name, operator, rhs, arg);
  }

  @override
  R visitIfNotNullDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleDynamicCompound(node, receiver, name, operator, rhs, arg);
  }

  @override
  R visitDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return handleDynamicPostfixPrefix(node, receiver, name, operator, arg,
        isPrefix: false);
  }

  @override
  R visitIfNotNullDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return handleDynamicPostfixPrefix(node, receiver, name, operator, arg,
        isPrefix: false);
  }

  @override
  R visitDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return handleDynamicPostfixPrefix(node, receiver, name, operator, arg,
        isPrefix: true);
  }

  @override
  R visitIfNotNullDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return handleDynamicPostfixPrefix(node, receiver, name, operator, arg,
        isPrefix: true);
  }

  @override
  R visitThisPropertyCompound(
      Send node, Name name, AssignmentOperator operator, Node rhs, A arg) {
    return handleDynamicCompound(node, null, name, operator, rhs, arg);
  }

  @override
  R visitThisPropertyPostfix(
      Send node, Name name, IncDecOperator operator, A arg) {
    return handleDynamicPostfixPrefix(node, null, name, operator, arg,
        isPrefix: false);
  }

  @override
  R visitThisPropertyPrefix(
      Send node, Name name, IncDecOperator operator, A arg) {
    return handleDynamicPostfixPrefix(node, null, name, operator, arg,
        isPrefix: true);
  }

  @override
  R visitIndexPostfix(
      Send node, Node receiver, Node index, IncDecOperator operator, A arg) {
    return handleDynamicIndexPostfixPrefix(node, receiver, index, operator, arg,
        isPrefix: false);
  }

  @override
  R visitIndexPrefix(
      Send node, Node receiver, Node index, IncDecOperator operator, A arg) {
    return handleDynamicIndexPostfixPrefix(node, receiver, index, operator, arg,
        isPrefix: true);
  }
}

/// The getter kind for statically resolved compound expressions.
enum CompoundGetter {
  /// The compound reads from a field.
  FIELD,

  /// The compound reads from a getter.
  GETTER,

  /// The compound reads (closurizes) a method.
  METHOD,

  /// The getter is unresolved. The accompanied element is an erroneous element.
  UNRESOLVED,
}

/// The setter kind for statically resolved compound expressions.
enum CompoundSetter {
  /// The compound writes to a field.
  FIELD,

  /// The compound writes to a setter.
  SETTER,

  /// The setter is unresolved or unassignable. The accompanied element may be
  /// `null`, and erroneous element, or the unassignable element.
  INVALID,
}

/// The kind of a [CompoundRhs].
enum CompoundKind {
  /// A prefix expression, like `--a`.
  PREFIX,

  /// A postfix expression, like `a++`.
  POSTFIX,

  /// A compound assignment, like `a *= b`.
  ASSIGNMENT,
}

/// The right-hand side of a compound expression.
abstract class CompoundRhs {
  /// The kind of compound.
  CompoundKind get kind;

  /// The binary operator implied by the compound operator.
  BinaryOperator get operator;

  /// The explicit right hand side in case of a compound assignment, `null`
  /// otherwise.
  Node get rhs;
}

/// A prefix or postfix of [incDecOperator].
class IncDecCompound implements CompoundRhs {
  final CompoundKind kind;
  final IncDecOperator incDecOperator;

  IncDecCompound(this.kind, this.incDecOperator);

  BinaryOperator get operator => incDecOperator.binaryOperator;

  Node get rhs => null;
}

/// A compound assignment with [assignmentOperator] and [rhs].
class AssignmentCompound implements CompoundRhs {
  final AssignmentOperator assignmentOperator;
  final Node rhs;

  AssignmentCompound(this.assignmentOperator, this.rhs);

  CompoundKind get kind => CompoundKind.ASSIGNMENT;

  BinaryOperator get operator => assignmentOperator.binaryOperator;
}

/// Simplified handling of compound assignments and prefix/postfix expressions.
abstract class BaseImplementationOfCompoundsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  /// Handle a super compounds, like `super.foo += 42` or `--super.bar`.
  R handleSuperCompounds(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      A arg);

  /// Handle a static or top level compounds, like `foo += 42` or `--bar`.
  R handleStaticCompounds(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      A arg);

  /// Handle a local compounds, like `foo += 42` or `--bar`. If [isSetterValid]
  /// is false [local] is unassignable.
  R handleLocalCompounds(
      SendSet node, LocalElement local, CompoundRhs rhs, A arg,
      {bool isSetterValid});

  /// Handle a compounds on a type literal constant, like `Object += 42` or
  /// `--Object`.
  R handleTypeLiteralConstantCompounds(
      SendSet node, ConstantExpression constant, CompoundRhs rhs, A arg);

  /// Handle a compounds on a type variable type literal, like `T += 42` or
  /// `--T`.
  R handleTypeVariableTypeLiteralCompounds(
      SendSet node, TypeVariableElement typeVariable, CompoundRhs rhs, A arg);

  /// Handle a dynamic compounds, like `o.foo += 42` or `--o.foo`. [receiver] is
  /// `null` for properties on `this`, like `--this.foo` or `--foo`.
  R handleDynamicCompounds(
      Send node, Node receiver, Name name, CompoundRhs rhs, A arg);

  R visitDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleDynamicCompounds(
        node, receiver, name, new AssignmentCompound(operator, rhs), arg);
  }

  R visitIfNotNullDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleDynamicCompounds(
        node, receiver, name, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitThisPropertyCompound(
      Send node, Name name, AssignmentOperator operator, Node rhs, A arg) {
    return handleDynamicCompounds(
        node, null, name, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleLocalCompounds(
        node, parameter, new AssignmentCompound(operator, rhs), arg,
        isSetterValid: true);
  }

  @override
  R visitFinalParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleLocalCompounds(
        node, parameter, new AssignmentCompound(operator, rhs), arg,
        isSetterValid: false);
  }

  @override
  R visitLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleLocalCompounds(
        node, variable, new AssignmentCompound(operator, rhs), arg,
        isSetterValid: true);
  }

  @override
  R visitFinalLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleLocalCompounds(
        node, variable, new AssignmentCompound(operator, rhs), arg,
        isSetterValid: false);
  }

  @override
  R visitLocalFunctionCompound(Send node, LocalFunctionElement function,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleLocalCompounds(
        node, function, new AssignmentCompound(operator, rhs), arg,
        isSetterValid: false);
  }

  @override
  R visitStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.FIELD, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitFinalStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, field, CompoundGetter.FIELD, null,
        CompoundSetter.INVALID, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitStaticGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, getter, CompoundGetter.GETTER, setter,
        CompoundSetter.SETTER, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitStaticMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, method, CompoundGetter.METHOD, setter,
        CompoundSetter.SETTER, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.FIELD, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitFinalTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, field, CompoundGetter.FIELD, null,
        CompoundSetter.INVALID, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitTopLevelGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, getter, CompoundGetter.GETTER, setter,
        CompoundSetter.SETTER, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitTopLevelMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, method, CompoundGetter.METHOD, setter,
        CompoundSetter.SETTER, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.FIELD, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitFinalSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.INVALID, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitSuperGetterSetterCompound(Send node, GetterElement getter,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(node, getter, CompoundGetter.GETTER, setter,
        CompoundSetter.SETTER, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitSuperMethodSetterCompound(Send node, FunctionElement method,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(node, method, CompoundGetter.METHOD, setter,
        CompoundSetter.SETTER, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitSuperFieldSetterCompound(Send node, FieldElement field,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(node, field, CompoundGetter.FIELD, setter,
        CompoundSetter.SETTER, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitSuperGetterFieldCompound(Send node, GetterElement getter,
      FieldElement field, AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(node, getter, CompoundGetter.GETTER, field,
        CompoundSetter.FIELD, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitClassTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleTypeLiteralConstantCompounds(
        node, constant, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitTypedefTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleTypeLiteralConstantCompounds(
        node, constant, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitTypeVariableTypeLiteralCompound(Send node, TypeVariableElement element,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleTypeVariableTypeLiteralCompounds(
        node, element, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitDynamicTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleTypeLiteralConstantCompounds(
        node, constant, new AssignmentCompound(operator, rhs), arg);
  }

  R visitDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return handleDynamicCompounds(node, receiver, name,
        new IncDecCompound(CompoundKind.PREFIX, operator), arg);
  }

  R visitIfNotNullDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return handleDynamicCompounds(node, receiver, name,
        new IncDecCompound(CompoundKind.PREFIX, operator), arg);
  }

  @override
  R visitParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return handleLocalCompounds(
        node, parameter, new IncDecCompound(CompoundKind.PREFIX, operator), arg,
        isSetterValid: true);
  }

  @override
  R visitLocalVariablePrefix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return handleLocalCompounds(
        node, variable, new IncDecCompound(CompoundKind.PREFIX, operator), arg,
        isSetterValid: true);
  }

  @override
  R visitLocalFunctionPrefix(Send node, LocalFunctionElement function,
      IncDecOperator operator, A arg) {
    return handleLocalCompounds(
        node, function, new IncDecCompound(CompoundKind.PREFIX, operator), arg,
        isSetterValid: false);
  }

  R visitThisPropertyPrefix(
      Send node, Name name, IncDecOperator operator, A arg) {
    return handleDynamicCompounds(node, null, name,
        new IncDecCompound(CompoundKind.PREFIX, operator), arg);
  }

  @override
  R visitStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitStaticGetterSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  R visitStaticMethodSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.METHOD,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitTopLevelGetterSetterPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitTopLevelMethodSetterPrefix(Send node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitSuperFieldPrefix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitSuperFieldFieldPrefix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        readField,
        CompoundGetter.FIELD,
        writtenField,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitSuperFieldSetterPrefix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitSuperGetterSetterPrefix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitSuperGetterFieldPrefix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        field,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitSuperMethodSetterPrefix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitClassTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return handleTypeLiteralConstantCompounds(
        node, constant, new IncDecCompound(CompoundKind.PREFIX, operator), arg);
  }

  @override
  R visitTypedefTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return handleTypeLiteralConstantCompounds(
        node, constant, new IncDecCompound(CompoundKind.PREFIX, operator), arg);
  }

  @override
  R visitTypeVariableTypeLiteralPrefix(
      Send node, TypeVariableElement element, IncDecOperator operator, A arg) {
    return handleTypeVariableTypeLiteralCompounds(
        node, element, new IncDecCompound(CompoundKind.PREFIX, operator), arg);
  }

  @override
  R visitDynamicTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return handleTypeLiteralConstantCompounds(
        node, constant, new IncDecCompound(CompoundKind.PREFIX, operator), arg);
  }

  @override
  R visitDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return handleDynamicCompounds(node, receiver, name,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg);
  }

  @override
  R visitIfNotNullDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, A arg) {
    return handleDynamicCompounds(node, receiver, name,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg);
  }

  @override
  R visitParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return handleLocalCompounds(node, parameter,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg,
        isSetterValid: true);
  }

  @override
  R visitLocalVariablePostfix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return handleLocalCompounds(
        node, variable, new IncDecCompound(CompoundKind.POSTFIX, operator), arg,
        isSetterValid: true);
  }

  @override
  R visitLocalFunctionPostfix(Send node, LocalFunctionElement function,
      IncDecOperator operator, A arg) {
    return handleLocalCompounds(
        node, function, new IncDecCompound(CompoundKind.POSTFIX, operator), arg,
        isSetterValid: false);
  }

  R visitThisPropertyPostfix(
      Send node, Name name, IncDecOperator operator, A arg) {
    return handleDynamicCompounds(node, null, name,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg);
  }

  @override
  R visitStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitStaticGetterSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  R visitStaticMethodSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.METHOD,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitTopLevelGetterSetterPostfix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitTopLevelMethodSetterPostfix(Send node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitSuperFieldPostfix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitSuperFieldFieldPostfix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        readField,
        CompoundGetter.FIELD,
        writtenField,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitSuperFieldSetterPostfix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  R visitSuperGetterSetterPostfix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitSuperGetterFieldPostfix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        field,
        CompoundSetter.FIELD,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitSuperMethodSetterPostfix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitClassTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return handleTypeLiteralConstantCompounds(node, constant,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg);
  }

  @override
  R visitTypedefTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return handleTypeLiteralConstantCompounds(node, constant,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg);
  }

  @override
  R visitTypeVariableTypeLiteralPostfix(
      Send node, TypeVariableElement element, IncDecOperator operator, A arg) {
    return handleTypeVariableTypeLiteralCompounds(
        node, element, new IncDecCompound(CompoundKind.POSTFIX, operator), arg);
  }

  @override
  R visitDynamicTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, A arg) {
    return handleTypeLiteralConstantCompounds(node, constant,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg);
  }

  @override
  R visitUnresolvedStaticGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedTopLevelGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedStaticSetterPostfix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedTopLevelSetterPostfix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitStaticMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        method,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitTopLevelMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        method,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedPostfix(
      Send node, ErroneousElement element, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedStaticGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedTopLevelGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedStaticSetterPrefix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedTopLevelSetterPrefix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitStaticMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        method,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitTopLevelMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        method,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedPrefix(
      Send node, ErroneousElement element, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedStaticGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        setter,
        CompoundSetter.SETTER,
        new AssignmentCompound(operator, rhs),
        arg);
  }

  @override
  R visitUnresolvedTopLevelGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        setter,
        CompoundSetter.SETTER,
        new AssignmentCompound(operator, rhs),
        arg);
  }

  @override
  R visitUnresolvedStaticSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, getter, CompoundGetter.GETTER, element,
        CompoundSetter.INVALID, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitUnresolvedTopLevelSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, getter, CompoundGetter.GETTER, element,
        CompoundSetter.INVALID, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitStaticMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, method, CompoundGetter.METHOD, method,
        CompoundSetter.INVALID, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitTopLevelMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(node, method, CompoundGetter.METHOD, method,
        CompoundSetter.INVALID, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitUnresolvedCompound(Send node, ErroneousElement element,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleStaticCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        element,
        CompoundSetter.INVALID,
        new AssignmentCompound(operator, rhs),
        arg);
  }

  @override
  R visitFinalLocalVariablePostfix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return handleLocalCompounds(
        node, variable, new IncDecCompound(CompoundKind.POSTFIX, operator), arg,
        isSetterValid: false);
  }

  @override
  R visitFinalLocalVariablePrefix(Send node, LocalVariableElement variable,
      IncDecOperator operator, A arg) {
    return handleLocalCompounds(
        node, variable, new IncDecCompound(CompoundKind.PREFIX, operator), arg,
        isSetterValid: false);
  }

  @override
  R visitFinalParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return handleLocalCompounds(node, parameter,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg,
        isSetterValid: false);
  }

  @override
  R visitFinalParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, A arg) {
    return handleLocalCompounds(
        node, parameter, new IncDecCompound(CompoundKind.PREFIX, operator), arg,
        isSetterValid: false);
  }

  @override
  R visitFinalStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitFinalStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitSuperFieldFieldCompound(Send node, FieldElement readField,
      FieldElement writtenField, AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(
        node,
        readField,
        CompoundGetter.FIELD,
        writtenField,
        CompoundSetter.FIELD,
        new AssignmentCompound(operator, rhs),
        arg);
  }

  @override
  R visitFinalSuperFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitFinalSuperFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitSuperMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(node, method, CompoundGetter.METHOD, method,
        CompoundSetter.INVALID, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitSuperMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        method,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitSuperMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        method,
        CompoundGetter.METHOD,
        method,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitFinalTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitFinalTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleStaticCompounds(
        node,
        field,
        CompoundGetter.FIELD,
        field,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedSuperCompound(Send node, Element element,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        element,
        CompoundSetter.INVALID,
        new AssignmentCompound(operator, rhs),
        arg);
  }

  @override
  R visitUnresolvedSuperPostfix(
      SendSet node, Element element, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedSuperPrefix(
      SendSet node, Element element, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedSuperGetterCompound(SendSet node, Element element,
      SetterElement setter, AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        setter,
        CompoundSetter.SETTER,
        new AssignmentCompound(operator, rhs),
        arg);
  }

  @override
  R visitUnresolvedSuperGetterPostfix(SendSet node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedSuperGetterPrefix(SendSet node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        element,
        CompoundGetter.UNRESOLVED,
        setter,
        CompoundSetter.SETTER,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedSuperSetterCompound(Send node, GetterElement getter,
      Element element, AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperCompounds(node, getter, CompoundGetter.GETTER, element,
        CompoundSetter.INVALID, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitUnresolvedSuperSetterPostfix(SendSet node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.POSTFIX, operator),
        arg);
  }

  @override
  R visitUnresolvedSuperSetterPrefix(SendSet node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleSuperCompounds(
        node,
        getter,
        CompoundGetter.GETTER,
        element,
        CompoundSetter.INVALID,
        new IncDecCompound(CompoundKind.PREFIX, operator),
        arg);
  }
}

/// Simplified handling of if-null assignments.
abstract class BaseImplementationOfSetIfNullsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  /// Handle a super if-null assignments, like `super.foo ??= 42`.
  R handleSuperSetIfNulls(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      Node rhs,
      A arg);

  /// Handle a static or top level if-null assignments, like `foo ??= 42`.
  R handleStaticSetIfNulls(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      Node rhs,
      A arg);

  /// Handle a local if-null assignments, like `foo ??= 42`. If [isSetterValid]
  /// is false [local] is unassignable.
  R handleLocalSetIfNulls(SendSet node, LocalElement local, Node rhs, A arg,
      {bool isSetterValid});

  /// Handle a if-null assignments on a type literal constant, like
  /// `Object ??= 42`.
  R handleTypeLiteralConstantSetIfNulls(
      SendSet node, ConstantExpression constant, Node rhs, A arg);

  /// Handle a dynamic if-null assignments, like `o.foo ??= 42`. [receiver] is
  /// `null` for properties on `this`, like `this.foo ??= 42` or `foo ??= 42`.
  R handleDynamicSetIfNulls(
      Send node, Node receiver, Name name, Node rhs, A arg);

  @override
  R visitClassTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, A arg) {
    return handleTypeLiteralConstantSetIfNulls(node, constant, rhs, arg);
  }

  @override
  R visitDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, A arg) {
    return handleDynamicSetIfNulls(node, receiver, name, rhs, arg);
  }

  @override
  R visitDynamicTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, A arg) {
    return handleTypeLiteralConstantSetIfNulls(node, constant, rhs, arg);
  }

  @override
  R visitFinalLocalVariableSetIfNull(
      Send node, LocalVariableElement variable, Node rhs, A arg) {
    return handleLocalSetIfNulls(node, variable, rhs, arg,
        isSetterValid: false);
  }

  @override
  R visitFinalParameterSetIfNull(
      Send node, ParameterElement parameter, Node rhs, A arg) {
    return handleLocalSetIfNulls(node, parameter, rhs, arg,
        isSetterValid: false);
  }

  @override
  R visitFinalStaticFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitFinalSuperFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitFinalTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitIfNotNullDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, A arg) {
    return handleDynamicSetIfNulls(node, receiver, name, rhs, arg);
  }

  @override
  R visitLocalFunctionSetIfNull(
      Send node, LocalFunctionElement function, Node rhs, A arg) {
    return handleLocalSetIfNulls(node, function, rhs, arg,
        isSetterValid: false);
  }

  @override
  R visitLocalVariableSetIfNull(
      Send node, LocalVariableElement variable, Node rhs, A arg) {
    return handleLocalSetIfNulls(node, variable, rhs, arg, isSetterValid: true);
  }

  @override
  R visitParameterSetIfNull(
      Send node, ParameterElement parameter, Node rhs, A arg) {
    return handleLocalSetIfNulls(node, parameter, rhs, arg,
        isSetterValid: true);
  }

  @override
  R visitStaticFieldSetIfNull(Send node, FieldElement field, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.FIELD, rhs, arg);
  }

  @override
  R visitStaticGetterSetterSetIfNull(
      Send node, GetterElement getter, SetterElement setter, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, getter, CompoundGetter.GETTER, setter,
        CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitStaticMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, method, CompoundGetter.METHOD, method,
        CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitStaticMethodSetterSetIfNull(
      Send node, MethodElement method, MethodElement setter, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, method, CompoundGetter.METHOD, setter,
        CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitSuperFieldFieldSetIfNull(Send node, FieldElement readField,
      FieldElement writtenField, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, readField, CompoundGetter.FIELD,
        writtenField, CompoundSetter.FIELD, rhs, arg);
  }

  @override
  R visitSuperFieldSetIfNull(Send node, FieldElement field, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.FIELD, rhs, arg);
  }

  @override
  R visitSuperFieldSetterSetIfNull(
      Send node, FieldElement field, SetterElement setter, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, field, CompoundGetter.FIELD, setter,
        CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitSuperGetterFieldSetIfNull(
      Send node, GetterElement getter, FieldElement field, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, getter, CompoundGetter.GETTER, field,
        CompoundSetter.FIELD, rhs, arg);
  }

  @override
  R visitSuperGetterSetterSetIfNull(
      Send node, GetterElement getter, SetterElement setter, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, getter, CompoundGetter.GETTER, setter,
        CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitSuperMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, method, CompoundGetter.METHOD, method,
        CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitSuperMethodSetterSetIfNull(Send node, FunctionElement method,
      SetterElement setter, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, method, CompoundGetter.METHOD, setter,
        CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitThisPropertySetIfNull(Send node, Name name, Node rhs, A arg) {
    return handleDynamicSetIfNulls(node, null, name, rhs, arg);
  }

  @override
  R visitTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, field, CompoundGetter.FIELD, field,
        CompoundSetter.FIELD, rhs, arg);
  }

  @override
  R visitTopLevelGetterSetterSetIfNull(
      Send node, GetterElement getter, SetterElement setter, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, getter, CompoundGetter.GETTER, setter,
        CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitTopLevelMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, method, CompoundGetter.METHOD, method,
        CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitTopLevelMethodSetterSetIfNull(Send node, FunctionElement method,
      SetterElement setter, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, method, CompoundGetter.METHOD, setter,
        CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitTypedefTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, A arg) {
    return handleTypeLiteralConstantSetIfNulls(node, constant, rhs, arg);
  }

  @override
  R visitUnresolvedSetIfNull(Send node, Element element, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, element, CompoundGetter.UNRESOLVED,
        element, CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitUnresolvedStaticGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, element, CompoundGetter.UNRESOLVED,
        setter, CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitUnresolvedStaticSetterSetIfNull(
      Send node, GetterElement getter, Element element, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, getter, CompoundGetter.GETTER, element,
        CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitUnresolvedSuperGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, element, CompoundGetter.UNRESOLVED,
        setter, CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitUnresolvedSuperSetIfNull(Send node, Element element, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, element, CompoundGetter.UNRESOLVED,
        element, CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitUnresolvedSuperSetterSetIfNull(
      Send node, GetterElement getter, Element element, Node rhs, A arg) {
    return handleSuperSetIfNulls(node, getter, CompoundGetter.GETTER, element,
        CompoundSetter.INVALID, rhs, arg);
  }

  @override
  R visitUnresolvedTopLevelGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, element, CompoundGetter.UNRESOLVED,
        setter, CompoundSetter.SETTER, rhs, arg);
  }

  @override
  R visitUnresolvedTopLevelSetterSetIfNull(
      Send node, GetterElement getter, Element element, Node rhs, A arg) {
    return handleStaticSetIfNulls(node, getter, CompoundGetter.GETTER, element,
        CompoundSetter.INVALID, rhs, arg);
  }
}

/// Simplified handling of indexed compound assignments and prefix/postfix
/// expressions.
abstract class BaseImplementationOfIndexCompoundsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  /// Handle a dynamic index compounds, like `receiver[index] += rhs` or
  /// `--receiver[index]`.
  R handleIndexCompounds(
      SendSet node, Node receiver, Node index, CompoundRhs rhs, A arg);

  /// Handle a super index compounds, like `super[index] += rhs` or
  /// `--super[index]`.
  R handleSuperIndexCompounds(SendSet node, Element indexFunction,
      Element indexSetFunction, Node index, CompoundRhs rhs, A arg,
      {bool isGetterValid, bool isSetterValid});

  @override
  R visitSuperCompoundIndexSet(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return handleSuperIndexCompounds(node, indexFunction, indexSetFunction,
        index, new AssignmentCompound(operator, rhs), arg,
        isGetterValid: true, isSetterValid: true);
  }

  @override
  R visitSuperIndexPostfix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleSuperIndexCompounds(node, indexFunction, indexSetFunction,
        index, new IncDecCompound(CompoundKind.POSTFIX, operator), arg,
        isGetterValid: true, isSetterValid: true);
  }

  @override
  R visitSuperIndexPrefix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleSuperIndexCompounds(node, indexFunction, indexSetFunction,
        index, new IncDecCompound(CompoundKind.PREFIX, operator), arg,
        isGetterValid: true, isSetterValid: true);
  }

  @override
  R visitUnresolvedSuperGetterCompoundIndexSet(
      SendSet node,
      Element indexFunction,
      FunctionElement indexSetFunction,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return handleSuperIndexCompounds(node, indexFunction, indexSetFunction,
        index, new AssignmentCompound(operator, rhs), arg,
        isGetterValid: false, isSetterValid: true);
  }

  @override
  R visitUnresolvedSuperSetterCompoundIndexSet(
      SendSet node,
      MethodElement indexFunction,
      Element indexSetFunction,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      A arg) {
    return handleSuperIndexCompounds(node, indexFunction, indexSetFunction,
        index, new AssignmentCompound(operator, rhs), arg,
        isGetterValid: true, isSetterValid: false);
  }

  @override
  R visitUnresolvedSuperCompoundIndexSet(SendSet node, Element element,
      Node index, AssignmentOperator operator, Node rhs, A arg) {
    return handleSuperIndexCompounds(node, element, element, index,
        new AssignmentCompound(operator, rhs), arg,
        isGetterValid: false, isSetterValid: false);
  }

  @override
  R visitUnresolvedSuperGetterIndexPostfix(
      SendSet node,
      Element element,
      FunctionElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleSuperIndexCompounds(node, element, indexSetFunction, index,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg,
        isGetterValid: false, isSetterValid: true);
  }

  @override
  R visitUnresolvedSuperGetterIndexPrefix(
      SendSet node,
      Element element,
      FunctionElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleSuperIndexCompounds(node, element, indexSetFunction, index,
        new IncDecCompound(CompoundKind.PREFIX, operator), arg,
        isGetterValid: false, isSetterValid: true);
  }

  @override
  R visitUnresolvedSuperSetterIndexPostfix(
      SendSet node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleSuperIndexCompounds(node, indexFunction, element, index,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg,
        isGetterValid: true, isSetterValid: false);
  }

  @override
  R visitUnresolvedSuperSetterIndexPrefix(
      SendSet node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleSuperIndexCompounds(node, indexFunction, element, index,
        new IncDecCompound(CompoundKind.PREFIX, operator), arg,
        isGetterValid: true, isSetterValid: false);
  }

  @override
  R visitUnresolvedSuperIndexPostfix(
      Send node, Element element, Node index, IncDecOperator operator, A arg) {
    return handleSuperIndexCompounds(node, element, element, index,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg,
        isGetterValid: false, isSetterValid: false);
  }

  @override
  R visitUnresolvedSuperIndexPrefix(
      Send node, Element element, Node index, IncDecOperator operator, A arg) {
    return handleSuperIndexCompounds(node, element, element, index,
        new IncDecCompound(CompoundKind.PREFIX, operator), arg,
        isGetterValid: false, isSetterValid: false);
  }

  @override
  R visitCompoundIndexSet(SendSet node, Node receiver, Node index,
      AssignmentOperator operator, Node rhs, A arg) {
    return handleIndexCompounds(
        node, receiver, index, new AssignmentCompound(operator, rhs), arg);
  }

  @override
  R visitIndexPostfix(
      Send node, Node receiver, Node index, IncDecOperator operator, A arg) {
    return handleIndexCompounds(node, receiver, index,
        new IncDecCompound(CompoundKind.POSTFIX, operator), arg);
  }

  @override
  R visitIndexPrefix(
      Send node, Node receiver, Node index, IncDecOperator operator, A arg) {
    return handleIndexCompounds(node, receiver, index,
        new IncDecCompound(CompoundKind.PREFIX, operator), arg);
  }
}

/// Simplified handling of super if-null assignments.
abstract class BaseImplementationOfSuperIndexSetIfNullMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  /// Handle a super index if-null assignments, like `super[index] ??= rhs`.
  R handleSuperIndexSetIfNull(SendSet node, Element indexFunction,
      Element indexSetFunction, Node index, Node rhs, A arg,
      {bool isGetterValid, bool isSetterValid});

  @override
  R visitSuperIndexSetIfNull(Send node, FunctionElement indexFunction,
      FunctionElement indexSetFunction, Node index, Node rhs, A arg) {
    return handleSuperIndexSetIfNull(
        node, indexFunction, indexSetFunction, index, rhs, arg,
        isGetterValid: true, isSetterValid: true);
  }

  @override
  R visitUnresolvedSuperGetterIndexSetIfNull(
      SendSet node,
      Element indexFunction,
      FunctionElement indexSetFunction,
      Node index,
      Node rhs,
      A arg) {
    return handleSuperIndexSetIfNull(
        node, indexFunction, indexSetFunction, index, rhs, arg,
        isGetterValid: false, isSetterValid: true);
  }

  @override
  R visitUnresolvedSuperSetterIndexSetIfNull(
      SendSet node,
      MethodElement indexFunction,
      Element indexSetFunction,
      Node index,
      Node rhs,
      A arg) {
    return handleSuperIndexSetIfNull(
        node, indexFunction, indexSetFunction, index, rhs, arg,
        isGetterValid: true, isSetterValid: false);
  }

  @override
  R visitUnresolvedSuperIndexSetIfNull(
      Send node, Element element, Node index, Node rhs, A arg) {
    return handleSuperIndexSetIfNull(node, element, element, index, rhs, arg,
        isGetterValid: false, isSetterValid: false);
  }
}

/// Mixin that groups all `visitSuperXPrefix`, `visitSuperXPostfix` methods by
/// delegating calls to `handleSuperXPostfixPrefix` methods.
///
/// This mixin is useful for the cases where super prefix/postfix expression are
/// handled uniformly.
abstract class BaseImplementationOfSuperIncDecsMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  R handleSuperFieldFieldPostfixPrefix(Send node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleSuperFieldSetterPostfixPrefix(Send node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleSuperGetterFieldPostfixPrefix(Send node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleSuperGetterSetterPostfixPrefix(Send node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleSuperMethodSetterPostfixPrefix(Send node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleSuperIndexPostfixPrefix(
      Send node,
      FunctionElement indexFunction,
      FunctionElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg,
      {bool isPrefix});

  R handleUnresolvedSuperGetterIndexPostfixPrefix(Send node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleUnresolvedSuperSetterIndexPostfixPrefix(
      Send node,
      FunctionElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      A arg,
      {bool isPrefix});

  R handleUnresolvedSuperIndexPostfixPrefix(
      Send node, Element element, Node index, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleFinalSuperFieldPostfixPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleSuperMethodPostfixPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleUnresolvedSuperPostfixPrefix(
      Send node, Element element, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleUnresolvedSuperGetterPostfixPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, A arg,
      {bool isPrefix});

  R handleUnresolvedSuperSetterPostfixPrefix(Send node, GetterElement getter,
      Element element, IncDecOperator operator, A arg,
      {bool isPrefix});

  @override
  R visitSuperFieldFieldPostfix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return handleSuperFieldFieldPostfixPrefix(
        node, readField, writtenField, operator, arg,
        isPrefix: false);
  }

  @override
  R visitSuperFieldFieldPrefix(SendSet node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, A arg) {
    return handleSuperFieldFieldPostfixPrefix(
        node, readField, writtenField, operator, arg,
        isPrefix: true);
  }

  @override
  R visitSuperFieldPostfix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperFieldFieldPostfixPrefix(node, field, field, operator, arg,
        isPrefix: false);
  }

  @override
  R visitSuperFieldPrefix(
      SendSet node, FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperFieldFieldPostfixPrefix(node, field, field, operator, arg,
        isPrefix: true);
  }

  @override
  R visitSuperFieldSetterPostfix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperFieldSetterPostfixPrefix(
        node, field, setter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitSuperFieldSetterPrefix(SendSet node, FieldElement field,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperFieldSetterPostfixPrefix(
        node, field, setter, operator, arg,
        isPrefix: true);
  }

  @override
  R visitSuperGetterFieldPostfix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperGetterFieldPostfixPrefix(
        node, getter, field, operator, arg,
        isPrefix: false);
  }

  @override
  R visitSuperGetterFieldPrefix(SendSet node, GetterElement getter,
      FieldElement field, IncDecOperator operator, A arg) {
    return handleSuperGetterFieldPostfixPrefix(
        node, getter, field, operator, arg,
        isPrefix: true);
  }

  @override
  R visitSuperGetterSetterPostfix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperGetterSetterPostfixPrefix(
        node, getter, setter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitSuperGetterSetterPrefix(SendSet node, GetterElement getter,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperGetterSetterPostfixPrefix(
        node, getter, setter, operator, arg,
        isPrefix: true);
  }

  @override
  R visitSuperMethodSetterPostfix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperMethodSetterPostfixPrefix(
        node, method, setter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitSuperMethodSetterPrefix(SendSet node, FunctionElement method,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleSuperMethodSetterPostfixPrefix(
        node, method, setter, operator, arg,
        isPrefix: true);
  }

  @override
  R visitSuperIndexPostfix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleSuperIndexPostfixPrefix(
        node, indexFunction, indexSetFunction, index, operator, arg,
        isPrefix: false);
  }

  @override
  R visitSuperIndexPrefix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleSuperIndexPostfixPrefix(
        node, indexFunction, indexSetFunction, index, operator, arg,
        isPrefix: true);
  }

  @override
  R visitUnresolvedSuperGetterIndexPostfix(SendSet node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperGetterIndexPostfixPrefix(
        node, element, setter, index, operator, arg,
        isPrefix: false);
  }

  @override
  R visitUnresolvedSuperGetterIndexPrefix(SendSet node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperGetterIndexPostfixPrefix(
        node, element, setter, index, operator, arg,
        isPrefix: true);
  }

  @override
  R visitUnresolvedSuperSetterIndexPostfix(
      SendSet node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleUnresolvedSuperSetterIndexPostfixPrefix(
        node, indexFunction, element, index, operator, arg,
        isPrefix: false);
  }

  @override
  R visitUnresolvedSuperSetterIndexPrefix(
      SendSet node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      A arg) {
    return handleUnresolvedSuperSetterIndexPostfixPrefix(
        node, indexFunction, element, index, operator, arg,
        isPrefix: true);
  }

  @override
  R visitUnresolvedSuperIndexPostfix(
      Send node, Element element, Node index, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperIndexPostfixPrefix(
        node, element, index, operator, arg,
        isPrefix: false);
  }

  @override
  R visitUnresolvedSuperIndexPrefix(
      Send node, Element element, Node index, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperIndexPostfixPrefix(
        node, element, index, operator, arg,
        isPrefix: true);
  }

  @override
  R visitFinalSuperFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleFinalSuperFieldPostfixPrefix(node, field, operator, arg,
        isPrefix: false);
  }

  @override
  R visitFinalSuperFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, A arg) {
    return handleFinalSuperFieldPostfixPrefix(node, field, operator, arg,
        isPrefix: true);
  }

  @override
  R visitSuperMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return handleSuperMethodPostfixPrefix(node, method, operator, arg,
        isPrefix: false);
  }

  @override
  R visitSuperMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, A arg) {
    return handleSuperMethodPostfixPrefix(node, method, operator, arg,
        isPrefix: true);
  }

  @override
  R visitUnresolvedSuperPostfix(
      SendSet node, Element element, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperPostfixPrefix(node, element, operator, arg,
        isPrefix: false);
  }

  @override
  R visitUnresolvedSuperPrefix(
      Send node, Element element, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperPostfixPrefix(node, element, operator, arg,
        isPrefix: true);
  }

  @override
  R visitUnresolvedSuperGetterPostfix(SendSet node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperGetterPostfixPrefix(
        node, element, setter, operator, arg,
        isPrefix: false);
  }

  @override
  R visitUnresolvedSuperGetterPrefix(SendSet node, Element element,
      SetterElement setter, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperGetterPostfixPrefix(
        node, element, setter, operator, arg,
        isPrefix: true);
  }

  @override
  R visitUnresolvedSuperSetterPostfix(SendSet node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperSetterPostfixPrefix(
        node, getter, element, operator, arg,
        isPrefix: false);
  }

  @override
  R visitUnresolvedSuperSetterPrefix(SendSet node, GetterElement getter,
      Element element, IncDecOperator operator, A arg) {
    return handleUnresolvedSuperSetterPostfixPrefix(
        node, getter, element, operator, arg,
        isPrefix: true);
  }
}

/// Mixin that groups the non-constant `visitXConstructorInvoke` methods by
/// delegating calls to the `handleConstructorInvoke` method.
///
/// This mixin is useful for the cases where all constructor invocations are
/// handled uniformly.
abstract class BaseImplementationOfNewMixin<R, A>
    implements SemanticSendVisitor<R, A> {
  R handleConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionDartType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg);

  R visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return handleConstructorInvoke(
        node, constructor, type, arguments, callStructure, arg);
  }

  @override
  R visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return handleConstructorInvoke(
        node, constructor, type, arguments, callStructure, arg);
  }

  @override
  R visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return handleConstructorInvoke(
        node, constructor, type, arguments, callStructure, arg);
  }

  @override
  R visitRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      ConstructorElement effectiveTarget,
      ResolutionInterfaceType effectiveTargetType,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return handleConstructorInvoke(
        node, constructor, type, arguments, callStructure, arg);
  }

  @override
  R visitUnresolvedConstructorInvoke(NewExpression node, Element constructor,
      ResolutionDartType type, NodeList arguments, Selector selector, A arg) {
    return handleConstructorInvoke(
        node, constructor, type, arguments, selector.callStructure, arg);
  }

  @override
  R visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      ErroneousElement element,
      ResolutionDartType type,
      NodeList arguments,
      Selector selector,
      A arg) {
    return handleConstructorInvoke(
        node, element, type, arguments, selector.callStructure, arg);
  }

  @override
  R visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return handleConstructorInvoke(
        node, constructor, type, arguments, callStructure, arg);
  }

  @override
  R visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      A arg) {
    return handleConstructorInvoke(
        node, constructor, type, arguments, callStructure, arg);
  }
}
