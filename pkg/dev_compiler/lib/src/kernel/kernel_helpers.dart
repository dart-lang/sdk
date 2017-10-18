// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';

/// Returns the enclosing library for reference [r].
Library getLibrary(NamedNode n) {
  while (n != null && n is! Library) {
    n = n.parent;
  }
  return n;
}

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
Expression findAnnotation(NamedNode node, bool test(Expression value)) {
  List<Expression> annotations;
  if (node is Class) {
    annotations = node.annotations;
  } else if (node is Typedef) {
    annotations = node.annotations;
  } else if (node is Procedure) {
    annotations = node.annotations;
  } else {
    return null;
  }
  return annotations.firstWhere(test, orElse: () => null);
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
