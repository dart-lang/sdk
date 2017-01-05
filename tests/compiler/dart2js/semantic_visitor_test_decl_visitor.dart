// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.semantics_visitor_test;

class SemanticDeclarationTestVisitor extends SemanticTestVisitor {
  SemanticDeclarationTestVisitor(TreeElements elements) : super(elements);

  @override
  errorUnresolvedSuperConstructorInvoke(
      Send node, Element element, NodeList arguments, Selector selector, arg) {
    // TODO: implement errorUnresolvedSuperConstructorInvoke
  }

  @override
  errorUnresolvedThisConstructorInvoke(
      Send node, Element element, NodeList arguments, Selector selector, arg) {
    // TODO: implement errorUnresolvedThisConstructorInvoke
  }

  @override
  visitAbstractMethodDeclaration(
      FunctionExpression node, MethodElement method, NodeList parameters, arg) {
    visits.add(new Visit(VisitKind.VISIT_ABSTRACT_METHOD_DECL,
        element: method, parameters: parameters));
    applyParameters(parameters, arg);
  }

  @override
  visitClosureDeclaration(FunctionExpression node,
      LocalFunctionElement function, NodeList parameters, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_CLOSURE_DECL,
        element: function, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitFactoryConstructorDeclaration(FunctionExpression node,
      ConstructorElement constructor, NodeList parameters, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_FACTORY_CONSTRUCTOR_DECL,
        element: constructor, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitFieldInitializer(
      SendSet node, FieldElement field, Node initializer, arg) {
    visits.add(new Visit(VisitKind.VISIT_FIELD_INITIALIZER,
        element: field, rhs: initializer));
    apply(initializer, arg);
  }

  @override
  visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
        element: constructor, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    applyInitializers(node, arg);
    apply(body, arg);
  }

  @override
  visitInstanceMethodDeclaration(FunctionExpression node, MethodElement method,
      NodeList parameters, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_INSTANCE_METHOD_DECL,
        element: method, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitLocalFunctionDeclaration(FunctionExpression node,
      LocalFunctionElement function, NodeList parameters, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_DECL,
        element: function, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      ResolutionInterfaceType redirectionType,
      ConstructorElement redirectionTarget,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
        element: constructor,
        parameters: parameters,
        target: redirectionTarget,
        type: redirectionType));
    applyParameters(parameters, arg);
  }

