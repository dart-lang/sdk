// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';

Constructor unnamedConstructor(Class c) =>
    c.constructors.firstWhere((c) => c.name.name == '', orElse: () => null);

/// Returns the enclosing library for reference [node].
Library getLibrary(NamedNode node) {
  for (TreeNode n = node; n != null; n = n.parent) {
    if (n is Library) return n;
  }
  return null;
}

final Pattern _syntheticTypeCharacters = new RegExp('[&^#.]');

String _escapeIdentifier(String identifier) {
  // Remove the special characters used to encode mixin application class names
  // which are legal in Kernel, but not in JavaScript.
  return identifier?.replaceAll(_syntheticTypeCharacters, r'$');
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

bool isFromEnvironmentInvocation(CoreTypes coreTypes, StaticInvocation node) {
  var target = node.target;
  return node.isConst &&
      target.name.name == 'fromEnvironment' &&
      target.enclosingLibrary == coreTypes.coreLibrary;
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
    e.name.name == 'JS' &&
    e.enclosingLibrary.importUri.toString() == 'dart:_foreign_helper';

// Check whether we have any covariant parameters.
// Usually we don't, so we can use the same type.
bool isCovariant(VariableDeclaration p) =>
    p.isCovariant || p.isGenericCovariantImpl;

/// Returns true iff this factory constructor just throws [UnsupportedError]/
///
/// `dart:html` has many of these.
bool isUnsupportedFactoryConstructor(Procedure node) {
  if (node.name.isPrivate && node.enclosingLibrary.importUri.scheme == 'dart') {
    var body = node.function.body;
    if (body is Block) {
      var statements = body.statements;
      if (statements.length == 1) {
        var statement = statements[0];
        if (statement is ExpressionStatement) {
          var expr = statement.expression;
          if (expr is Throw) {
            var error = expr.expression;
            if (error is ConstructorInvocation &&
                error.target.enclosingClass.name == 'UnsupportedError') {
              // HTML adds a lot of private constructors that are unreachable.
              // Skip these.
              return true;
            }
          }
        }
      }
    }
  }
  return false;
}

/// Returns the redirecting factory constructors for the enclosing class,
/// if the field [f] is storing that information, otherwise returns `null`.
Iterable<Member> getRedirectingFactories(Field f) {
  // TODO(jmesserly): this relies on implementation details in Kernel
  if (f.name.name == "_redirecting#") {
    assert(f.isStatic);
    var list = f.initializer as ListLiteral;
    return list.expressions.map((e) => (e as StaticGet).target);
  }
  return null;
}

/// Gets the real supertype of [c] and the list of [mixins] in reverse
/// application order (mixins will appear before ones they override).
///
/// This is used to ignore synthetic mixin application classes.
///
// TODO(jmesserly): consider replacing this with Kernel's mixin unrolling once
// we don't have the Analyzer backend to maintain.
Class getSuperclassAndMixins(Class c, List<Class> mixins) {
  assert(mixins.isEmpty);

  var mixedInClass = c.mixedInClass;
  if (mixedInClass != null) mixins.add(mixedInClass);

  var sc = c.superclass;
  for (; sc.isSyntheticMixinImplementation; sc = sc.superclass) {
    mixins.add(sc.mixedInClass);
  }
  return sc;
}
