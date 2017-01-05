// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.semantics_visitor_test;

class SemanticSendTestVisitor extends SemanticTestVisitor {
  SemanticSendTestVisitor(TreeElements elements) : super(elements);

  @override
  visitAs(Send node, Node expression, ResolutionDartType type, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_AS, expression: expression, type: type));
    apply(expression, arg);
  }

  @override
  errorInvalidCompound(Send node, ErroneousElement error,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_COMPOUND,
        error: error.messageKind, operator: operator, rhs: rhs));
    super.errorInvalidCompound(node, error, operator, rhs, arg);
  }

  @override
  errorInvalidGet(Send node, ErroneousElement error, arg) {
    visits
        .add(new Visit(VisitKind.ERROR_INVALID_GET, error: error.messageKind));
    super.errorInvalidGet(node, error, arg);
  }

  @override
  errorInvalidInvoke(Send node, ErroneousElement error, NodeList arguments,
      Selector selector, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_INVOKE,
        error: error.messageKind, arguments: arguments));
    super.errorInvalidInvoke(node, error, arguments, selector, arg);
  }

  @override
  errorInvalidPostfix(
      Send node, ErroneousElement error, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_POSTFIX,
        error: error.messageKind, operator: operator));
    super.errorInvalidPostfix(node, error, operator, arg);
  }

  @override
  errorInvalidPrefix(
      Send node, ErroneousElement error, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_PREFIX,
        error: error.messageKind, operator: operator));
    super.errorInvalidPrefix(node, error, operator, arg);
  }

  @override
  errorInvalidSet(Send node, ErroneousElement error, Node rhs, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_SET,
        error: error.messageKind, rhs: rhs));
    super.errorInvalidSet(node, error, rhs, arg);
  }

  @override
  errorInvalidSetIfNull(Send node, ErroneousElement error, Node rhs, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_SET_IF_NULL,
        error: error.messageKind, rhs: rhs));
    super.errorInvalidSetIfNull(node, error, rhs, arg);
  }

  @override
  errorInvalidUnary(
      Send node, UnaryOperator operator, ErroneousElement error, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_UNARY,
        error: error.messageKind, operator: operator));
    super.errorInvalidUnary(node, operator, error, arg);
  }

  @override
  errorInvalidEquals(Send node, ErroneousElement error, Node right, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_EQUALS,
        error: error.messageKind, right: right));
    super.errorInvalidEquals(node, error, right, arg);
  }

  @override
  errorInvalidNotEquals(Send node, ErroneousElement error, Node right, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_NOT_EQUALS,
        error: error.messageKind, right: right));
    super.errorInvalidNotEquals(node, error, right, arg);
  }

  @override
  errorInvalidBinary(Send node, ErroneousElement error, BinaryOperator operator,
      Node right, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_BINARY,
        error: error.messageKind, operator: operator, right: right));
    super.errorInvalidBinary(node, error, operator, right, arg);
  }

  @override
  errorInvalidIndex(Send node, ErroneousElement error, Node index, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_INDEX,
        error: error.messageKind, index: index));
    super.errorInvalidIndex(node, error, index, arg);
  }

  @override
  errorInvalidIndexSet(
      Send node, ErroneousElement error, Node index, Node rhs, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_INDEX_SET,
        error: error.messageKind, index: index, rhs: rhs));
    super.errorInvalidIndexSet(node, error, index, rhs, arg);
  }

  @override
  errorInvalidCompoundIndexSet(Send node, ErroneousElement error, Node index,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_COMPOUND_INDEX_SET,
        error: error.messageKind, index: index, operator: operator, rhs: rhs));
    super.errorInvalidCompoundIndexSet(node, error, index, operator, rhs, arg);
  }

  @override
  errorInvalidIndexPrefix(Send node, ErroneousElement error, Node index,
      IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_INDEX_PREFIX,
        error: error.messageKind, index: index, operator: operator));
    super.errorInvalidIndexPrefix(node, error, index, operator, arg);
  }

  @override
  errorInvalidIndexPostfix(Send node, ErroneousElement error, Node index,
      IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.ERROR_INVALID_INDEX_POSTFIX,
        error: error.messageKind, index: index, operator: operator));
    super.errorInvalidIndexPostfix(node, error, index, operator, arg);
  }

  @override
  visitBinary(Send node, Node left, BinaryOperator operator, Node right, arg) {
    visits.add(new Visit(VisitKind.VISIT_BINARY,
        left: left, operator: operator, right: right));
    super.visitBinary(node, left, operator, right, arg);
  }

  @override
  errorUndefinedBinaryExpression(
      Send node, Node left, Operator operator, Node right, arg) {
    visits.add(new Visit(VisitKind.ERROR_UNDEFINED_BINARY_EXPRESSION,
        left: left, operator: operator, right: right));
    super.errorUndefinedBinaryExpression(node, left, operator, right, arg);
  }

  @override
  visitIndex(Send node, Node receiver, Node index, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_INDEX, receiver: receiver, index: index));
    apply(receiver, arg);
    apply(index, arg);
  }

  @override
  visitClassTypeLiteralGet(Send node, ConstantExpression constant, arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_GET,
        constant: constant.toDartText()));
  }

  @override
  visitClassTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_INVOKE,
        constant: constant.toDartText(), arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitClassTypeLiteralSet(
      SendSet node, ConstantExpression constant, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_SET,
        constant: constant.toDartText(), rhs: rhs));
    super.visitClassTypeLiteralSet(node, constant, rhs, arg);
  }

  @override
  visitNotEquals(Send node, Node left, Node right, arg) {
    visits.add(new Visit(VisitKind.VISIT_NOT_EQUALS, left: left, right: right));
    apply(left, arg);
    apply(right, arg);
  }

  @override
  visitDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_PREFIX,
        receiver: receiver, operator: operator, name: name));
    super.visitDynamicPropertyPrefix(node, receiver, name, operator, arg);
  }

  @override
  visitDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_POSTFIX,
        receiver: receiver, operator: operator, name: name));
    super.visitDynamicPropertyPostfix(node, receiver, name, operator, arg);
  }

  @override
  visitDynamicPropertyGet(Send node, Node receiver, Name name, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_GET,
        receiver: receiver, name: name));
    super.visitDynamicPropertyGet(node, receiver, name, arg);
  }

  @override
  visitDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_INVOKE,
        receiver: receiver, name: selector.name, arguments: arguments));
    super.visitDynamicPropertyInvoke(node, receiver, arguments, selector, arg);
  }

  @override
  visitDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_SET,
        receiver: receiver, name: name, rhs: rhs));
    super.visitDynamicPropertySet(node, receiver, name, rhs, arg);
  }

  @override
  visitDynamicTypeLiteralGet(Send node, ConstantExpression constant, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_GET,
        constant: constant.toDartText()));
  }

  @override
  visitDynamicTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_INVOKE,
        constant: constant.toDartText(), arguments: arguments));
  }

  @override
  visitDynamicTypeLiteralSet(
      Send node, ConstantExpression constant, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_SET,
        constant: constant.toDartText(), rhs: rhs));
    super.visitDynamicTypeLiteralSet(node, constant, rhs, arg);
  }

  @override
  visitExpressionInvoke(Send node, Node expression, NodeList arguments,
      CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_EXPRESSION_INVOKE,
        receiver: expression, arguments: arguments));
  }

  @override
  visitIs(Send node, Node expression, ResolutionDartType type, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_IS, expression: expression, type: type));
    apply(expression, arg);
  }

  @override
  visitIsNot(Send node, Node expression, ResolutionDartType type, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_IS_NOT, expression: expression, type: type));
    apply(expression, arg);
  }

  @override
  visitLogicalAnd(Send node, Node left, Node right, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_LOGICAL_AND, left: left, right: right));
    apply(left, arg);
    apply(right, arg);
  }

  @override
  visitLogicalOr(Send node, Node left, Node right, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOGICAL_OR, left: left, right: right));
    apply(left, arg);
    apply(right, arg);
  }

  @override
  visitLocalFunctionGet(Send node, LocalFunctionElement function, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_GET, element: function));
  }

  @override
  visitLocalFunctionSet(
      SendSet node, LocalFunctionElement function, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_SET,
        element: function, rhs: rhs));
    super.visitLocalFunctionSet(node, function, rhs, arg);
  }

  @override
  visitLocalFunctionInvoke(Send node, LocalFunctionElement function,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_INVOKE,
        element: function, arguments: arguments, selector: callStructure));
    super.visitLocalFunctionInvoke(
        node, function, arguments, callStructure, arg);
  }

  @override
  visitLocalFunctionIncompatibleInvoke(Send node, LocalFunctionElement function,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_INCOMPATIBLE_INVOKE,
        element: function, arguments: arguments, selector: callStructure));
    super.visitLocalFunctionInvoke(
        node, function, arguments, callStructure, arg);
  }

  @override
  visitLocalVariableGet(Send node, LocalVariableElement variable, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_GET, element: variable));
  }

  @override
  visitLocalVariableInvoke(Send node, LocalVariableElement variable,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_INVOKE,
        element: variable, arguments: arguments, selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_SET,
        element: variable, rhs: rhs));
    super.visitLocalVariableSet(node, variable, rhs, arg);
  }

  @override
  visitFinalLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_SET,
        element: variable, rhs: rhs));
    super.visitFinalLocalVariableSet(node, variable, rhs, arg);
  }

  @override
  visitParameterGet(Send node, ParameterElement parameter, arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_GET, element: parameter));
  }

  @override
  visitParameterInvoke(Send node, ParameterElement parameter,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_INVOKE,
        element: parameter, arguments: arguments, selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitParameterSet(SendSet node, ParameterElement parameter, Node rhs, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_PARAMETER_SET, element: parameter, rhs: rhs));
    super.visitParameterSet(node, parameter, rhs, arg);
  }

  @override
  visitFinalParameterSet(
      SendSet node, ParameterElement parameter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_PARAMETER_SET,
        element: parameter, rhs: rhs));
    super.visitFinalParameterSet(node, parameter, rhs, arg);
  }

  @override
  visitStaticFieldGet(Send node, FieldElement field, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_GET, element: field));
  }

  @override
  visitStaticFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
        element: field, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitStaticFieldSet(SendSet node, FieldElement field, Node rhs, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_STATIC_FIELD_SET, element: field, rhs: rhs));
    super.visitStaticFieldSet(node, field, rhs, arg);
  }

  @override
  visitFinalStaticFieldSet(SendSet node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
        element: field, rhs: rhs));
    super.visitFinalStaticFieldSet(node, field, rhs, arg);
  }

  @override
  visitStaticFunctionGet(Send node, MethodElement function, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_GET, element: function));
  }

  @override
  visitStaticFunctionSet(SendSet node, MethodElement function, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_SET,
        element: function, rhs: rhs));
    super.visitStaticFunctionSet(node, function, rhs, arg);
  }

  @override
  visitStaticFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
        element: function, arguments: arguments));
    super.visitStaticFunctionInvoke(
        node, function, arguments, callStructure, arg);
  }

  @override
  visitStaticFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_INCOMPATIBLE_INVOKE,
        element: function, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitStaticGetterGet(Send node, FunctionElement getter, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_GET, element: getter));
    super.visitStaticGetterGet(node, getter, arg);
  }

  @override
  visitStaticGetterSet(SendSet node, MethodElement getter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_SET,
        element: getter, rhs: rhs));
    super.visitStaticGetterSet(node, getter, rhs, arg);
  }

  @override
  visitStaticGetterInvoke(Send node, FunctionElement getter, NodeList arguments,
      CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
        element: getter, arguments: arguments));
    super.visitStaticGetterInvoke(node, getter, arguments, callStructure, arg);
  }

  @override
  visitStaticSetterInvoke(Send node, FunctionElement setter, NodeList arguments,
      CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_SETTER_INVOKE,
        element: setter, arguments: arguments));
    super.visitStaticSetterInvoke(node, setter, arguments, callStructure, arg);
  }

  @override
  visitStaticSetterGet(Send node, FunctionElement getter, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_SETTER_GET, element: getter));
    super.visitStaticSetterGet(node, getter, arg);
  }

  @override
  visitStaticSetterSet(SendSet node, FunctionElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_SETTER_SET,
        element: setter, rhs: rhs));
    super.visitStaticSetterSet(node, setter, rhs, arg);
  }

  @override
  visitSuperBinary(Send node, FunctionElement function, BinaryOperator operator,
      Node argument, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_BINARY,
        element: function, operator: operator, right: argument));
    apply(argument, arg);
  }

  @override
  visitUnresolvedSuperBinary(
      Send node, Element element, BinaryOperator operator, Node argument, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_BINARY,
        operator: operator, right: argument));
    apply(argument, arg);
  }

  @override
  visitSuperIndex(Send node, FunctionElement function, Node index, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_INDEX,
        element: function, index: index));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperIndex(Send node, Element element, Node index, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX, index: index));
    apply(index, arg);
  }

  @override
  visitSuperNotEquals(Send node, FunctionElement function, Node argument, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_NOT_EQUALS,
        element: function, right: argument));
    apply(argument, arg);
  }

  @override
  visitThisGet(Identifier node, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_GET));
  }

  @override
  visitThisInvoke(
      Send node, NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_INVOKE, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitThisPropertyGet(Send node, Name name, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_GET, name: name));
    super.visitThisPropertyGet(node, name, arg);
  }

  @override
  visitThisPropertyInvoke(
      Send node, NodeList arguments, Selector selector, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_INVOKE,
        name: selector.name, arguments: arguments));
    super.visitThisPropertyInvoke(node, arguments, selector, arg);
  }

  @override
  visitThisPropertySet(SendSet node, Name name, Node rhs, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_THIS_PROPERTY_SET, name: name, rhs: rhs));
    super.visitThisPropertySet(node, name, rhs, arg);
  }

  @override
  visitTopLevelFieldGet(Send node, FieldElement field, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_GET, element: field));
  }

  @override
  visitTopLevelFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_INVOKE,
        element: field, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTopLevelFieldSet(SendSet node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_SET,
        element: field, rhs: rhs));
    super.visitTopLevelFieldSet(node, field, rhs, arg);
  }

  @override
  visitFinalTopLevelFieldSet(SendSet node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_TOP_LEVEL_FIELD_SET,
        element: field, rhs: rhs));
    super.visitFinalTopLevelFieldSet(node, field, rhs, arg);
  }

  @override
  visitTopLevelFunctionGet(Send node, MethodElement function, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_GET, element: function));
  }

  @override
  visitTopLevelFunctionSet(
      SendSet node, MethodElement function, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_SET,
        element: function, rhs: rhs));
    super.visitTopLevelFunctionSet(node, function, rhs, arg);
  }

  @override
  visitTopLevelFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INVOKE,
        element: function, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTopLevelFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INCOMPATIBLE_INVOKE,
        element: function, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTopLevelGetterGet(Send node, FunctionElement getter, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_GET, element: getter));
    super.visitTopLevelGetterGet(node, getter, arg);
  }

  @override
  visitTopLevelSetterGet(Send node, FunctionElement setter, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_GET, element: setter));
    super.visitTopLevelSetterGet(node, setter, arg);
  }

  @override
  visitTopLevelGetterInvoke(Send node, FunctionElement getter,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_INVOKE,
        element: getter, arguments: arguments));
    super
        .visitTopLevelGetterInvoke(node, getter, arguments, callStructure, arg);
  }

  @override
  visitTopLevelSetterInvoke(Send node, FunctionElement setter,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_INVOKE,
        element: setter, arguments: arguments));
    super
        .visitTopLevelSetterInvoke(node, setter, arguments, callStructure, arg);
  }

  @override
  visitTopLevelGetterSet(SendSet node, FunctionElement getter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SET,
        element: getter, rhs: rhs));
    super.visitTopLevelGetterSet(node, getter, rhs, arg);
  }

  @override
  visitTopLevelSetterSet(SendSet node, FunctionElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_SET,
        element: setter, rhs: rhs));
    super.visitTopLevelSetterSet(node, setter, rhs, arg);
  }

  @override
  visitTypeVariableTypeLiteralGet(Send node, TypeVariableElement element, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_GET,
        element: element));
  }

  @override
  visitTypeVariableTypeLiteralInvoke(Send node, TypeVariableElement element,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_INVOKE,
        element: element, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTypeVariableTypeLiteralSet(
      SendSet node, TypeVariableElement element, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET,
        element: element, rhs: rhs));
    super.visitTypeVariableTypeLiteralSet(node, element, rhs, arg);
  }

  @override
  visitTypedefTypeLiteralGet(Send node, ConstantExpression constant, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_GET,
        constant: constant.toDartText()));
  }

  @override
  visitTypedefTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_INVOKE,
        constant: constant.toDartText(), arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTypedefTypeLiteralSet(
      SendSet node, ConstantExpression constant, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_SET,
        constant: constant.toDartText(), rhs: rhs));
    super.visitTypedefTypeLiteralSet(node, constant, rhs, arg);
  }

  @override
  visitUnary(Send node, UnaryOperator operator, Node expression, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNARY,
        expression: expression, operator: operator));
    super.visitUnary(node, operator, expression, arg);
  }

  @override
  errorUndefinedUnaryExpression(
      Send node, Operator operator, Node expression, arg) {
    visits.add(new Visit(VisitKind.ERROR_UNDEFINED_UNARY_EXPRESSION,
        expression: expression, operator: operator));
    super.errorUndefinedUnaryExpression(node, operator, expression, arg);
  }

  @override
  visitNot(Send node, Node expression, arg) {
    visits.add(new Visit(VisitKind.VISIT_NOT, expression: expression));
    apply(expression, arg);
  }

  @override
  visitSuperFieldGet(Send node, FieldElement field, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_GET, element: field));
  }

  @override
  visitUnresolvedSuperGet(Send node, Element element, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GET));
    return super.visitUnresolvedSuperGet(node, element, arg);
  }

  @override
  visitUnresolvedSuperSet(Send node, Element element, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SET, rhs: rhs));
    return super.visitUnresolvedSuperSet(node, element, rhs, arg);
  }

  @override
  visitSuperFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_INVOKE,
        element: field, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedSuperInvoke(
      Send node, Element element, NodeList arguments, Selector selector, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INVOKE,
        arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitSuperFieldSet(SendSet node, FieldElement field, Node rhs, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_SUPER_FIELD_SET, element: field, rhs: rhs));
    super.visitSuperFieldSet(node, field, rhs, arg);
  }

  @override
  visitFinalSuperFieldSet(SendSet node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_SUPER_FIELD_SET,
        element: field, rhs: rhs));
    super.visitFinalSuperFieldSet(node, field, rhs, arg);
  }

  @override
  visitSuperMethodGet(Send node, MethodElement method, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_GET, element: method));
  }

  @override
  visitSuperMethodSet(SendSet node, MethodElement method, Node rhs, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_SUPER_METHOD_SET, element: method, rhs: rhs));
    super.visitSuperMethodSet(node, method, rhs, arg);
  }

  @override
  visitSuperMethodInvoke(Send node, MethodElement method, NodeList arguments,
      CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_INVOKE,
        element: method, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitSuperMethodIncompatibleInvoke(Send node, MethodElement method,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_INCOMPATIBLE_INVOKE,
        element: method, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitSuperGetterGet(Send node, FunctionElement getter, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_GET, element: getter));
    super.visitSuperGetterGet(node, getter, arg);
  }

  @override
  visitSuperSetterGet(Send node, FunctionElement setter, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_SETTER_GET, element: setter));
    super.visitSuperSetterGet(node, setter, arg);
  }

  @override
  visitSuperGetterInvoke(Send node, FunctionElement getter, NodeList arguments,
      CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_INVOKE,
        element: getter, arguments: arguments));
    super.visitSuperGetterInvoke(node, getter, arguments, callStructure, arg);
  }

  @override
  visitSuperSetterInvoke(Send node, FunctionElement setter, NodeList arguments,
      CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_SETTER_INVOKE,
        element: setter, arguments: arguments));
    super.visitSuperSetterInvoke(node, setter, arguments, callStructure, arg);
  }

  @override
  visitSuperGetterSet(SendSet node, FunctionElement getter, Node rhs, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_SUPER_GETTER_SET, element: getter, rhs: rhs));
    super.visitSuperGetterSet(node, getter, rhs, arg);
  }

  @override
  visitSuperSetterSet(SendSet node, FunctionElement setter, Node rhs, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_SUPER_SETTER_SET, element: setter, rhs: rhs));
    super.visitSuperSetterSet(node, setter, rhs, arg);
  }

  @override
  visitSuperUnary(
      Send node, UnaryOperator operator, FunctionElement function, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_UNARY,
        element: function, operator: operator));
  }

  @override
  visitUnresolvedSuperUnary(
      Send node, UnaryOperator operator, Element element, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_UNARY, operator: operator));
  }

  @override
  visitEquals(Send node, Node left, Node right, arg) {
    visits.add(new Visit(VisitKind.VISIT_EQUALS, left: left, right: right));
    apply(left, arg);
    apply(right, arg);
  }

  @override
  visitSuperEquals(Send node, FunctionElement function, Node argument, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_EQUALS,
        element: function, right: argument));
    apply(argument, arg);
  }

  @override
  visitIndexSet(Send node, Node receiver, Node index, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_INDEX_SET,
        receiver: receiver, index: index, rhs: rhs));
    apply(receiver, arg);
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitSuperIndexSet(
      Send node, FunctionElement function, Node index, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_INDEX_SET,
        element: function, index: index, rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_COMPOUND,
        receiver: receiver, operator: operator, rhs: rhs, name: name));
    super
        .visitDynamicPropertyCompound(node, receiver, name, operator, rhs, arg);
  }

  @override
  visitFinalLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_COMPOUND,
        element: variable, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalLocalVariablePrefix(
      Send node, LocalVariableElement variable, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_PREFIX,
        element: variable, operator: operator));
  }

  @override
  visitFinalLocalVariablePostfix(
      Send node, LocalVariableElement variable, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_POSTFIX,
        element: variable, operator: operator));
  }

  @override
  visitFinalParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_PARAMETER_COMPOUND,
        element: parameter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_PARAMETER_PREFIX,
        element: parameter, operator: operator));
  }

  @override
  visitFinalParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_PARAMETER_POSTFIX,
        element: parameter, operator: operator));
  }

  @override
  visitFinalStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitFinalStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitFinalSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitFinalTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitLocalFunctionCompound(Send node, LocalFunctionElement function,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_COMPOUND,
        element: function, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_COMPOUND,
        element: variable, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_COMPOUND,
        element: parameter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitStaticGetterSetterCompound(Send node, FunctionElement getter,
      FunctionElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_COMPOUND,
        operator: operator, rhs: rhs, getter: getter, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperGetterSetterCompound(Send node, FunctionElement getter,
      FunctionElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_COMPOUND,
        operator: operator, rhs: rhs, getter: getter, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitThisPropertyCompound(
      Send node, Name name, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_COMPOUND,
        name: name, operator: operator, rhs: rhs));
    super.visitThisPropertyCompound(node, name, operator, rhs, arg);
  }

  @override
  visitTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTopLevelGetterSetterCompound(Send node, FunctionElement getter,
      FunctionElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_COMPOUND,
        operator: operator, rhs: rhs, getter: getter, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitStaticMethodSetterCompound(Send node, FunctionElement method,
      FunctionElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_COMPOUND,
        operator: operator, rhs: rhs, getter: method, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitSuperFieldSetterCompound(Send node, FieldElement field,
      FunctionElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_COMPOUND,
        operator: operator, rhs: rhs, getter: field, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitSuperGetterFieldCompound(Send node, FunctionElement getter,
      FieldElement field, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_COMPOUND,
        operator: operator, rhs: rhs, getter: getter, setter: field));
    apply(rhs, arg);
  }

  @override
  visitSuperMethodSetterCompound(Send node, FunctionElement method,
      FunctionElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_SETTER_COMPOUND,
        getter: method, setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperMethodCompound(Send node, FunctionElement method,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_COMPOUND,
        element: method, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperMethodPrefix(
      Send node, FunctionElement method, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_PREFIX,
        element: method, operator: operator));
  }

  @override
  visitSuperMethodPostfix(
      Send node, FunctionElement method, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_POSTFIX,
        element: method, operator: operator));
  }

  @override
  visitUnresolvedSuperCompound(
      Send node, Element element, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_COMPOUND,
        operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperPrefix(
      Send node, Element element, IncDecOperator operator, arg) {
    visits.add(
        new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_PREFIX, operator: operator));
  }

  @override
  visitUnresolvedSuperPostfix(
      Send node, Element element, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_POSTFIX,
        operator: operator));
  }

  @override
  visitTopLevelMethodSetterCompound(Send node, FunctionElement method,
      FunctionElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_COMPOUND,
        getter: method, setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitCompoundIndexSet(Send node, Node receiver, Node index,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_COMPOUND_INDEX_SET,
        receiver: receiver, index: index, rhs: rhs, operator: operator));
    apply(receiver, arg);
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitSuperCompoundIndexSet(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_COMPOUND_INDEX_SET,
        getter: getter,
        setter: setter,
        index: index,
        rhs: rhs,
        operator: operator));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitClassTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_COMPOUND,
        constant: constant.toDartText(), operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitDynamicTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_COMPOUND,
        constant: constant.toDartText(), operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTypeVariableTypeLiteralCompound(Send node, TypeVariableElement element,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_COMPOUND,
        element: element, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTypedefTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_COMPOUND,
        constant: constant.toDartText(), operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitLocalFunctionPrefix(
      Send node, LocalFunctionElement function, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_PREFIX,
        element: function, operator: operator));
  }

  @override
  visitClassTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_PREFIX,
        constant: constant.toDartText(), operator: operator));
  }

  @override
  visitDynamicTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_PREFIX,
        constant: constant.toDartText(), operator: operator));
  }

  @override
  visitLocalVariablePrefix(
      Send node, LocalVariableElement variable, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_PREFIX,
        element: variable, operator: operator));
  }

  @override
  visitParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_PREFIX,
        element: parameter, operator: operator));
  }

  @override
  visitStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitStaticGetterSetterPrefix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_PREFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitStaticMethodSetterPrefix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_PREFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitSuperFieldFieldCompound(Send node, FieldElement readField,
      FieldElement writtenField, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_FIELD_COMPOUND,
        getter: readField, setter: writtenField, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperFieldFieldPrefix(Send node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_FIELD_PREFIX,
        getter: readField, setter: writtenField, operator: operator));
  }

  @override
  visitSuperFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitFinalSuperFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitSuperFieldSetterPrefix(Send node, FieldElement field,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_PREFIX,
        getter: field, setter: setter, operator: operator));
  }

  @override
  visitSuperGetterFieldPrefix(Send node, FunctionElement getter,
      FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_PREFIX,
        getter: getter, setter: field, operator: operator));
  }

  @override
  visitSuperGetterSetterPrefix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_PREFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitSuperMethodSetterPrefix(Send node, FunctionElement method,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_SETTER_PREFIX,
        getter: method, setter: setter, operator: operator));
  }

  @override
  visitThisPropertyPrefix(Send node, Name name, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_PREFIX,
        name: name, operator: operator));
    super.visitThisPropertyPrefix(node, name, operator, arg);
  }

  @override
  visitTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitTopLevelGetterSetterPrefix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_PREFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitTopLevelMethodSetterPrefix(Send node, FunctionElement method,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_PREFIX,
        getter: method, setter: setter, operator: operator));
  }

  @override
  visitTypeVariableTypeLiteralPrefix(
      Send node, TypeVariableElement element, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_PREFIX,
        element: element, operator: operator));
  }

  @override
  visitTypedefTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_PREFIX,
        constant: constant.toDartText(), operator: operator));
  }

  @override
  visitLocalFunctionPostfix(
      Send node, LocalFunctionElement function, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_POSTFIX,
        element: function, operator: operator));
  }

  @override
  visitClassTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_POSTFIX,
        constant: constant.toDartText(), operator: operator));
  }

  @override
  visitDynamicTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_POSTFIX,
        constant: constant.toDartText(), operator: operator));
  }

  @override
  visitLocalVariablePostfix(
      Send node, LocalVariableElement variable, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_POSTFIX,
        element: variable, operator: operator));
  }

  @override
  visitParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_POSTFIX,
        element: parameter, operator: operator));
  }

  @override
  visitStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitStaticGetterSetterPostfix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_POSTFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitStaticMethodSetterPostfix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_POSTFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitSuperFieldFieldPostfix(Send node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_FIELD_POSTFIX,
        getter: readField, setter: writtenField, operator: operator));
  }

  @override
  visitSuperFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitFinalSuperFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitSuperFieldSetterPostfix(Send node, FieldElement field,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_POSTFIX,
        getter: field, setter: setter, operator: operator));
  }

  @override
  visitSuperGetterFieldPostfix(Send node, FunctionElement getter,
      FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_POSTFIX,
        getter: getter, setter: field, operator: operator));
  }

  @override
  visitSuperGetterSetterPostfix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_POSTFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitSuperMethodSetterPostfix(Send node, FunctionElement method,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_SETTER_POSTFIX,
        getter: method, setter: setter, operator: operator));
  }

  @override
  visitThisPropertyPostfix(Send node, Name name, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_POSTFIX,
        name: name, operator: operator));
    super.visitThisPropertyPostfix(node, name, operator, arg);
  }

  @override
  visitTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitTopLevelGetterSetterPostfix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_POSTFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitTopLevelMethodSetterPostfix(Send node, FunctionElement method,
      FunctionElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_POSTFIX,
        getter: method, setter: setter, operator: operator));
  }

  @override
  visitTypeVariableTypeLiteralPostfix(
      Send node, TypeVariableElement element, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_POSTFIX,
        element: element, operator: operator));
  }

  @override
  visitTypedefTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_POSTFIX,
        constant: constant.toDartText(), operator: operator));
  }

  @override
  visitUnresolvedCompound(Send node, ErroneousElement element,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_COMPOUND,
        operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedGet(Send node, Element element, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_GET, name: element.name));
  }

  @override
  visitUnresolvedSet(Send node, Element element, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SET,
        name: element.name, rhs: rhs));
    super.visitUnresolvedSet(node, element, rhs, arg);
  }

  @override
  visitUnresolvedInvoke(
      Send node, Element element, NodeList arguments, Selector selector, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
        name: element.name, arguments: arguments));
    super.visitUnresolvedInvoke(node, element, arguments, selector, arg);
  }

  @override
  visitUnresolvedPostfix(
      Send node, ErroneousElement element, IncDecOperator operator, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_UNRESOLVED_POSTFIX, operator: operator));
  }

  @override
  visitUnresolvedPrefix(
      Send node, ErroneousElement element, IncDecOperator operator, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_UNRESOLVED_PREFIX, operator: operator));
  }

  @override
  visitUnresolvedSuperCompoundIndexSet(Send node, Element element, Node index,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_COMPOUND_INDEX_SET,
        index: index, operator: operator, rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperGetterCompoundIndexSet(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND_INDEX_SET,
        setter: setter,
        index: index,
        operator: operator,
        rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperSetterCompoundIndexSet(Send node, MethodElement getter,
      Element element, Node index, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND_INDEX_SET,
        getter: getter,
        index: index,
        operator: operator,
        rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperIndexSet(
      Send node, ErroneousElement element, Node index, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_SET,
        index: index, rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperIndexPostfix(
      Send node, Element element, Node index, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_POSTFIX,
        index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperGetterIndexPostfix(Send node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_INDEX_POSTFIX,
        setter: setter, index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperSetterIndexPostfix(Send node, MethodElement getter,
      Element element, Node index, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_INDEX_POSTFIX,
        getter: getter, index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperIndexPrefix(
      Send node, Element element, Node index, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_PREFIX,
        index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperGetterIndexPrefix(Send node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_INDEX_PREFIX,
        setter: setter, index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperSetterIndexPrefix(Send node, MethodElement getter,
      Element element, Node index, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_INDEX_PREFIX,
        getter: getter, index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitIndexPostfix(
      Send node, Node receiver, Node index, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_INDEX_POSTFIX,
        receiver: receiver, index: index, operator: operator));
    apply(receiver, arg);
    apply(index, arg);
  }

  @override
  visitIndexPrefix(
      Send node, Node receiver, Node index, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_INDEX_PREFIX,
        receiver: receiver, index: index, operator: operator));
    apply(receiver, arg);
    apply(index, arg);
  }

  @override
  visitSuperIndexPostfix(
      Send node,
      FunctionElement indexFunction,
      FunctionElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_INDEX_POSTFIX,
        getter: indexFunction,
        setter: indexSetFunction,
        index: index,
        operator: operator));
    apply(index, arg);
  }

  @override
  visitSuperIndexPrefix(
      Send node,
      FunctionElement indexFunction,
      FunctionElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_INDEX_PREFIX,
        getter: indexFunction,
        setter: indexSetFunction,
        index: index,
        operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedClassConstructorInvoke(NewExpression node, Element constructor,
      ResolutionDartType type, NodeList arguments, Selector selector, arg) {
    // TODO(johnniwinther): Test [type] when it is not `dynamic`.
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE,
        arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedConstructorInvoke(NewExpression node, Element constructor,
      ResolutionDartType type, NodeList arguments, Selector selector, arg) {
    // TODO(johnniwinther): Test [type] when it is not `dynamic`.
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_CONSTRUCTOR_INVOKE,
        arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitConstConstructorInvoke(
      NewExpression node, ConstructedConstantExpression constant, arg) {
    visits.add(new Visit(VisitKind.VISIT_CONST_CONSTRUCTOR_INVOKE,
        constant: constant.toDartText()));
    super.visitConstConstructorInvoke(node, constant, arg);
  }

  @override
  visitBoolFromEnvironmentConstructorInvoke(
      NewExpression node, BoolFromEnvironmentConstantExpression constant, arg) {
    visits.add(new Visit(
        VisitKind.VISIT_BOOL_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
        constant: constant.toDartText()));
    super.visitBoolFromEnvironmentConstructorInvoke(node, constant, arg);
  }

  @override
  visitIntFromEnvironmentConstructorInvoke(
      NewExpression node, IntFromEnvironmentConstantExpression constant, arg) {
    visits.add(new Visit(
        VisitKind.VISIT_INT_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
        constant: constant.toDartText()));
    super.visitIntFromEnvironmentConstructorInvoke(node, constant, arg);
  }

  @override
  visitStringFromEnvironmentConstructorInvoke(NewExpression node,
      StringFromEnvironmentConstantExpression constant, arg) {
    visits.add(new Visit(
        VisitKind.VISIT_STRING_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
        constant: constant.toDartText()));
    super.visitStringFromEnvironmentConstructorInvoke(node, constant, arg);
  }

  @override
  errorNonConstantConstructorInvoke(
      NewExpression node,
      Element element,
      ResolutionDartType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_NON_CONSTANT_CONSTRUCTOR_INVOKE,
        element: element,
        type: type,
        arguments: arguments,
        selector: callStructure));
    super.errorNonConstantConstructorInvoke(
        node, element, type, arguments, callStructure, arg);
  }

  @override
  visitConstructorIncompatibleInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CONSTRUCTOR_INCOMPATIBLE_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    super.visitConstructorIncompatibleInvoke(
        node, constructor, type, arguments, callStructure, arg);
  }

  @override
  visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      ConstructorElement effectiveTarget,
      ResolutionInterfaceType effectiveTargetType,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        target: effectiveTarget,
        targetType: effectiveTargetType,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedStaticGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_COMPOUND,
        setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedTopLevelGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_COMPOUND,
        setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedStaticSetterCompound(Send node, MethodElement getter,
      Element element, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_COMPOUND,
        getter: getter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedTopLevelSetterCompound(Send node, MethodElement getter,
      Element element, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_COMPOUND,
        getter: getter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitStaticMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_COMPOUND,
        element: method, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTopLevelMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_COMPOUND,
        element: method, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedStaticGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_PREFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedTopLevelGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_PREFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedStaticSetterPrefix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_PREFIX,
        getter: getter, operator: operator));
  }

  @override
  visitUnresolvedTopLevelSetterPrefix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_PREFIX,
        getter: getter, operator: operator));
  }

  @override
  visitStaticMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_PREFIX,
        element: method, operator: operator));
  }

  @override
  visitTopLevelMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_PREFIX,
        element: method, operator: operator));
  }

  @override
  visitUnresolvedStaticGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_POSTFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedTopLevelGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_POSTFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedStaticSetterPostfix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_POSTFIX,
        getter: getter, operator: operator));
  }

  @override
  visitUnresolvedTopLevelSetterPostfix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_POSTFIX,
        getter: getter, operator: operator));
  }

  @override
  visitStaticMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_POSTFIX,
        element: method, operator: operator));
  }

  @override
  visitTopLevelMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_POSTFIX,
        element: method, operator: operator));
  }

  @override
  visitUnresolvedSuperGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND,
        setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_POSTFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedSuperGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_PREFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedSuperSetterCompound(Send node, MethodElement getter,
      Element element, AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND,
        getter: getter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperSetterPostfix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_POSTFIX,
        getter: getter, operator: operator));
  }

  @override
  visitUnresolvedSuperSetterPrefix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_PREFIX,
        getter: getter, operator: operator));
  }

  @override
  visitIfNotNullDynamicPropertyGet(Send node, Node receiver, Name name, arg) {
    visits.add(new Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_GET,
        receiver: receiver, name: name));
    super.visitIfNotNullDynamicPropertyGet(node, receiver, name, arg);
  }

  @override
  visitIfNotNullDynamicPropertySet(
      Send node, Node receiver, Name name, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_SET,
        receiver: receiver, name: name, rhs: rhs));
    super.visitIfNotNullDynamicPropertySet(node, receiver, name, rhs, arg);
  }

  @override
  visitIfNotNullDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, arg) {
    visits.add(new Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_INVOKE,
        receiver: receiver, selector: selector, arguments: arguments));
    super.visitIfNotNullDynamicPropertyInvoke(
        node, receiver, arguments, selector, arg);
  }

  @override
  visitIfNotNullDynamicPropertyPrefix(
      Send node, Node receiver, Name name, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_PREFIX,
        receiver: receiver, name: name, operator: operator));
    super.visitIfNotNullDynamicPropertyPrefix(
        node, receiver, name, operator, arg);
  }

  @override
  visitIfNotNullDynamicPropertyPostfix(
      Send node, Node receiver, Name name, IncDecOperator operator, arg) {
    visits.add(new Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_POSTFIX,
        receiver: receiver, name: name, operator: operator));
    super.visitIfNotNullDynamicPropertyPostfix(
        node, receiver, name, operator, arg);
  }

  @override
  visitIfNotNullDynamicPropertyCompound(Send node, Node receiver, Name name,
      AssignmentOperator operator, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_COMPOUND,
        receiver: receiver, name: name, operator: operator, rhs: rhs));
    super.visitIfNotNullDynamicPropertyCompound(
        node, receiver, name, operator, rhs, arg);
  }

  @override
  visitIfNull(Send node, Node left, Node right, arg) {
    visits.add(new Visit(VisitKind.VISIT_IF_NULL, left: left, right: right));
    super.visitIfNull(node, left, right, arg);
  }

  @override
  visitConstantGet(Send node, ConstantExpression constant, arg) {
    visits.add(new Visit(VisitKind.VISIT_CONSTANT_GET,
        constant: constant.toDartText()));
    super.visitConstantGet(node, constant, arg);
  }

  @override
  visitConstantInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_CONSTANT_INVOKE,
        constant: constant.toDartText()));
    super.visitConstantInvoke(node, constant, arguments, callStructure, arg);
  }

  @override
  previsitDeferredAccess(Send node, PrefixElement prefix, arg) {
    visits.add(new Visit(VisitKind.PREVISIT_DEFERRED_ACCESS, element: prefix));
  }

  @override
  visitClassTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_SET_IF_NULL,
        constant: constant.toDartText(), rhs: rhs));
    super.visitClassTypeLiteralSetIfNull(node, constant, rhs, arg);
  }

  @override
  visitDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_SET_IF_NULL,
        receiver: receiver, name: name, rhs: rhs));
    super.visitDynamicPropertySetIfNull(node, receiver, name, rhs, arg);
  }

  @override
  visitDynamicTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_SET_IF_NULL,
        constant: constant.toDartText(), rhs: rhs));
    super.visitDynamicTypeLiteralSetIfNull(node, constant, rhs, arg);
  }

  @override
  visitFinalLocalVariableSetIfNull(
      Send node, LocalVariableElement variable, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_SET_IF_NULL,
        element: variable, rhs: rhs));
    super.visitFinalLocalVariableSetIfNull(node, variable, rhs, arg);
  }

  @override
  visitFinalParameterSetIfNull(
      Send node, ParameterElement parameter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_PARAMETER_SET_IF_NULL,
        element: parameter, rhs: rhs));
    super.visitFinalParameterSetIfNull(node, parameter, rhs, arg);
  }

  @override
  visitFinalStaticFieldSetIfNull(Send node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_SET_IF_NULL,
        element: field, rhs: rhs));
    super.visitFinalStaticFieldSetIfNull(node, field, rhs, arg);
  }

  @override
  visitFinalSuperFieldSetIfNull(Send node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_SET_IF_NULL,
        element: field, rhs: rhs));
    super.visitFinalSuperFieldSetIfNull(node, field, rhs, arg);
  }

  @override
  visitFinalTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_SET_IF_NULL,
        element: field, rhs: rhs));
    super.visitFinalTopLevelFieldSetIfNull(node, field, rhs, arg);
  }

  @override
  visitIfNotNullDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, arg) {
    visits.add(new Visit(
        VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_SET_IF_NULL,
        receiver: receiver,
        name: name,
        rhs: rhs));
    super
        .visitIfNotNullDynamicPropertySetIfNull(node, receiver, name, rhs, arg);
  }

  @override
  visitLocalFunctionSetIfNull(
      Send node, LocalFunctionElement function, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_SET_IF_NULL,
        element: function, rhs: rhs));
    super.visitLocalFunctionSetIfNull(node, function, rhs, arg);
  }

  @override
  visitLocalVariableSetIfNull(
      Send node, LocalVariableElement variable, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_SET_IF_NULL,
        element: variable, rhs: rhs));
    super.visitLocalVariableSetIfNull(node, variable, rhs, arg);
  }

  @override
  visitParameterSetIfNull(
      Send node, ParameterElement parameter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_SET_IF_NULL,
        element: parameter, rhs: rhs));
    super.visitParameterSetIfNull(node, parameter, rhs, arg);
  }

  @override
  visitStaticFieldSetIfNull(Send node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_SET_IF_NULL,
        element: field, rhs: rhs));
    super.visitStaticFieldSetIfNull(node, field, rhs, arg);
  }

  @override
  visitStaticGetterSetterSetIfNull(Send node, FunctionElement getter,
      FunctionElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_SET_IF_NULL,
        getter: getter, setter: setter, rhs: rhs));
    super.visitStaticGetterSetterSetIfNull(node, getter, setter, rhs, arg);
  }

  @override
  visitStaticMethodSetIfNull(Send node, FunctionElement method, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_SET_IF_NULL,
        element: method, rhs: rhs));
    super.visitStaticMethodSetIfNull(node, method, rhs, arg);
  }

  @override
  visitStaticMethodSetterSetIfNull(
      Send node, MethodElement method, MethodElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_SET_IF_NULL,
        getter: method, setter: setter, rhs: rhs));
    super.visitStaticMethodSetterSetIfNull(node, method, setter, rhs, arg);
  }

  @override
  visitSuperFieldFieldSetIfNull(Send node, FieldElement readField,
      FieldElement writtenField, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_FIELD_SET_IF_NULL,
        getter: readField, setter: writtenField, rhs: rhs));
    super
        .visitSuperFieldFieldSetIfNull(node, readField, writtenField, rhs, arg);
  }

  @override
  visitSuperFieldSetIfNull(Send node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_SET_IF_NULL,
        element: field, rhs: rhs));
    super.visitSuperFieldSetIfNull(node, field, rhs, arg);
  }

  @override
  visitSuperFieldSetterSetIfNull(
      Send node, FieldElement field, FunctionElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_SET_IF_NULL,
        getter: field, setter: setter, rhs: rhs));
    super.visitSuperFieldSetterSetIfNull(node, field, setter, rhs, arg);
  }

  @override
  visitSuperGetterFieldSetIfNull(
      Send node, FunctionElement getter, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_SET_IF_NULL,
        getter: getter, setter: field, rhs: rhs));
    super.visitSuperGetterFieldSetIfNull(node, getter, field, rhs, arg);
  }

  @override
  visitSuperGetterSetterSetIfNull(Send node, FunctionElement getter,
      FunctionElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_SET_IF_NULL,
        getter: getter, setter: setter, rhs: rhs));
    super.visitSuperGetterSetterSetIfNull(node, getter, setter, rhs, arg);
  }

  @override
  visitSuperMethodSetIfNull(Send node, FunctionElement method, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_SET_IF_NULL,
        element: method, rhs: rhs));
    super.visitSuperMethodSetIfNull(node, method, rhs, arg);
  }

  @override
  visitSuperMethodSetterSetIfNull(Send node, FunctionElement method,
      FunctionElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_SETTER_SET_IF_NULL,
        getter: method, setter: setter, rhs: rhs));
    super.visitSuperMethodSetterSetIfNull(node, method, setter, rhs, arg);
  }

  @override
  visitThisPropertySetIfNull(Send node, Name name, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_SET_IF_NULL,
        name: name, rhs: rhs));
    super.visitThisPropertySetIfNull(node, name, rhs, arg);
  }

  @override
  visitTopLevelFieldSetIfNull(Send node, FieldElement field, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_SET_IF_NULL,
        element: field, rhs: rhs));
    super.visitTopLevelFieldSetIfNull(node, field, rhs, arg);
  }

  @override
  visitTopLevelGetterSetterSetIfNull(Send node, FunctionElement getter,
      FunctionElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_SET_IF_NULL,
        getter: getter, setter: setter, rhs: rhs));
    super.visitTopLevelGetterSetterSetIfNull(node, getter, setter, rhs, arg);
  }

  @override
  visitTopLevelMethodSetIfNull(
      Send node, FunctionElement method, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_SET_IF_NULL,
        element: method, rhs: rhs));
    super.visitTopLevelMethodSetIfNull(node, method, rhs, arg);
  }

  @override
  visitTopLevelMethodSetterSetIfNull(Send node, FunctionElement method,
      FunctionElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_SET_IF_NULL,
        getter: method, setter: setter, rhs: rhs));
    super.visitTopLevelMethodSetterSetIfNull(node, method, setter, rhs, arg);
  }

  @override
  visitTypeVariableTypeLiteralSetIfNull(
      Send node, TypeVariableElement element, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET_IF_NULL,
        element: element, rhs: rhs));
    super.visitTypeVariableTypeLiteralSetIfNull(node, element, rhs, arg);
  }

  @override
  visitTypedefTypeLiteralSetIfNull(
      Send node, ConstantExpression constant, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_SET_IF_NULL,
        constant: constant.toDartText(), rhs: rhs));
    super.visitTypedefTypeLiteralSetIfNull(node, constant, rhs, arg);
  }

  @override
  visitUnresolvedSetIfNull(Send node, Element element, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SET_IF_NULL,
        name: element.name, rhs: rhs));
    super.visitUnresolvedSetIfNull(node, element, rhs, arg);
  }

  @override
  visitUnresolvedStaticGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_SET_IF_NULL,
        setter: setter, rhs: rhs));
    super.visitUnresolvedStaticGetterSetIfNull(node, element, setter, rhs, arg);
  }

  @override
  visitUnresolvedStaticSetterSetIfNull(
      Send node, MethodElement getter, Element element, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_SET_IF_NULL,
        getter: getter, rhs: rhs));
    super.visitUnresolvedStaticSetterSetIfNull(node, getter, element, rhs, arg);
  }

  @override
  visitUnresolvedSuperGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_SET_IF_NULL,
        setter: setter, rhs: rhs));
    super.visitUnresolvedSuperGetterSetIfNull(node, element, setter, rhs, arg);
  }

  @override
  visitUnresolvedSuperSetIfNull(Send node, Element element, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SET_IF_NULL,
        name: element.name, rhs: rhs));
    super.visitUnresolvedSuperSetIfNull(node, element, rhs, arg);
  }

  @override
  visitUnresolvedSuperSetterSetIfNull(
      Send node, MethodElement getter, Element element, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_SET_IF_NULL,
        getter: getter, rhs: rhs));
    super.visitUnresolvedSuperSetterSetIfNull(node, getter, element, rhs, arg);
  }

  @override
  visitUnresolvedTopLevelGetterSetIfNull(
      Send node, Element element, MethodElement setter, Node rhs, arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_SET_IF_NULL,
        setter: setter,
        rhs: rhs));
    super.visitUnresolvedTopLevelGetterSetIfNull(
        node, element, setter, rhs, arg);
  }

  @override
  visitUnresolvedTopLevelSetterSetIfNull(
      Send node, MethodElement getter, Element element, Node rhs, arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_SET_IF_NULL,
        getter: getter,
        rhs: rhs));
    super.visitUnresolvedTopLevelSetterSetIfNull(
        node, getter, element, rhs, arg);
  }

  @override
  visitIndexSetIfNull(SendSet node, Node receiver, Node index, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_INDEX_SET_IF_NULL,
        receiver: receiver, index: index, rhs: rhs));
    super.visitIndexSetIfNull(node, receiver, index, rhs, arg);
  }

  @override
  visitSuperIndexSetIfNull(SendSet node, MethodElement getter,
      MethodElement setter, Node index, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_INDEX_SET_IF_NULL,
        getter: getter, setter: setter, index: index, rhs: rhs));
    super.visitSuperIndexSetIfNull(node, getter, setter, index, rhs, arg);
  }

  @override
  visitUnresolvedSuperGetterIndexSetIfNull(Send node, Element element,
      MethodElement setter, Node index, Node rhs, arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_INDEX_SET_IF_NULL,
        setter: setter,
        index: index,
        rhs: rhs));
    super.visitUnresolvedSuperGetterIndexSetIfNull(
        node, element, setter, index, rhs, arg);
  }

  @override
  visitUnresolvedSuperSetterIndexSetIfNull(Send node, MethodElement getter,
      Element element, Node index, Node rhs, arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_INDEX_SET_IF_NULL,
        getter: getter,
        index: index,
        rhs: rhs));
    super.visitUnresolvedSuperSetterIndexSetIfNull(
        node, getter, element, index, rhs, arg);
  }

  @override
  visitUnresolvedSuperIndexSetIfNull(
      Send node, Element element, Node index, Node rhs, arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_SET_IF_NULL,
        index: index, rhs: rhs));
    super.visitUnresolvedSuperIndexSetIfNull(node, element, index, rhs, arg);
  }

  @override
  errorInvalidIndexSetIfNull(
      SendSet node, ErroneousElement error, Node index, Node rhs, arg) {
    visits.add(
        new Visit(VisitKind.ERROR_INVALID_SET_IF_NULL, index: index, rhs: rhs));
    super.visitUnresolvedSuperIndexSetIfNull(node, error, index, rhs, arg);
  }
}
