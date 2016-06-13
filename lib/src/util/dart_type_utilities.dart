// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.util.dart_type_utilities;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/ast/ast.dart';

typedef bool AstNodePredicate(AstNode node);

class DartTypeUtilities {
  static bool unrelatedTypes(DartType leftType, DartType rightType) {
    if (leftType == null || leftType.isBottom || leftType.isDynamic ||
        rightType == null || rightType.isBottom || rightType.isDynamic) {
      return false;
    }
    if (leftType == rightType ||
        leftType.isMoreSpecificThan(rightType) ||
        rightType.isMoreSpecificThan(leftType)) {
      return false;
    }
    Element leftElement = leftType.element;
    Element rightElement = rightType.element;
    if (leftElement is ClassElement && rightElement is ClassElement) {
      return leftElement.supertype.isObject ||
          leftElement.supertype != rightElement.supertype;
    }
    return false;
  }

  static bool implementsInterface(DartType type, String interface,
      String library) {
    bool predicate(InterfaceType i) =>
        i.name == interface && i.element.library.name == library;
    ClassElement element = type.element;
    return predicate(type) || !element.isSynthetic &&
        type is InterfaceType &&
        element.allSupertypes.any(predicate);
  }

  /// Builds the list resulting from traversing the node in DFS and does not
  /// include the node itself.
  static List<AstNode> traverseNodesInDFS(AstNode node) {
    List<AstNode> nodes = [];
    node.childEntities
        .where((c) => c is AstNode)
        .forEach((c) {
      nodes.add(c);
      nodes.addAll(traverseNodesInDFS(c));
    });
    return nodes;
  }
}
