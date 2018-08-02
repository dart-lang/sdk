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
  @deprecated
  @override
  ExecutableElement bestElementForFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      node.staticElement;

  @deprecated
  @override
  Element bestElementForIdentifier(Identifier node) => node.staticElement;

  @deprecated
  @override
  MethodElement bestElementForMethodReference(MethodReferenceExpression node) =>
      node.staticElement;

  @deprecated
  @override
  ParameterElement bestParameterElementForExpression(Expression node) =>
      node.staticParameterElement;

  @deprecated
  @override
  DartType bestTypeForExpression(Expression node) => node.staticType;

  @override
  ElementAnnotation elementAnnotationForAnnotation(Annotation node) =>
      node.elementAnnotation;

  @override
  ClassElement elementDeclaredByClassDeclaration(ClassDeclaration node) =>
      node.declaredElement;

  @override
  CompilationUnitElement elementDeclaredByCompilationUnit(
          CompilationUnit node) =>
      node.declaredElement;

  @override
  ConstructorElement elementDeclaredByConstructorDeclaration(
          ConstructorDeclaration node) =>
      node.declaredElement;

  @override
  Element elementDeclaredByDeclaration(Declaration node) =>
      node.declaredElement;

  @override
  LocalVariableElement elementDeclaredByDeclaredIdentifier(
          DeclaredIdentifier node) =>
      node.declaredElement;

  @override
  Element elementDeclaredByDirective(Directive node) => node.element;

  @override
  ClassElement elementDeclaredByEnumDeclaration(EnumDeclaration node) =>
      node.declaredElement;

  @override
  ParameterElement elementDeclaredByFormalParameter(FormalParameter node) =>
      node.declaredElement;

  @override
  ExecutableElement elementDeclaredByFunctionDeclaration(
          FunctionDeclaration node) =>
      node.declaredElement;

  @override
  ExecutableElement elementDeclaredByFunctionExpression(
          FunctionExpression node) =>
      node.declaredElement;

  @override
  ExecutableElement elementDeclaredByMethodDeclaration(
          MethodDeclaration node) =>
      node.declaredElement;

  @override
  VariableElement elementDeclaredByVariableDeclaration(
          VariableDeclaration node) =>
      node.declaredElement;

  @override
  Element elementForAnnotation(Annotation node) => node.element;

  @override
  ParameterElement elementForNamedExpression(NamedExpression node) =>
      node.element;

  @override
  List<ParameterElement> parameterElementsForFormalParameterList(
          FormalParameterList node) =>
      node.parameterElements;

  @deprecated
  @override
  ExecutableElement propagatedElementForFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      null;

  @deprecated
  @override
  Element propagatedElementForIdentifier(Identifier node) => null;

  @deprecated
  @override
  MethodElement propagatedElementForMethodReference(
          MethodReferenceExpression node) =>
      null;

  @deprecated
  @override
  ParameterElement propagatedParameterElementForExpression(Expression node) =>
      null;

  @deprecated
  @override
  DartType propagatedTypeForExpression(Expression node) => null;

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