  @override
  visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_DECL,
        element: constructor,
        parameters: parameters,
        initializers: initializers));
    applyParameters(parameters, arg);
    applyInitializers(node, arg);
  }

  @override
  visitStaticFunctionDeclaration(FunctionExpression node,
      MethodElement function, NodeList parameters, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_DECL,
        element: function, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      ResolutionInterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_CONSTRUCTOR_INVOKE,
        element: superConstructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    super.visitSuperConstructorInvoke(
        node, superConstructor, type, arguments, callStructure, arg);
  }

  @override
  visitImplicitSuperConstructorInvoke(FunctionExpression node,
      ConstructorElement superConstructor, ResolutionInterfaceType type, arg) {
    visits.add(new Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
        element: superConstructor, type: type));
    super
        .visitImplicitSuperConstructorInvoke(node, superConstructor, type, arg);
  }

  @override
  visitThisConstructorInvoke(Send node, ConstructorElement thisConstructor,
      NodeList arguments, CallStructure callStructure, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_CONSTRUCTOR_INVOKE,
        element: thisConstructor,
        arguments: arguments,
        selector: callStructure));
    super.visitThisConstructorInvoke(
        node, thisConstructor, arguments, callStructure, arg);
  }

  @override
  visitTopLevelFunctionDeclaration(FunctionExpression node,
      MethodElement function, NodeList parameters, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
        element: function, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  errorUnresolvedFieldInitializer(
      SendSet node, Element element, Node initializer, arg) {
    // TODO: implement errorUnresolvedFieldInitializer
  }

  @override
  visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_OPTIONAL_PARAMETER_DECL,
        element: parameter,
        constant: defaultValue != null ? defaultValue.toDartText() : null,
        index: index));
  }

  @override
  visitParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, int index, arg) {
    visits.add(new Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
        element: parameter, index: index));
  }

  @override
  visitInitializingFormalDeclaration(VariableDefinitions node, Node definition,
      InitializingFormalElement initializingFormal, int index, arg) {
    visits.add(new Visit(VisitKind.VISIT_REQUIRED_INITIALIZING_FORMAL_DECL,
        element: initializingFormal, index: index));
  }

  @override
  visitLocalVariableDeclaration(VariableDefinitions node, Node definition,
      LocalVariableElement variable, Node initializer, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
        element: variable, rhs: initializer));
    if (initializer != null) {
      apply(initializer, arg);
    }
  }

  @override
  visitLocalConstantDeclaration(VariableDefinitions node, Node definition,
      LocalVariableElement variable, ConstantExpression constant, arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_CONSTANT_DECL,
        element: variable, constant: constant.toDartText()));
  }

  @override
  visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement initializingFormal,
      ConstantExpression defaultValue,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_NAMED_INITIALIZING_FORMAL_DECL,
        element: initializingFormal,
        constant: defaultValue != null ? defaultValue.toDartText() : null));
  }

  @override
  visitNamedParameterDeclaration(VariableDefinitions node, Node definition,
      ParameterElement parameter, ConstantExpression defaultValue, arg) {
    visits.add(new Visit(VisitKind.VISIT_NAMED_PARAMETER_DECL,
        element: parameter,
        constant: defaultValue != null ? defaultValue.toDartText() : null));
  }

  @override
  visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement initializingFormal,
      ConstantExpression defaultValue,
      int index,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_OPTIONAL_INITIALIZING_FORMAL_DECL,
        element: initializingFormal,
        constant: defaultValue != null ? defaultValue.toDartText() : null,
        index: index));
  }

  @override
  visitInstanceFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, arg) {
    visits.add(new Visit(VisitKind.VISIT_INSTANCE_FIELD_DECL,
        element: field, rhs: initializer));
    if (initializer != null) {
      apply(initializer, arg);
    }
  }

  @override
  visitStaticConstantDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, ConstantExpression constant, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_CONSTANT_DECL,
        element: field, constant: constant.toDartText()));
  }

  @override
  visitStaticFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
        element: field, rhs: initializer));
    if (initializer != null) {
      apply(initializer, arg);
    }
  }

  @override
  visitTopLevelConstantDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, ConstantExpression constant, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_CONSTANT_DECL,
        element: field, constant: constant.toDartText()));
  }

  @override
  visitTopLevelFieldDeclaration(VariableDefinitions node, Node definition,
      FieldElement field, Node initializer, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_DECL,
        element: field, rhs: initializer));
    if (initializer != null) {
      apply(initializer, arg);
    }
  }

  @override
  visitAbstractGetterDeclaration(
      FunctionExpression node, MethodElement getter, arg) {
    visits
        .add(new Visit(VisitKind.VISIT_ABSTRACT_GETTER_DECL, element: getter));
  }

  @override
  visitAbstractSetterDeclaration(
      FunctionExpression node, MethodElement setter, NodeList parameters, arg) {
    visits.add(new Visit(VisitKind.VISIT_ABSTRACT_SETTER_DECL,
        element: setter, parameters: parameters));
    applyParameters(parameters, arg);
  }

  @override
  visitInstanceGetterDeclaration(
      FunctionExpression node, MethodElement getter, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_INSTANCE_GETTER_DECL,
        element: getter, body: body));
    apply(body, arg);
  }

  @override
  visitInstanceSetterDeclaration(FunctionExpression node, MethodElement setter,
      NodeList parameters, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_INSTANCE_SETTER_DECL,
        element: setter, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitTopLevelGetterDeclaration(
      FunctionExpression node, MethodElement getter, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_DECL,
        element: getter, body: body));
    apply(body, arg);
  }

  @override
  visitTopLevelSetterDeclaration(FunctionExpression node, MethodElement setter,
      NodeList parameters, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_DECL,
        element: setter, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitStaticGetterDeclaration(
      FunctionExpression node, MethodElement getter, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_DECL,
        element: getter, body: body));
    apply(body, arg);
  }

  @override
  visitStaticSetterDeclaration(FunctionExpression node, MethodElement setter,
      NodeList parameters, Node body, arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_SETTER_DECL,
        element: setter, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }
}
