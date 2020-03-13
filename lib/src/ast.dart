// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common AST helpers.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/workspace/workspace.dart'; // ignore: implementation_imports
import 'package:path/path.dart' as path;

import 'analyzer.dart';
import 'utils.dart';

/// Returns direct children of [parent].
List<Element> getChildren(Element parent, [String name]) {
  final children = <Element>[];
  visitChildren(parent, (Element element) {
    if (name == null || element.displayName == name) {
      children.add(element);
    }
    return false;
  });
  return children;
}

/// Return the compilation unit of a node
CompilationUnit getCompilationUnit(AstNode node) =>
    node.thisOrAncestorOfType<CompilationUnit>();

/// Returns a field identifier with the given [name] in the given [decl]'s
/// variable declaration list or `null` if none is found.
SimpleIdentifier getFieldIdentifier(FieldDeclaration decl, String name) {
  for (var v in decl.fields.variables) {
    if (v.name?.name == name) {
      return v.name;
    }
  }
  return null;
}

/// Returns the most specific AST node appropriate for associating errors.
AstNode getNodeToAnnotate(Declaration node) {
  final mostSpecific = _getNodeToAnnotate(node);
  return mostSpecific ?? node;
}

bool hasConstantError(LinterContext context, Expression node) {
  var result = context.evaluateConstant(node);
  return result.errors.isNotEmpty;
}

/// Returns `true` if this [element] has a `@literal` annotation.
bool hasLiteralAnnotation(Element element) {
  final metadata = element.metadata;
  for (var i = 0; i < metadata.length; i++) {
    if (metadata[i].isLiteral) {
      return true;
    }
  }
  return false;
}

/// Returns `true` if this [element] has an `@override` annotation.
bool hasOverrideAnnotation(Element element) {
  final metadata = element.metadata;
  for (var i = 0; i < metadata.length; i++) {
    if (metadata[i].isOverride) {
      return true;
    }
  }
  return false;
}

/// Returns `true` if this [node] is the child of a private compilation unit
/// member.
bool inPrivateMember(AstNode node) {
  final parent = node.parent;
  if (parent is NamedCompilationUnitMember) {
    return isPrivate(parent.name);
  }
  if (parent is ExtensionDeclaration) {
    return parent.name == null || isPrivate(parent.name);
  }
  return false;
}

/// Returns `true` if the given [declaration] is annotated `@deprecated`.
bool isDeprecated(Declaration declaration) =>
    declaration.declaredElement.hasDeprecated;

/// Returns `true` if this element is the `==` method declaration.
bool isEquals(ClassMember element) =>
    element is MethodDeclaration && element.name?.name == '==';

/// Returns `true` if the keyword associated with this token is `final` or
/// `const`.
bool isFinalOrConst(Token token) =>
    isKeyword(token, Keyword.FINAL) || isKeyword(token, Keyword.CONST);

/// Returns `true` if this element is a `hashCode` method or field declaration.
bool isHashCode(ClassMember element) =>
    (element is MethodDeclaration && element.name?.name == 'hashCode') ||
    (element is FieldDeclaration &&
        getFieldIdentifier(element, 'hashCode') != null);

/// Return true if this compilation unit [node] is declared within the given
/// [package]'s `lib/` directory tree.
bool isInLibDir(CompilationUnit node, WorkspacePackage package) {
  if (package == null) return false;
  final cuPath = node.declaredElement.library?.source?.fullName;
  if (cuPath == null) return false;
  final libDir = path.join(package.root, 'lib');
  return path.isWithin(libDir, cuPath);
}

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
bool isPublicMethod(ClassMember m) => isMethod(m) && m.declaredElement.isPublic;

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
  var body = declaration.body;
  if (body is ExpressionFunctionBody) {
    return _checkForSimpleGetter(declaration, body.expression);
  } else if (body is BlockFunctionBody) {
    final block = body.block;
    if (block.statements.length == 1) {
      var statement = block.statements[0];
      if (statement is ReturnStatement) {
        return _checkForSimpleGetter(declaration, statement.expression);
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
  var body = setter.body;
  if (body is ExpressionFunctionBody) {
    return _checkForSimpleSetter(setter, body.expression);
  } else if (body is BlockFunctionBody) {
    final block = body.block;
    if (block.statements.length == 1) {
      var statement = block.statements[0];
      if (statement is ExpressionStatement) {
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

/// Return the nearest enclosing pubspec file.
File locatePubspecFile(CompilationUnit compilationUnit) {
  final fullName = compilationUnit?.declaredElement?.source?.fullName;
  if (fullName == null) {
    return null;
  }

  final resourceProvider =
      compilationUnit?.declaredElement?.session?.resourceProvider;
  if (resourceProvider == null) {
    return null;
  }

  final file = resourceProvider.getFile(fullName);
  var folder = file.parent;

  // Look for a pubspec.yaml file.
  while (folder != null) {
    final pubspecFile = folder.getChildAssumingFile('pubspec.yaml');
    if (pubspecFile.exists) {
      return pubspecFile;
    }
    folder = folder.parent;
  }

  return null;
}

/// Uses [processor] to visit all of the children of [element].
/// If [processor] returns `true`, then children of a child are visited too.
void visitChildren(Element element, ElementProcessor processor) {
  element.visitChildren(_ElementVisitorAdapter(processor));
}

bool _checkForSimpleGetter(MethodDeclaration getter, Expression expression) {
  if (expression is SimpleIdentifier) {
    var staticElement = expression.staticElement;
    if (staticElement is PropertyAccessorElement) {
      Element getterElement = getter.declaredElement;
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
  final assignment = expression as AssignmentExpression;

  var leftHandSide = assignment.leftHandSide;
  var rightHandSide = assignment.rightHandSide;
  if (leftHandSide is SimpleIdentifier && rightHandSide is SimpleIdentifier) {
    var leftElement = leftHandSide.staticElement;
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
      return rightElement == parameters[0].declaredElement;
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
typedef ElementProcessor = bool Function(Element element);

/// A [GeneralizingElementVisitor] adapter for [ElementProcessor].
class _ElementVisitorAdapter extends GeneralizingElementVisitor {
  final ElementProcessor processor;

  _ElementVisitorAdapter(this.processor);

  @override
  void visitElement(Element element) {
    final visitChildren = processor(element);
    if (visitChildren == true) {
      element.visitChildren(this);
    }
  }
}
