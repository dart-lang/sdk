// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common AST helpers.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/workspace/workspace.dart'; // ignore: implementation_imports
import 'package:path/path.dart' as path;

import 'analyzer.dart';
import 'utils.dart';

final List<String> reservedWords = _collectReservedWords();

/// Returns direct children of [parent].
List<Element> getChildren(Element parent, [String? name]) {
  var children = <Element>[];
  visitChildren(parent, (Element element) {
    if (name == null || element.displayName == name) {
      children.add(element);
    }
    return false;
  });
  return children;
}

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
int? getIntValue(Expression expression, LinterContext? context) {
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
    return node.name ?? node;
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
/// "writeElement", otherwise return its "staticElement", which might be
/// thought as the "readElement".
Element? getWriteOrReadElement(SimpleIdentifier node) {
  var writeElement = _getWriteElement(node);
  if (writeElement != null) {
    return writeElement;
  }
  return node.staticElement;
}

bool hasConstantError(LinterContext context, Expression node) {
  var result = context.evaluateConstant(node);
  return result.errors.isNotEmpty;
}

/// Returns `true` if this [element] has a `@literal` annotation.
@Deprecated('prefer: element.hasLiteral')
bool hasLiteralAnnotation(Element element) => element.hasLiteral;

/// Returns `true` if this [element] has an `@override` annotation.
@Deprecated('prefer: element.hasOverride')
bool hasOverrideAnnotation(Element element) => element.hasOverride;

/// Returns `true` if this [node] is the child of a private compilation unit
/// member.
bool inPrivateMember(AstNode node) {
  var parent = node.parent;
  if (parent is NamedCompilationUnitMember) {
    return isPrivate(parent.name);
  }
  if (parent is ExtensionDeclaration) {
    return parent.name == null || isPrivate(parent.name);
  }
  return false;
}

/// Returns `true` if this element is the `==` method declaration.
bool isEquals(ClassMember element) =>
    element is MethodDeclaration && element.name.lexeme == '==';

/// Returns `true` if the keyword associated with this token is `final` or
/// `const`.
bool isFinalOrConst(Token token) =>
    isKeyword(token, Keyword.FINAL) || isKeyword(token, Keyword.CONST);

/// Returns `true` if this element is a `hashCode` method or field declaration.
bool isHashCode(ClassMember element) => _hasFieldOrMethod(element, 'hashCode');

/// Returns `true` if this element is an `index` method or field declaration.
bool isIndex(ClassMember element) => _hasFieldOrMethod(element, 'index');

/// Return true if this compilation unit [node] is declared within the given
/// [package]'s `lib/` directory tree.
bool isInLibDir(CompilationUnit node, WorkspacePackage? package) {
  if (package == null) return false;
  var cuPath = node.declaredElement?.library.source.fullName;
  if (cuPath == null) return false;
  var libDir = path.join(package.root, 'lib');
  return path.isWithin(libDir, cuPath);
}

/// Return `true` if this compilation unit [node] is declared within a public
/// directory in the given [package]'s directory tree. Public dirs are the
/// `lib` and `bin` dirs.
//
//  TODO: move into WorkspacePackage
bool isInPublicDir(CompilationUnit node, WorkspacePackage? package) {
  if (package == null) return false;
  var cuPath = node.declaredElement?.library.source.fullName;
  if (cuPath == null) return false;
  var libDir = path.join(package.root, 'lib');
  var binDir = path.join(package.root, 'bin');
  return path.isWithin(libDir, cuPath) || path.isWithin(binDir, cuPath);
}

/// Returns `true` if the keyword associated with the given [token] matches
/// [keyword].
bool isKeyword(Token token, Keyword keyword) =>
    token is KeywordToken && token.keyword == keyword;

/// Returns `true` if the given [id] is a Dart keyword.
bool isKeyWord(String id) => Keyword.keywords.containsKey(id);

/// Returns `true` if the given [ClassMember] is a method.
bool isMethod(ClassMember m) => m is MethodDeclaration;

/// Check if the given identifier has a private name.
bool isPrivate(Token? name) =>
    name != null ? Identifier.isPrivateName(name.lexeme) : false;

/// Returns `true` if the given [ClassMember] is a public method.
bool isPublicMethod(ClassMember m) {
  var declaredElement = m.declaredElement;
  return declaredElement != null && isMethod(m) && declaredElement.isPublic;
}

/// Check if the given word is a Dart reserved word.
bool isReservedWord(String word) => reservedWords.contains(word);

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

/// Returns `true` if the given [id] is a valid Dart identifier.
bool isValidDartIdentifier(String id) => !isKeyWord(id) && isIdentifier(id);

/// Returns `true` if this element is a `values` method or field declaration.
bool isValues(ClassMember element) => _hasFieldOrMethod(element, 'values');

/// Returns `true` if the keyword associated with this token is `var`.
bool isVar(Token token) => isKeyword(token, Keyword.VAR);

/// Return the nearest enclosing pubspec file.
File? locatePubspecFile(CompilationUnit compilationUnit) {
  var fullName = compilationUnit.declaredElement?.source.fullName;
  if (fullName == null) {
    return null;
  }

  var resourceProvider =
      compilationUnit.declaredElement?.session.resourceProvider;
  if (resourceProvider == null) {
    return null;
  }

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

/// Uses [processor] to visit all of the children of [element].
/// If [processor] returns `true`, then children of a child are visited too.
void visitChildren(Element element, ElementProcessor processor) {
  element.visitChildren(_ElementVisitorAdapter(processor));
}

bool _checkForSimpleGetter(MethodDeclaration getter, Expression? expression) {
  if (expression is SimpleIdentifier) {
    var staticElement = expression.staticElement;
    if (staticElement is PropertyAccessorElement) {
      var enclosingElement = getter.declaredElement?.enclosingElement;
      // Skipping library level getters, test that the enclosing element is
      // the same
      if (staticElement.enclosingElement == enclosingElement) {
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
  if (expression.operator.type != TokenType.EQ) {
    return false;
  }

  var leftHandSide = expression.leftHandSide;
  var rightHandSide = expression.rightHandSide;
  if (leftHandSide is SimpleIdentifier && rightHandSide is SimpleIdentifier) {
    var leftElement = expression.writeElement;
    if (leftElement is! PropertyAccessorElement || !leftElement.isSynthetic) {
      return false;
    }

    // To guard against setters used as type constraints
    if (expression.writeType != rightHandSide.staticType) {
      return false;
    }

    var rightElement = rightHandSide.staticElement;
    if (rightElement is! ParameterElement) {
      return false;
    }

    var parameters = setter.parameters?.parameters;
    if (parameters != null && parameters.length == 1) {
      return rightElement == parameters.first.declaredElement;
    }
  }

  return false;
}

List<String> _collectReservedWords() {
  var reserved = <String>[];
  for (var entry in Keyword.keywords.entries) {
    if (entry.value.isReservedWord) {
      reserved.add(entry.key);
    }
  }
  return reserved;
}

int? _getIntValue(Expression expression, LinterContext? context,
    {bool negated = false}) {
  int? value;
  if (expression is IntegerLiteral) {
    value = expression.value;
  } else if (expression is SimpleIdentifier && context != null) {
    value = context.evaluateConstant(expression).value?.toIntValue();
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

/// An [Element] processor function type.
/// If `true` is returned, children of [element] will be visited.
typedef ElementProcessor = bool Function(Element element);

/// A [GeneralizingElementVisitor] adapter for [ElementProcessor].
class _ElementVisitorAdapter extends GeneralizingElementVisitor {
  final ElementProcessor processor;

  _ElementVisitorAdapter(this.processor);

  @override
  void visitElement(Element element) {
    var visitChildren = processor(element);
    if (visitChildren) {
      element.visitChildren(this);
    }
  }
}

extension AstNodeExtension on AstNode {
  bool get isToStringInvocationWithArguments {
    var self = this;
    return self is MethodInvocation &&
        self.methodName.name == 'toString' &&
        self.argumentList.arguments.isNotEmpty;
  }
}

extension ElementExtension on Element? {
  // TODO(srawlins): Move to extensions.dart.
  bool get isDartCorePrint {
    var self = this;
    return self is FunctionElement &&
        self.name == 'print' &&
        self.library.isDartCore;
  }
}
