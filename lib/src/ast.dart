// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common AST helpers.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/utils.dart';

/// Returns direct children of [parent].
List<Element> getChildren(Element parent, [String name]) {
  List<Element> children = <Element>[];
  visitChildren(parent, (Element element) {
    if (name == null || element.displayName == name) {
      children.add(element);
    }
  });
  return children;
}

/// Returns the most specific AST node appropriate for associating errors.
AstNode getNodeToAnnotate(Declaration node) {
  AstNode mostSpecific = _getNodeToAnnotate(node);
  return mostSpecific ?? node;
}

/// Returns `true` if this [node] has an `@override` annotation.
bool hasOverrideAnnotation(Declaration node) =>
    node.metadata.map((Annotation a) => a.name.name).contains('override');

/// Returns `true` if this [node] is the child of a private compilation unit
/// member.
bool inPrivateMember(AstNode node) {
  AstNode parent = node.parent;
  if (parent is NamedCompilationUnitMember) {
    return isPrivate(parent.name);
  }
  return false;
}

/// Returns `true` if this element is the `==` method declaration.
bool isEquals(ClassMember element) =>
    element is MethodDeclaration && element.name?.name == '==';

/// Returns `true` if the keyword associated with this token is `final` or
/// `const`.
bool isFinalOrConst(Token token) =>
    isKeyword(token, Keyword.FINAL) || isKeyword(token, Keyword.CONST);

/// Returns `true` if this element is the `hashCode` method declaration.
bool isHashCode(ClassMember element) =>
    element is MethodDeclaration && element.name?.name == 'hashCode';

/// Returns `true` if the keyword associated with the given [token] matches
/// [keyword].
bool isKeyword(Token token, Keyword keyword) =>
    token is KeywordToken && token.keyword == keyword;

/// Returns `true` if the given [id] is a Dart keyword.
bool isKeyWord(String id) => Keyword.keywords.keys.contains(id);

/// Returns `true` if the given [ClassMember] is a method.
bool isMethod(ClassMember m) => m is MethodDeclaration;

/// Check if the given identifier has a private name.
bool isPrivate(SimpleIdentifier identifier) =>
    identifier != null ? Identifier.isPrivateName(identifier.name) : false;

/// Returns `true` if the given [declaration] is annotated `@protected`.
bool isProtected(Declaration declaration) =>
    declaration.metadata.any((Annotation a) => a.name.name == 'protected');

/// Returns `true` if the given [ClassMember] is a public method.
bool isPublicMethod(ClassMember m) =>
    isMethod(m) && resolutionMap.elementDeclaredByDeclaration(m).isPublic;

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

/// Returns `true` if the given [setter] is a "simple setter".
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

/// Returns `true` if the keyword associated with this token is `var`.
bool isVar(Token token) => isKeyword(token, Keyword.VAR);

/// Uses [processor] to visit all of the children of [element].
/// If [processor] returns `true`, then children of a child are visited too.
void visitChildren(Element element, ElementProcessor processor) {
  element.visitChildren(new _ElementVisitorAdapter(processor));
}

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
  var rightHandSide = assignment.rightHandSide;
  if (leftHandSide is SimpleIdentifier && rightHandSide is SimpleIdentifier) {
    var leftElement = resolutionMap.staticElementForIdentifier(leftHandSide);
    if (leftElement is! PropertyAccessorElement || !leftElement.isSynthetic) {
      return false;
    }

    // To guard against setters used as type constraints
    if (leftHandSide.staticType != rightHandSide.staticType) {
      return false;
    }

    var rightElement = rightHandSide.staticElement;
    if (rightElement is! ParameterElement) {
      return false;
    }

    var parameters = setter.parameters.parameters;
    if (parameters.length == 1) {
      return rightElement == parameters[0].element;
    }
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

/// An [Element] processor function type.
/// If `true` is returned, children of [element] will be visited.
typedef bool ElementProcessor(Element element);

/// A [GeneralizingElementVisitor] adapter for [ElementProcessor].
class _ElementVisitorAdapter extends GeneralizingElementVisitor {
  final ElementProcessor processor;
  _ElementVisitorAdapter(this.processor);

  @override
  void visitElement(Element element) {
    bool visitChildren = processor(element);
    if (visitChildren == true) {
      element.visitChildren(this);
    }
  }
}
