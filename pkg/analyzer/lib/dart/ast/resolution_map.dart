// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/**
 * A collection of methods which may be used to map from nodes in a resolved AST
 * to elements and types in the element model.
 *
 * Clients should not extend, implement or mix-in this class.
 */
abstract class ResolutionMap {
  /**
   * Return the best element available for the function being invoked at [node].
   * If resolution was able to find a better element based on type propagation,
   * that element will be returned. Otherwise, the element found using the
   * result of static analysis will be returned. If resolution has not been
   * performed, then `null` will be returned.
   */
  ExecutableElement bestElementForFunctionExpressionInvocation(
      FunctionExpressionInvocation node);

  /**
   * Return the best element available for the identifier [node]. If resolution
   * was able to find a better element based on type propagation, that element
   * will be returned. Otherwise, the element found using the result of static
   * analysis will be returned. If resolution has not been performed, then
   * `null` will be returned.
   */
  Element bestElementForIdentifier(Identifier node);

  /**
   * Return the best element available for the expression [node]. If resolution
   * was able to find a better element based on type propagation, that element
   * will be returned. Otherwise, the element found using the result of static
   * analysis will be returned. If resolution has not been performed, then
   * `null` will be returned.
   */
  MethodElement bestElementForMethodReference(MethodReferenceExpression node);

  /**
   * Return the best parameter element information available for the expression
   * [node]. If type propagation was able to find a better parameter element
   * than static analysis, that type will be returned. Otherwise, the result of
   * static analysis will be returned.
   */
  ParameterElement bestParameterElementForExpression(Expression node);

  /**
   * Return the best type information available for the expression [node]. If
   * type propagation was able to find a better type than static analysis, that
   * type will be returned. Otherwise, the result of static analysis will be
   * returned. If no type analysis has been performed, then the type 'dynamic'
   * will be returned.
   */
  DartType bestTypeForExpression(Expression node);

  /**
   * Return the element annotation representing the annotation [node] in the
   * element model.
   */
  ElementAnnotation elementAnnotationForAnnotation(Annotation node);

  /**
   * Return the element associated with the declaration [node], or `null` if
   * either this node corresponds to a list of declarations or if the AST
   * structure has not been resolved.
   */
  ClassElement elementDeclaredByClassDeclaration(ClassDeclaration node);

  /**
   * Return the element associated with the compilation unit [node], or `null`
   * if the AST structure has not been resolved.
   */
  CompilationUnitElement elementDeclaredByCompilationUnit(CompilationUnit node);

  /**
   * Return the element associated with the declaration [node], or `null` if
   * either this node corresponds to a list of declarations or if the AST
   * structure has not been resolved.
   */
  ConstructorElement elementDeclaredByConstructorDeclaration(
      ConstructorDeclaration node);

  /**
   * Return the element associated with the declaration [node], or `null` if
   * either this node corresponds to a list of declarations or if the AST
   * structure has not been resolved.
   */
  Element elementDeclaredByDeclaration(Declaration node);

  /**
   * Return the element associated with the declaration [node], or `null` if
   * either this node corresponds to a list of declarations or if the AST
   * structure has not been resolved.
   */
  LocalVariableElement elementDeclaredByDeclaredIdentifier(
      DeclaredIdentifier node);

  /**
   * Return the element associated with the directive [node], or `null` if the
   * AST structure has not been resolved or if this directive could not be
   * resolved.
   */
  Element elementDeclaredByDirective(Directive node);

  /**
   * Return the element associated with the declaration [node], or `null` if
   * either this node corresponds to a list of declarations or if the AST
   * structure has not been resolved.
   */
  ClassElement elementDeclaredByEnumDeclaration(EnumDeclaration node);

  /**
   * Return the element representing the parameter [node], or `null` if this
   * parameter has not been resolved.
   */
  ParameterElement elementDeclaredByFormalParameter(FormalParameter node);

  /**
   * Return the element associated with the declaration [node], or `null` if
   * either this node corresponds to a list of declarations or if the AST
   * structure has not been resolved.
   */
  ExecutableElement elementDeclaredByFunctionDeclaration(
      FunctionDeclaration node);

  /**
   * Return the element associated with the function expression [node], or
   * `null` if the AST structure has not been resolved.
   */
  ExecutableElement elementDeclaredByFunctionExpression(
      FunctionExpression node);

  /**
   * Return the element associated with the declaration [node], or `null` if
   * either this node corresponds to a list of declarations or if the AST
   * structure has not been resolved.
   */
  ExecutableElement elementDeclaredByMethodDeclaration(MethodDeclaration node);

  /**
   * Return the element associated with the declaration [node], or `null` if
   * either this node corresponds to a list of declarations or if the AST
   * structure has not been resolved.
   */
  VariableElement elementDeclaredByVariableDeclaration(
      VariableDeclaration node);

