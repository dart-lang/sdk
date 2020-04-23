// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type_provider.dart';

/// Determines whether a type annotation's position in the AST makes it
/// impossible to be nullable.
bool typeIsNonNullableByContext(TypeAnnotation node) {
  var parent = node.parent;
  return parent is ExtendsClause ||
      parent is ImplementsClause ||
      parent is WithClause ||
      parent is OnClause ||
      parent is ClassTypeAlias ||
      parent is GenericTypeAlias ||
      parent is ConstructorName;
}

/// This mixin provides utilities that are useful to visitors implementing
/// resolution-like behaviors.
mixin ResolutionUtils {
  List<String> _objectGetNames;

  TypeProvider get typeProvider;

  /// Determines whether the given getter or method name is declared on
  /// `Object` (and is hence valid to call on a nullable type).
  bool isDeclaredOnObject(String name) =>
      (_objectGetNames ??= _computeObjectGetNames()).contains(name);

  List<String> _computeObjectGetNames() {
    var result = <String>[];
    var objectClass = typeProvider.objectType.element;
    for (var accessor in objectClass.accessors) {
      assert(accessor.isGetter);
      assert(!accessor.name.startsWith('_'));
      result.add(accessor.name);
    }
    for (var method in objectClass.methods) {
      assert(!method.name.startsWith('_'));
      result.add(method.name);
    }
    return result;
  }
}
