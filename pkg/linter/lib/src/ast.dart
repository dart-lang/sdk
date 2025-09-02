// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common AST helpers.
library;

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/workspace/workspace.dart';
import 'package:path/path.dart' as path;

/// Return the compilation unit of a node
CompilationUnit? getCompilationUnit(AstNode node) =>
    node.thisOrAncestorOfType<CompilationUnit>();

/// Returns a field identifier with the given [name] in the given [decl]'s
/// variable declaration list or `null` if none is found.
Token? getFieldName(FieldDeclaration decl, String name) {
  for (var v in decl.fields.variables) {
    if (v.name.lexeme == name) {
      return v.name;
    }
  }
  return null;
}

/// Returns the value of an [IntegerLiteral] or [PrefixExpression] with a
/// minus and then an [IntegerLiteral]. If a [context] is provided,
/// [SimpleIdentifier]s are evaluated as constants. For anything else,
/// returns `null`.
int? getIntValue(Expression expression, RuleContext? context) {
  if (expression is PrefixExpression) {
    var operand = expression.operand;
    if (expression.operator.type != TokenType.MINUS) return null;
    return _getIntValue(operand, context, negated: true);
  }
  return _getIntValue(expression, context);
}

/// Returns the most specific AST node appropriate for associating errors.
SyntacticEntity getNodeToAnnotate(Declaration node) {
  // TODO(srawlins): Convert to a switch expression over `Declaration` subtypes,
  // assuming `Declaration` becomes an exhaustive type.
  if (node is ClassDeclaration) {
    return node.name;
  }
  if (node is ClassTypeAlias) {
    return node.name;
  }
  if (node is ConstructorDeclaration) {
    return node.name ?? node.returnType;
  }
  if (node is EnumConstantDeclaration) {
    return node.name;
  }
  if (node is EnumDeclaration) {
    return node.name;
  }
  if (node is ExtensionDeclaration) {
    return node.name ?? node;
  }
  if (node is FieldDeclaration) {
    return node.fields;
  }
  if (node is FunctionDeclaration) {
    return node.name;
  }
  if (node is FunctionTypeAlias) {
    return node.name;
  }
  if (node is GenericTypeAlias) {
    return node.name;
  }
  if (node is MethodDeclaration) {
    return node.name;
  }
  if (node is MixinDeclaration) {
    return node.name;
  }
  if (node is TopLevelVariableDeclaration) {
    return node.variables;
  }
  if (node is TypeParameter) {
    return node.name;
  }
  if (node is VariableDeclaration) {
    return node.name;
  }
  if (node is ExtensionTypeDeclaration) {
    return node.name;
  }
  assert(false, "Unaccounted for Declaration subtype: '${node.runtimeType}'");
  return node;
}

/// If the [node] is the finishing identifier of an assignment, return its
/// "writeElement", otherwise return its "element", which might be
/// thought as the "readElement".
Element? getWriteOrReadElement(SimpleIdentifier node) =>
    _getWriteElement(node) ?? node.element;

bool hasConstantError(Expression node) =>
    node.computeConstantValue()?.diagnostics.isNotEmpty ?? true;

/// Returns `true` if this element is the `==` method declaration.
bool isEquals(ClassMember element) =>
    element is MethodDeclaration && element.name.lexeme == '==';

/// Returns `true` if this element is a `hashCode` method or field declaration.
bool isHashCode(ClassMember element) => _hasFieldOrMethod(element, 'hashCode');

/// Returns `true` if this element is an `index` method or field declaration.
bool isIndex(ClassMember element) => _hasFieldOrMethod(element, 'index');

/// Return `true` if this compilation unit [node] is declared within a public
/// directory in the given [package]'s directory tree. Public dirs are the
/// `lib` and `bin` dirs and the build and link hook file.
//
// TODO(jakemac): move into WorkspacePackage
bool isInPublicDir(CompilationUnit node, WorkspacePackage? package) {
  if (package == null) return false;
  var cuPath = node.declaredFragment?.element.firstFragment.source.fullName;
  if (cuPath == null) return false;
  var libDir = path.join(package.root.path, 'lib');
  var binDir = path.join(package.root.path, 'bin');
  // Hook directory: https://github.com/dart-lang/sdk/issues/54334,
  var buildHookFile = path.join(package.root.path, 'hook', 'build.dart');
  var linkHookFile = path.join(package.root.path, 'hook', 'link.dart');
  return path.isWithin(libDir, cuPath) ||
      path.isWithin(binDir, cuPath) ||
      cuPath == buildHookFile ||
      cuPath == linkHookFile;
}

