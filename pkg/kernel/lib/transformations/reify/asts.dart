// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.reify.ast_helpers;

import 'package:kernel/ast.dart';

Class getEnclosingClass(TreeNode node) {
  TreeNode original = node;
  while (node != null && node is! Class) {
    node = node.parent;
  }
  if (node == null) {
    throw 'internal error: enclosing class not found for $original';
  }
  return node;
}

Library getEnclosingLibrary(TreeNode node) {
  TreeNode original = node;
  while (node != null && node is! Library) {
    node = node.parent;
  }
  if (node == null) {
    throw 'internal error: enclosing library not found for $original';
  }
  return node;
}

Member getEnclosingMember(TreeNode node) {
  TreeNode original = node;
  while (node != null && node is! Member) {
    node = node.parent;
  }
  if (node == null) {
    throw 'internal error: enclosing member not found for $original';
  }
  return node;
}

List<TypeParameter> typeVariables(DartType type) {
  List<TypeParameter> parameters = <TypeParameter>[];
  collect(DartType type) {
    if (type is InterfaceType) {
      type.typeArguments.map(collect);
    } else if (type is TypeParameterType) {
      parameters.add(type.parameter);
    }
  }

  collect(type);
  return parameters;
}