  /**
   * Return the element associated with the annotation [node], or `null` if the
   * AST structure has not been resolved or if this annotation could not be
   * resolved.
   */
  Element elementForAnnotation(Annotation node);

  /**
   * Return the element representing the parameter being named by the
   * expression [node], or `null` if the AST structure has not been resolved or
   * if there is no parameter with the same name as this expression.
   */
  ParameterElement elementForNamedExpression(NamedExpression node);

  /**
   * Return a list containing the elements representing the parameters in the
   * list [node]. The list will contain `null`s if the parameters in this list
   * have not been resolved.
   */
  List<ParameterElement> parameterElementsForFormalParameterList(
      FormalParameterList node);

  /**
   * Return the element associated with the function being invoked at [node]
   * based on propagated type information, or `null` if the AST structure has
   * not been resolved or the function could not be resolved.
   */
  ExecutableElement propagatedElementForFunctionExpressionInvocation(
      FunctionExpressionInvocation node);

  /**
   * Return the element associated with the identifier [node] based on
   * propagated type information, or `null` if the AST structure has not been
   * resolved or if this identifier could not be resolved. One example of the
   * latter case is an identifier that is not defined within the scope in which
   * it appears.
   */
  Element propagatedElementForIdentifier(Identifier node);

  /**
   * Return the element associated with the expression [node] based on
   * propagated types, or `null` if the AST structure has not been resolved, or
   * there is no meaningful propagated element to return (e.g. because this is a
   * non-compound assignment expression, or because the method referred to could
   * not be resolved).
   */
  MethodElement propagatedElementForMethodReference(
      MethodReferenceExpression node);

  /**
   * If the expression [node] is an argument to an invocation, and the AST
   * structure has been resolved, and the function being invoked is known based
   * on propagated type information, and [node] corresponds to one of the
   * parameters of the function being invoked, then return the parameter element
   * representing the parameter to which the value of [node] will be
   * bound. Otherwise, return `null`.
   */
  ParameterElement propagatedParameterElementForExpression(Expression node);

  /**
   * Return the propagated type of the expression [node], or `null` if type
   * propagation has not been performed on the AST structure.
   */
  DartType propagatedTypeForExpression(Expression node);

  /**
   * Return the element associated with the constructor referenced by [node]
   * based on static type information, or `null` if the AST structure has not
   * been resolved or if the constructor could not be resolved.
   */
  ConstructorElement staticElementForConstructorReference(
      ConstructorReferenceNode node);

  /**
   * Return the element associated with the function being invoked at [node]
   * based on static type information, or `null` if the AST structure has not
   * been resolved or the function could not be resolved.
   */
  ExecutableElement staticElementForFunctionExpressionInvocation(
      FunctionExpressionInvocation node);

  /**
   * Return the element associated with the identifier [node] based on static
   * type information, or `null` if the AST structure has not been resolved or
   * if this identifier could not be resolved. One example of the latter case is
   * an identifier that is not defined within the scope in which it appears
   */
  Element staticElementForIdentifier(Identifier node);

  /**
   * Return the element associated with the expression [node] based on the
   * static types, or `null` if the AST structure has not been resolved, or
   * there is no meaningful static element to return (e.g. because this is a
   * non-compound assignment expression, or because the method referred to could
   * not be resolved).
   */
  MethodElement staticElementForMethodReference(MethodReferenceExpression node);

  /**
   * Return the function type of the invocation [node] based on the static type
   * information, or `null` if the AST structure has not been resolved, or if
   * the invoke could not be resolved.
   *
   * This will usually be a [FunctionType], but it can also be an
   * [InterfaceType] with a `call` method, `dynamic`, `Function`, or a `@proxy`
   * interface type that implements `Function`.
   */
  DartType staticInvokeTypeForInvocationExpression(InvocationExpression node);

  /**
   * If the expression [node] is an argument to an invocation, and the AST
   * structure has been resolved, and the function being invoked is known based
   * on static type information, and [node] corresponds to one of the parameters
   * of the function being invoked, then return the parameter element
   * representing the parameter to which the value of [node] will be
   * bound. Otherwise, return `null`.
   */
  ParameterElement staticParameterElementForExpression(Expression node);

  /**
   * Return the static type of the expression [node], or `null` if the AST
   * structure has not been resolved.
   */
  DartType staticTypeForExpression(Expression node);

  /**
   * Return the type being named by [node], or `null` if the AST structure has
   * not been resolved.
   */
  DartType typeForTypeName(TypeAnnotation node);

  /**
   * Return the element associated with the uri of the directive [node], or
   * `null` if the AST structure has not been resolved or if the URI could not
   * be resolved. Examples of the latter case include a directive that contains
   * an invalid URL or a URL that does not exist.
   */
  Element uriElementForDirective(UriBasedDirective node);
}
