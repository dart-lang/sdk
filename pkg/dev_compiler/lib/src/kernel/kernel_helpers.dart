// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';

Constructor unnamedConstructor(Class c) =>
    c.constructors.firstWhere((c) => c.name.name == '', orElse: () => null);

/// Returns the enclosing library for reference [r].
Library getLibrary(NamedNode n) {
  while (n != null && n is! Library) {
    n = n.parent;
  }
  return n;
}

final Pattern genericTypeEncodingCharacters = new RegExp('[&^#]');

// TODO(karlklose): add a namer for all identifiers?
String _escapeIdentifier(String identifier) {
  // Remove the special characters used to encode mixin application class names
  // which are legal in Kernel, but not in JavaScript.
  return identifier?.replaceAll(genericTypeEncodingCharacters, r'$');
}

/// Returns the escaped name for class [node].
///
/// The caller of this function has to make sure that this name is unique in
/// the current scope.
///
/// In the current encoding, generic classes are generated in a function scope
/// which avoids name clashes of the escaped class name.
String getLocalClassName(Class node) => _escapeIdentifier(node.name);

/// Returns the escaped name for the type parameter [node].
///
/// In the current encoding, generic classes are generated in a function scope
/// which avoids name clashes of the escaped parameter name.
String getTypeParameterName(TypeParameter node) => _escapeIdentifier(node.name);

String getTopLevelName(NamedNode n) {
  if (n is Procedure) return n.name.name;
  if (n is Class) return n.name;
  if (n is Typedef) return n.name;
  if (n is Field) return n.name.name;
  return n.canonicalName?.name;
}

/// Given an annotated [node] and a [test] function, returns the first matching
/// constant valued annotation.
///
/// For example if we had the ClassDeclaration node for `FontElement`:
///
///    @js.JS('HTMLFontElement')
///    @deprecated
///    class FontElement { ... }
///
/// We could match `@deprecated` with a test function like:
///
///    (v) => v.type.name == 'Deprecated' && v.type.element.library.isDartCore
///
Expression findAnnotation(TreeNode node, bool test(Expression value)) {
  List<Expression> annotations;
  if (node is Class) {
    annotations = node.annotations;
  } else if (node is Typedef) {
    annotations = node.annotations;
  } else if (node is Procedure) {
    annotations = node.annotations;
  } else if (node is Member) {
    annotations = node.annotations;
  } else if (node is Library) {
    annotations = node.annotations;
  } else {
    return null;
  }
  return annotations.firstWhere(test, orElse: () => null);
}

bool isBuiltinAnnotation(
    Expression value, String libraryName, String expectedName) {
  if (value is ConstructorInvocation) {
    var c = value.target.enclosingClass;
    return c.name == expectedName &&
        c.enclosingLibrary.importUri.toString() == libraryName;
  }
  return false;
}

/// If [node] has annotation matching [test] and the first argument is a
/// string, this returns the string value.
///
/// For example
///
///     class MyAnnotation {
///       final String name;
///       // ...
///       const MyAnnotation(this.name/*, ... other params ... */);
///     }
///
///     @MyAnnotation('FooBar')
///     main() { ... }
///
/// If we match the annotation for the `@MyAnnotation('FooBar')` this will
/// return the string `'FooBar'`.
String getAnnotationName(NamedNode node, bool test(Expression value)) {
  var match = findAnnotation(node, test);
  if (match is ConstructorInvocation && match.arguments.positional.isNotEmpty) {
    var first = match.arguments.positional[0];
    if (first is StringLiteral) {
      return first.value;
    }
  }
  return null;
}

/// Finds constant expressions as defined in Dart language spec 4th ed,
/// 16.1 Constants
class ConstantVisitor extends ExpressionVisitor<bool> {
  final CoreTypes coreTypes;
  ConstantVisitor(this.coreTypes);

  bool isConstant(Expression e) => e.accept(this);

  defaultExpression(node) => false;
  defaultBasicLiteral(node) => true;
  visitTypeLiteral(node) => true; // TODO(jmesserly): deferred libraries?
  visitSymbolLiteral(node) => true;
  visitListLiteral(node) => node.isConst;
  visitMapLiteral(node) => node.isConst;
  visitStaticInvocation(node) {
    return node.isConst ||
        node.target == coreTypes.identicalProcedure &&
            node.arguments.positional.every(isConstant);
  }

  visitDirectMethodInvocation(node) {
    return node.receiver is BasicLiteral &&
        isOperatorMethodName(node.name.name) &&
        node.arguments.positional.every((p) => p is BasicLiteral);
  }

  visitMethodInvocation(node) {
    return node.receiver is BasicLiteral &&
        isOperatorMethodName(node.name.name) &&
        node.arguments.positional.every((p) => p is BasicLiteral);
  }

  visitConstructorInvocation(node) => node.isConst;
  visitStringConcatenation(node) =>
      node.expressions.every((e) => e is BasicLiteral);
  visitStaticGet(node) {
    var target = node.target;
    return target is Procedure || target is Field && target.isConst;
  }

  visitVariableGet(node) => node.variable.isConst;
  visitNot(node) {
    var operand = node.operand;
    return operand is BoolLiteral ||
        operand is DirectMethodInvocation &&
            visitDirectMethodInvocation(operand) ||
        operand is MethodInvocation && visitMethodInvocation(operand);
  }

  visitLogicalExpression(node) =>
      node.left is BoolLiteral && node.right is BoolLiteral;
  visitConditionalExpression(node) =>
      node.condition is BoolLiteral &&
      node.then is BoolLiteral &&
      node.otherwise is BoolLiteral;

  visitLet(Let node) {
    var init = node.variable.initializer;
    return (init == null || isConstant(init)) && isConstant(node.body);
  }
}

/// Returns true if [name] is an operator method that is available on primitive
/// types (`int`, `double`, `num`, `String`, `bool`).
///
/// This does not include logical operators that cannot be user-defined
/// (`!`, `&&` and `||`).
bool isOperatorMethodName(String name) {
  switch (name) {
    case '==':
    case '~':
    case '^':
    case '|':
    case '&':
    case '>>':
    case '<<':
    case '+':
    case 'unary-':
    case '-':
    case '*':
    case '/':
    case '~/':
    case '>':
    case '<':
    case '>=':
    case '<=':
    case '%':
      return true;
  }
  return false;
}

/// Returns true if this class is of the form:
/// `class C = Object with M [implements I1, I2 ...];`
///
/// A mixin alias class is a mixin application, that can also be itself used as
/// a mixin.
bool isMixinAliasClass(Class c) =>
    c.isMixinApplication && c.superclass.superclass == null;

List<Class> getSuperclasses(Class c) {
  var result = <Class>[];
  var visited = new HashSet<Class>();
  while (c != null && visited.add(c)) {
    for (var m = c.mixedInClass; m != null; m = m.mixedInClass) {
      result.add(m);
    }
    var superclass = c.superclass;
    if (superclass == null) break;
    result.add(superclass);
    c = superclass;
  }
  return result;
}

List<Class> getImmediateSuperclasses(Class c) {
  var result = <Class>[];
  var m = c.mixedInClass;
  if (m != null) result.add(m);
  var s = c.superclass;
  if (s != null) result.add(s);
  return result;
}

Expression getInvocationReceiver(InvocationExpression node) =>
    node is MethodInvocation
        ? node.receiver
        : node is DirectMethodInvocation ? node.receiver : null;

bool isInlineJS(Member e) =>
    e is Procedure &&
    e.name == 'JS' &&
    e.enclosingLibrary.importUri.toString() == 'dart:_foreign_helper';
