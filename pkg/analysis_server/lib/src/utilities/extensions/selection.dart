// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/src/utilities/selection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

extension SelectionExtension on Selection {
  /// The end of the selection.
  int get end => offset + length;

  /// Returns the element of the constructor at the given [selection].
  ///
  /// Returns `null` if
  /// - the selection doesn't identify a constructor, or
  /// - [mustHaveName] is `true` and the referenced constructor doesn't have a
  ///   name, or
  /// - [mustNotHaveName] is `true` and the referenced constructor has a name.
  ConstructorElement? constructor({
    bool mustHaveName = false,
    bool mustNotHaveName = false,
  }) {
    var node = coveringNode;

    bool meetsRequirements(Object? name) {
      if (name == null) {
        if (mustHaveName) return false;
      } else {
        if (mustNotHaveName) return false;
      }
      return true;
    }

    if (node is ConstructorDeclaration) {
      if (!meetsRequirements(node.name)) return null;
      var left =
          node.typeName?.offset ??
          node.factoryKeyword?.offset ??
          node.newKeyword?.offset ??
          node.firstTokenAfterCommentAndMetadata.offset;
      var right = node.separator?.offset ?? node.parameters.offset;
      if (left <= offset && end <= right) {
        return node.declaredFragment?.element;
      }
    } else if (node is SimpleIdentifier || node is FormalParameterList) {
      var parent = node.parent;
      if (parent is ConstructorDeclaration) {
        if (!meetsRequirements(parent.name)) return null;
        return parent.declaredFragment?.element;
      } else if (parent is ConstructorName) {
        if (!meetsRequirements(parent.name)) return null;
        return parent.element;
      }
    } else if (node is PrimaryConstructorDeclaration) {
      if (!meetsRequirements(node.constructorName)) return null;
      return node.declaredFragment?.element;
    } else if (node is PrimaryConstructorName) {
      if (!meetsRequirements(node.name)) return null;
      var parent = node.parent;
      if (parent is PrimaryConstructorDeclaration) {
        return parent.declaredFragment?.element;
      }
    } else if (node is NamedType) {
      var parent = node.parent;
      if (parent is ConstructorName) {
        if (!meetsRequirements(node.name)) return null;
        return parent.element;
      }
    } else if (node is ConstructorName) {
      if (!meetsRequirements(node.name)) return null;
      return node.element;
    }
    return null;
  }
}
