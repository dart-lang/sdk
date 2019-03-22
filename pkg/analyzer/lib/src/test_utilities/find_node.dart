// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

class FindNode {
  final String content;
  final CompilationUnit unit;

  FindNode(this.content, this.unit);

  LibraryDirective get libraryDirective {
    return unit.directives.singleWhere((d) => d is LibraryDirective);
  }

  Annotation annotation(String search) {
    return _node(search, (n) => n is Annotation);
  }

  AstNode any(String search) {
    return _node(search, (n) => true);
  }

  AssignmentExpression assignment(String search) {
    return _node(search, (n) => n is AssignmentExpression);
  }

  BinaryExpression binary(String search) {
    return _node(search, (n) => n is BinaryExpression);
  }

  Block block(String search) {
    return _node(search, (n) => n is Block);
  }

  BreakStatement breakStatement(String search) {
    return _node(search, (n) => n is BreakStatement);
  }

  CascadeExpression cascade(String search) {
    return _node(search, (n) => n is CascadeExpression);
  }

  ClassDeclaration classDeclaration(String search) {
    return _node(search, (n) => n is ClassDeclaration);
  }

  CommentReference commentReference(String search) {
    return _node(search, (n) => n is CommentReference);
  }

  ConditionalExpression conditionalExpression(String search) {
    return _node(search, (n) => n is ConditionalExpression);
  }

  ConstructorDeclaration constructor(String search) {
    return _node(search, (n) => n is ConstructorDeclaration);
  }

  ConstructorFieldInitializer constructorFieldInitializer(String search) {
    return _node(search, (n) => n is ConstructorFieldInitializer);
  }

  ContinueStatement continueStatement(String search) {
    return _node(search, (n) => n is ContinueStatement);
  }

  DefaultFormalParameter defaultParameter(String search) {
    return _node(search, (n) => n is DefaultFormalParameter);
  }

  DoStatement doStatement(String search) {
    return _node(search, (n) => n is DoStatement);
  }

  ExportDirective export(String search) {
    return _node(search, (n) => n is ExportDirective);
  }

  Expression expression(String search) {
    return _node(search, (n) => n is Expression);
  }

  ExpressionStatement expressionStatement(String search) {
    return _node(search, (n) => n is ExpressionStatement);
  }

  FieldFormalParameter fieldFormalParameter(String search) {
    return _node(search, (n) => n is FieldFormalParameter);
  }

  ForStatement forStatement(String search) {
    return _node(search, (n) => n is ForStatement);
  }

  FunctionBody functionBody(String search) {
    return _node(search, (n) => n is FunctionBody);
  }

  FunctionDeclaration functionDeclaration(String search) {
    return _node(search, (n) => n is FunctionDeclaration);
  }

  FunctionExpression functionExpression(String search) {
    return _node(search, (n) => n is FunctionExpression);
  }

  FunctionTypeAlias functionTypeAlias(String search) {
    return _node(search, (n) => n is FunctionTypeAlias);
  }

  GenericFunctionType genericFunctionType(String search) {
    return _node(search, (n) => n is GenericFunctionType);
  }

  ImportDirective import(String search) {
    return _node(search, (n) => n is ImportDirective);
  }

  IndexExpression index(String search) {
    return _node(search, (n) => n is IndexExpression);
  }

  InstanceCreationExpression instanceCreation(String search) {
    return _node(search, (n) => n is InstanceCreationExpression);
  }

  IntegerLiteral integerLiteral(String search) {
    return _node(search, (n) => n is IntegerLiteral);
  }

  LibraryDirective library(String search) {
    return _node(search, (n) => n is LibraryDirective);
  }

  ListLiteral listLiteral(String search) {
    return _node(search, (n) => n is ListLiteral);
  }

  MethodDeclaration methodDeclaration(String search) {
    return _node(search, (n) => n is MethodDeclaration);
  }

