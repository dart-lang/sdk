// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:collection';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';

Constructor unnamedConstructor(Class c) =>
    c.constructors.firstWhere((c) => c.name.text == '', orElse: () => null);

/// Returns the enclosing library for reference [node].
Library getLibrary(NamedNode node) {
  for (TreeNode n = node; n != null; n = n.parent) {
    if (n is Library) return n;
  }
  return null;
}

final Pattern _syntheticTypeCharacters = RegExp('[&^#.|]');

String escapeIdentifier(String identifier) {
  // Remove the special characters used to encode mixin application class names
  // and extension method / parameter names which are legal in Kernel, but not
  // in JavaScript.
  //
  // Note, there is an implicit assumption here that we won't have
  // collisions since everything is mapped to \$.  That may work out fine given
  // how these are sythesized, but may need to revisit.
  return identifier?.replaceAll(_syntheticTypeCharacters, r'$');
}

/// Returns the escaped name for class [node].
///
/// The caller of this function has to make sure that this name is unique in
/// the current scope.
///
/// In the current encoding, generic classes are generated in a function scope
/// which avoids name clashes of the escaped class name.
String getLocalClassName(Class node) => escapeIdentifier(node.name);

/// Returns the escaped name for the type parameter [node].
///
/// In the current encoding, generic classes are generated in a function scope
/// which avoids name clashes of the escaped parameter name.
String getTypeParameterName(TypeParameter node) => escapeIdentifier(node.name);

String getTopLevelName(NamedNode n) {
  if (n is Procedure) return n.name.text;
  if (n is Class) return n.name;
  if (n is Typedef) return n.name;
  if (n is Field) return n.name.text;
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
Expression findAnnotation(TreeNode node, bool Function(Expression) test) {
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

/// Returns true if [value] represents an annotation for class [className] in
/// "dart:" library [libraryName].
bool isBuiltinAnnotation(
    Expression value, String libraryName, String className) {
  var c = getAnnotationClass(value);
  if (c != null && c.name == className) {
    var uri = c.enclosingLibrary.importUri;
    return uri.scheme == 'dart' && uri.path == libraryName;
  }
  return false;
}

/// Gets the class of the instance referred to by metadata annotation [node].
///
/// For example:
///
/// - `@JS()` would return the "JS" class in "package:js".
/// - `@anonymous` would return the "_Anonymous" class in "package:js".
///
/// This function works regardless of whether the CFE is evaluating constants,
/// or whether the constant is a field reference (such as "anonymous" above).
Class getAnnotationClass(Expression node) {
  if (node is ConstantExpression) {
    var constant = node.constant;
    if (constant is InstanceConstant) return constant.classNode;
  } else if (node is ConstructorInvocation) {
    return node.target.enclosingClass;
  } else if (node is StaticGet) {
    var type = node.target.getterType;
    if (type is InterfaceType) return type.classNode;
  }
  return null;
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
      target.name.text == 'fromEnvironment' &&
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
  var visited = HashSet<Class>();
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

Expression getInvocationReceiver(InvocationExpression node) {
  if (node is MethodInvocation) {
    return node.receiver;
  } else if (node is InstanceInvocation) {
    return node.receiver;
  } else if (node is DynamicInvocation) {
    return node.receiver;
  } else if (node is FunctionInvocation) {
    return node.receiver;
  } else if (node is LocalFunctionInvocation) {
    return VariableGet(node.variable);
  }
  return null;
}

bool isInlineJS(Member e) =>
    e is Procedure &&
    e.name.text == 'JS' &&
    e.enclosingLibrary.importUri.toString() == 'dart:_foreign_helper';

/// Whether the parameter [p] is covariant (either explicitly `covariant` or
/// implicitly due to generics) and needs a check for soundness.
bool isCovariantParameter(VariableDeclaration p) {
  return p.isCovariant || p.isGenericCovariantImpl;
}

/// Whether the field [p] is covariant (either explicitly `covariant` or
/// implicitly due to generics) and needs a check for soundness.
bool isCovariantField(Field f) {
  return f.isCovariant || f.isGenericCovariantImpl;
}

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

            // HTML adds a lot of private constructors that are unreachable.
            // Skip these.
            return isBuiltinAnnotation(error, 'core', 'UnsupportedError');
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
  if (isRedirectingFactoryField(f)) {
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
// TODO(jmesserly): consider replacing this with Kernel's mixin unrolling
Class getSuperclassAndMixins(Class c, List<Class> mixins) {
  assert(mixins.isEmpty);

  var mixedInClass = c.mixedInClass;
  if (mixedInClass != null) mixins.add(mixedInClass);

  var sc = c.superclass;
  for (; sc.isAnonymousMixin; sc = sc.superclass) {
    mixedInClass = sc.mixedInClass;
    if (mixedInClass != null) mixins.add(sc.mixedInClass);
  }
  return sc;
}

/// Returns true if a switch statement contains any continues with a label.
bool hasLabeledContinue(SwitchStatement node) {
  var visitor = LabelContinueFinder();
  node.accept(visitor);
  return visitor.found;
}

class LabelContinueFinder extends StatementVisitor<void> {
  var found = false;

  void visit(Statement s) {
    if (!found && s != null) s.accept(this);
  }

  @override
  void visitBlock(Block node) => node.statements.forEach(visit);
  @override
  void visitAssertBlock(AssertBlock node) => node.statements.forEach(visit);
  @override
  void visitWhileStatement(WhileStatement node) => visit(node.body);
  @override
  void visitDoStatement(DoStatement node) => visit(node.body);
  @override
  void visitForStatement(ForStatement node) => visit(node.body);
  @override
  void visitForInStatement(ForInStatement node) => visit(node.body);
  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) =>
      found = true;

  @override
  void visitSwitchStatement(SwitchStatement node) {
    node.cases.forEach((c) => visit(c.body));
  }

  @override
  void visitIfStatement(IfStatement node) {
    visit(node.then);
    visit(node.otherwise);
  }

  @override
  void visitTryCatch(TryCatch node) {
    visit(node.body);
    node.catches.forEach((c) => visit(c.body));
  }

  @override
  void visitTryFinally(TryFinally node) {
    visit(node.body);
    visit(node.finalizer);
  }
}

/// Ensures that all of the known DartType implementors are handled.
///
/// The goal of the function is to catch a new unhandled implementor of
/// [DartType] in a chain of if-else statements analysing possibilities for an
/// object of DartType. It doesn't introduce a run-time overhead in production
/// code if used in an assert.
bool isKnownDartTypeImplementor(DartType t) {
  return t is BottomType ||
      t is DynamicType ||
      t is FunctionType ||
      t is FutureOrType ||
      t is InterfaceType ||
      t is InvalidType ||
      t is NeverType ||
      t is NullType ||
      t is TypeParameterType ||
      t is TypedefType ||
      t is VoidType;
}
