// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/**
 * Concrete implementation of [ResolutionMap] based on the standard AST
 * implementation.
 */
class ResolutionMapImpl implements ResolutionMap {
  @override
  ExecutableElement bestElementForFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      node.bestElement;

  @override
  Element bestElementForIdentifier(Identifier node) => node.bestElement;

  @override
  MethodElement bestElementForMethodReference(MethodReferenceExpression node) =>
      node.bestElement;

  @override
  ParameterElement bestParameterElementForExpression(Expression node) =>
      node.bestParameterElement;

  @override
  DartType bestTypeForExpression(Expression node) => node.bestType;

  @override
  ElementAnnotation elementAnnotationForAnnotation(Annotation node) =>
      node.elementAnnotation;

  @override
  ClassElement elementDeclaredByClassDeclaration(ClassDeclaration node) =>
      node.element;

  @override
  CompilationUnitElement elementDeclaredByCompilationUnit(
          CompilationUnit node) =>
      node.element;

  @override
  ConstructorElement elementDeclaredByConstructorDeclaration(
          ConstructorDeclaration node) =>
      node.element;

  @override
  Element elementDeclaredByDeclaration(Declaration node) => node.element;

  @override
  LocalVariableElement elementDeclaredByDeclaredIdentifier(
          DeclaredIdentifier node) =>
      node.element;

  @override
  Element elementDeclaredByDirective(Directive node) => node.element;

  @override
  ClassElement elementDeclaredByEnumDeclaration(EnumDeclaration node) =>
      node.element;

  @override
  ParameterElement elementDeclaredByFormalParameter(FormalParameter node) =>
      node.element;

  @override
  ExecutableElement elementDeclaredByFunctionDeclaration(
          FunctionDeclaration node) =>
      node.element;

  @override
  ExecutableElement elementDeclaredByFunctionExpression(
          FunctionExpression node) =>
      node.element;

  @override
  ExecutableElement elementDeclaredByMethodDeclaration(
          MethodDeclaration node) =>
      node.element;

  @override
  VariableElement elementDeclaredByVariableDeclaration(
          VariableDeclaration node) =>
      node.element;

  @override
  Element elementForAnnotation(Annotation node) => node.element;

  @override
  ParameterElement elementForNamedExpression(NamedExpression node) =>
      node.element;

  @override
  List<ParameterElement> parameterElementsForFormalParameterList(
          FormalParameterList node) =>
      node.parameterElements;

  @override
  ExecutableElement propagatedElementForFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      node.propagatedElement;

  @override
  Element propagatedElementForIdentifier(Identifier node) =>
      node.propagatedElement;

  @override
  MethodElement propagatedElementForMethodReference(
          MethodReferenceExpression node) =>
      node.propagatedElement;

  @override
  ParameterElement propagatedParameterElementForExpression(Expression node) =>
      node.propagatedParameterElement;

  @override
  DartType propagatedTypeForExpression(Expression node) => node.propagatedType;

  @override
  ConstructorElement staticElementForConstructorReference(
          ConstructorReferenceNode node) =>
      node.staticElement;

  @override
  ExecutableElement staticElementForFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      node.staticElement;

  @override
  Element staticElementForIdentifier(Identifier node) => node.staticElement;

  @override
  MethodElement staticElementForMethodReference(
          MethodReferenceExpression node) =>
      node.staticElement;

  @override
  DartType staticInvokeTypeForInvocationExpression(InvocationExpression node) =>
      node.staticInvokeType;

  @override
  ParameterElement staticParameterElementForExpression(Expression node) =>
      node.staticParameterElement;

  @override
  DartType staticTypeForExpression(Expression node) => node.staticType;

  @override
  DartType typeForTypeName(TypeAnnotation node) => node.type;

  @override
  Element uriElementForDirective(UriBasedDirective node) => node.uriElement;
}
