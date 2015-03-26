// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common AST helpers.
library linter.src.ast;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:linter/src/util.dart';

/// Returns the most specific AST node appropriate for associating errors.
AstNode getNodeToAnnotate(Declaration node) {
  AstNode mostSpecific = _getNodeToAnnotate(node);
  if (mostSpecific != null) {
    return mostSpecific;
  }
  return node;
}

/// Returns `true` if the given [id] is a Dart keyword.
bool isKeyWord(String id) => Keyword.keywords.keys.contains(id);

/// Returns `true` if the given [ClassMember] is a method.
bool isMethod(ClassMember m) => m is MethodDeclaration;

/// Returns `true` if the given [ClassMember] is a public method.
bool isPublicMethod(ClassMember m) => isMethod(m) && m.element.isPublic;

/// Returns `true` if the given method [declaration] is a "simple getter".
///
/// A simple getter takes one of these basic forms:
///
///     get x => _simpleIdentifier;
/// or
///     get x {
///       return _simpleIdentifier;
///     }
bool isSimpleGetter(MethodDeclaration declaration) {
  if (!declaration.isGetter) {
    return false;
  }
  if (declaration.body is ExpressionFunctionBody) {
    ExpressionFunctionBody body = declaration.body;
    return _checkForSimpleGetter(declaration, body.expression);
  } else if (declaration.body is BlockFunctionBody) {
    BlockFunctionBody body = declaration.body;
    Block block = body.block;
    if (block.statements.length == 1) {
      if (block.statements[0] is ReturnStatement) {
        ReturnStatement returnStatement = block.statements[0];
        return _checkForSimpleGetter(declaration, returnStatement.expression);
      }
    }
  }
  return false;
}

/// Returns `true` if the given method [declaration] is a "simple setter".
///
/// A simple setter takes this basic form:
///
///     var _x;
///     set(x) {
///       _x = x;
///     }
///
/// or:
///
///     set(x) => _x = x;
///
/// where the static type of the left and right hand sides must be the same.
bool isSimpleSetter(MethodDeclaration setter) {
  if (setter.body is ExpressionFunctionBody) {
    ExpressionFunctionBody body = setter.body;
    return _checkForSimpleSetter(setter, body.expression);
  } else if (setter.body is BlockFunctionBody) {
    BlockFunctionBody body = setter.body;
    Block block = body.block;
    if (block.statements.length == 1) {
      if (block.statements[0] is ExpressionStatement) {
        ExpressionStatement statement = block.statements[0];
        return _checkForSimpleSetter(setter, statement.expression);
      }
    }
  }

  return false;
}

/// Returns `true` if the given [id] is a valid Dart identifier.
bool isValidDartIdentifier(String id) => !isKeyWord(id) && isIdentifier(id);

bool _checkForSimpleGetter(MethodDeclaration getter, Expression expression) {
  if (expression is SimpleIdentifier) {
    var staticElement = expression.staticElement;
    if (staticElement is PropertyAccessorElement) {
      Element getterElement = getter.element;
      // Skipping library level getters, test that the enclosing element is
      // the same
      if (staticElement.enclosingElement != null &&
          (staticElement.enclosingElement == getterElement.enclosingElement)) {
        return staticElement.isSynthetic && staticElement.variable.isPrivate;
      }
    }
  }
  return false;
}

bool _checkForSimpleSetter(MethodDeclaration setter, Expression expression) {
  if (expression is! AssignmentExpression) {
    return false;
  }
  AssignmentExpression assignment = expression;

  var leftHandSide = assignment.leftHandSide;
  if (leftHandSide is! SimpleIdentifier) {
    return false;
  }
  var staticElement = leftHandSide.staticElement;
  if (staticElement is! PropertyAccessorElement || !staticElement.isSynthetic) {
    return false;
  }

  var rightHandSide = assignment.rightHandSide;
  if (rightHandSide is! SimpleIdentifier) {
    return false;
  }

  // To guard against setters used as type constraints
  if (leftHandSide.staticType != rightHandSide.staticType) {
    return false;
  }

  staticElement = rightHandSide.staticElement;
  if (staticElement is! ParameterElement) {
    return false;
  }

  var parameters = setter.parameters.parameters;
  if (parameters.length == 1) {
    return staticElement == parameters[0].element;
  }

  return false;
}

AstNode _getNodeToAnnotate(Declaration node) {
  if (node is MethodDeclaration) {
    return node.name;
  }
  if (node is ConstructorDeclaration) {
    return node.name;
  }
  if (node is FieldDeclaration) {
    return node.fields;
  }
  if (node is ClassTypeAlias) {
    return node.name;
  }
  if (node is FunctionTypeAlias) {
    return node.name;
  }
  if (node is ClassDeclaration) {
    return node.name;
  }
  if (node is EnumDeclaration) {
    return node.name;
  }
  if (node is FunctionDeclaration) {
    return node.name;
  }
  if (node is TopLevelVariableDeclaration) {
    return node.variables;
  }
  if (node is EnumConstantDeclaration) {
    return node.name;
  }
  if (node is TypeParameter) {
    return node.name;
  }
  if (node is VariableDeclaration) {
    return node.name;
  }
  return null;
}