/// Returns `true` if the given method [declaration] is a "simple getter".
///
/// A simple getter takes one of these basic forms:
///
/// ```dart
/// get x => _simpleIdentifier;
/// ```
///
/// or
///
/// ```dart
/// get x {
///   return _simpleIdentifier;
/// }
/// ```
bool isSimpleGetter(MethodDeclaration declaration) {
  if (!declaration.isGetter) {
    return false;
  }
  var body = declaration.body;
  if (body is ExpressionFunctionBody) {
    return _checkForSimpleGetter(declaration, body.expression);
  } else if (body is BlockFunctionBody) {
    var block = body.block;
    if (block.statements.length == 1) {
      var statement = block.statements.first;
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
/// ```dart
/// int _x;
/// set(int x) {
///   _x = x;
/// }
/// ```
///
/// or:
///
/// ```dart
/// int _x;
/// set(int x) => _x = x;
/// ```
///
/// where the static type of the left and right hand sides of the assignment
/// expression are the same.
bool isSimpleSetter(MethodDeclaration setter) {
  var body = setter.body;
  if (body is ExpressionFunctionBody) {
    return _checkForSimpleSetter(setter, body.expression);
  } else if (body is BlockFunctionBody) {
    var block = body.block;
    if (block.statements.length == 1) {
      var statement = block.statements.first;
      if (statement is ExpressionStatement) {
        return _checkForSimpleSetter(setter, statement.expression);
      }
    }
  }

  return false;
}

/// Returns `true` if this element is a `values` method or field declaration.
bool isValues(ClassMember element) => _hasFieldOrMethod(element, 'values');

/// Return the nearest enclosing pubspec file.
File? locatePubspecFile(CompilationUnit compilationUnit) {
  var declaredFragment = compilationUnit.declaredFragment;
  if (declaredFragment == null) return null;

  var fullName = declaredFragment.source.fullName;
  var resourceProvider = declaredFragment.element.session.resourceProvider;

  var file = resourceProvider.getFile(fullName);

  // Look for a pubspec.yaml file.
  for (var folder in file.parent.withAncestors) {
    var pubspecFile = folder.getChildAssumingFile('pubspec.yaml');
    if (pubspecFile.exists) {
      return pubspecFile;
    }
  }

  return null;
}

bool _checkForSimpleGetter(MethodDeclaration getter, Expression? expression) {
  if (expression is SimpleIdentifier) {
    var staticElement = expression.element;
    if (staticElement is GetterElement) {
      var enclosingElement = getter.declaredFragment?.element.enclosingElement;
      // Skipping library level getters, test that the enclosing element is
      // the same
      if (staticElement.enclosingElement == enclosingElement) {
        var variable = staticElement.variable;
        return staticElement.isSynthetic && variable.isPrivate;
      }
    }
  }
  return false;
}

bool _checkForSimpleSetter(MethodDeclaration setter, Expression expression) {
  if (expression is! AssignmentExpression) {
    return false;
  }
  if (expression.operator.type != TokenType.EQ) {
    return false;
  }

  var leftHandSide = expression.leftHandSide;
  var rightHandSide = expression.rightHandSide;
  if (leftHandSide is SimpleIdentifier && rightHandSide is SimpleIdentifier) {
    var leftElement = expression.writeElement;
    if (leftElement is! SetterElement || !leftElement.isSynthetic) {
      return false;
    }

    // To guard against setters used as type constraints
    if (expression.writeType != rightHandSide.staticType) {
      return false;
    }

    var rightElement = rightHandSide.element;
    if (rightElement is! FormalParameterElement) {
      return false;
    }

    var parameters = setter.parameters?.parameters;
    if (parameters != null && parameters.length == 1) {
      return rightElement == parameters.first.declaredFragment?.element;
    }
  }

  return false;
}

int? _getIntValue(
  Expression expression,
  RuleContext? context, {
  bool negated = false,
}) {
  int? value;
  if (expression is IntegerLiteral) {
    value = expression.value;
  } else if (expression is SimpleIdentifier && context != null) {
    value = expression.computeConstantValue()?.value?.toIntValue();
  }
  if (value is! int) return null;

  return negated ? -value : value;
}

/// If the [node] is the target of a [CompoundAssignmentExpression],
/// return the corresponding "writeElement", which is the local variable,
/// the setter referenced with a [SimpleIdentifier] or a [PropertyAccess],
/// or the `[]=` operator.
Element? _getWriteElement(AstNode node) {
  var parent = node.parent;
  if (parent is AssignmentExpression && parent.leftHandSide == node) {
    return parent.writeElement;
  }
  if (parent is PostfixExpression) {
    return parent.writeElement;
  }
  if (parent is PrefixExpression) {
    return parent.writeElement;
  }

  if (parent is PrefixedIdentifier && parent.identifier == node) {
    return _getWriteElement(parent);
  }

  if (parent is PropertyAccess && parent.propertyName == node) {
    return _getWriteElement(parent);
  }

  return null;
}

bool _hasFieldOrMethod(ClassMember element, String name) =>
    (element is MethodDeclaration && element.name.lexeme == name) ||
    (element is FieldDeclaration && getFieldName(element, name) != null);

extension AstNodeExtension on AstNode {
  bool get isToStringInvocationWithArguments {
    var self = this;
    return self is MethodInvocation &&
        self.methodName.name == 'toString' &&
        self.argumentList.arguments.isNotEmpty;
  }
}