  MethodInvocation methodInvocation(String search) {
    return _node(search, (n) => n is MethodInvocation);
  }

  MixinDeclaration mixin(String search) {
    return _node(search, (n) => n is MixinDeclaration);
  }

  NamedExpression namedExpression(String search) {
    return _node(search, (n) => n is NamedExpression);
  }

  ParenthesizedExpression parenthesized(String search) {
    return _node(search, (n) => n is ParenthesizedExpression);
  }

  PartDirective part(String search) {
    return _node(search, (n) => n is PartDirective);
  }

  PartOfDirective partOf(String search) {
    return _node(search, (n) => n is PartOfDirective);
  }

  PostfixExpression postfix(String search) {
    return _node(search, (n) => n is PostfixExpression);
  }

  PrefixExpression prefix(String search) {
    return _node(search, (n) => n is PrefixExpression);
  }

  PrefixedIdentifier prefixed(String search) {
    return _node(search, (n) => n is PrefixedIdentifier);
  }

  PropertyAccess propertyAccess(String search) {
    return _node(search, (n) => n is PropertyAccess);
  }

  RethrowExpression rethrow_(String search) {
    return _node(search, (n) => n is RethrowExpression);
  }

  SetOrMapLiteral setOrMapLiteral(String search) {
    return _node(search, (n) => n is SetOrMapLiteral);
  }

  SimpleIdentifier simple(String search) {
    return _node(search, (_) => true);
  }

  SimpleFormalParameter simpleParameter(String search) {
    return _node(search, (n) => n is SimpleFormalParameter);
  }

  Statement statement(String search) {
    return _node(search, (n) => n is Statement);
  }

  StringLiteral stringLiteral(String search) {
    return _node(search, (n) => n is StringLiteral);
  }

  SuperExpression super_(String search) {
    return _node(search, (n) => n is SuperExpression);
  }

  SwitchStatement switchStatement(String search) {
    return _node(search, (n) => n is SwitchStatement);
  }

  ThisExpression this_(String search) {
    return _node(search, (n) => n is ThisExpression);
  }

  ThrowExpression throw_(String search) {
    return _node(search, (n) => n is ThrowExpression);
  }

  TopLevelVariableDeclaration topLevelVariableDeclaration(String search) {
    return _node(search, (n) => n is TopLevelVariableDeclaration);
  }

  VariableDeclaration topVariableDeclarationByName(String name) {
    for (var declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          if (variable.name.name == name) {
            return variable;
          }
        }
      }
    }
    throw StateError('$name');
  }

  TypeAnnotation typeAnnotation(String search) {
    return _node(search, (n) => n is TypeAnnotation);
  }

  TypeName typeName(String search) {
    return _node(search, (n) => n is TypeName);
  }

  TypeParameter typeParameter(String search) {
    return _node(search, (n) => n is TypeParameter);
  }

  VariableDeclaration variableDeclaration(String search) {
    return _node(search, (n) => n is VariableDeclaration);
  }

  VariableDeclarationList variableDeclarationList(String search) {
    return _node(search, (n) => n is VariableDeclarationList);
  }

  WhileStatement whileStatement(String search) {
    return _node(search, (n) => n is WhileStatement);
  }

  AstNode _node(String search, bool Function(AstNode) predicate) {
    var index = content.indexOf(search);
    if (content.indexOf(search, index + 1) != -1) {
      throw new StateError('The pattern |$search| is not unique in:\n$content');
    }
    if (index < 0) {
      throw new StateError('The pattern |$search| is not found in:\n$content');
    }

    var node = new NodeLocator2(index).searchWithin(unit);
    if (node == null) {
      throw new StateError(
          'The pattern |$search| had no corresponding node in:\n$content');
    }

    var result = node.thisOrAncestorMatching(predicate);
    if (result == null) {
      throw new StateError(
          'The node for |$search| had no matching ancestor in:\n$content');
    }
    return result;
  }
}
