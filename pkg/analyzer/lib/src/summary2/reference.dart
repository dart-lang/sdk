// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/scope.dart';

/// Indirection between a name and the corresponding [Element].
///
/// References are organized in a prefix tree.
/// Each reference knows its parent, children, and the [Element].
///
///      Library:
///         URI of library
///
///      Class:
///         Reference of the enclosing library
///         "@class"
///         Name of the class
///
///      Method:
///         Reference of the enclosing class
///         "@method"
///         Name of the method
///
/// There is only one reference object per [Element].
class Reference {
  /// The parent of this reference, or `null` if the root.
  final Reference parent;

  /// The simple name of the reference in its [parent].
  final String name;

  /// The corresponding [LinkedNode], or `null` if a named container.
  LinkedNode node;

  /// The corresponding [AstNode], or `null` if a named container.
  AstNode node2;

  /// The corresponding [Element], or `null` if a named container.
  Element element;

  /// Temporary index used during serialization and linking.
  int index;

  Map<String, Reference> _children;

  /// If this reference is an import prefix, the scope of this prefix.
  Scope prefixScope;

  Reference.root() : this._(null, '');

  Reference._(this.parent, this.name);

  Iterable<Reference> get children {
    if (_children != null) {
      return _children.values;
    }
    return const [];
  }

  bool get isClass => parent != null && parent.name == '@class';

  bool get isDynamic => name == 'dynamic' && parent?.name == 'dart:core';

  bool get isEnum => parent != null && parent.name == '@enum';

  bool get isPrefix => parent != null && parent.name == '@prefix';

  bool get isTypeAlias => parent != null && parent.name == '@typeAlias';

  /// Return the child with the given name, or `null` if does not exist.
  Reference operator [](String name) {
    return _children != null ? _children[name] : null;
  }

  /// Return the child with the given name, create if does not exist yet.
  Reference getChild(String name) {
    var map = _children ??= <String, Reference>{};
    return map[name] ??= new Reference._(this, name);
  }

  /// If the reference has element, and it is for the [node], return `true`.
  ///
  /// The element might be not `null`, but the node is different in case of
  /// duplicate declarations.
  bool hasElementFor(AstNode node) {
    if (element != null && node2 == node) {
      return true;
    } else {
      if (node2 == null) {
        node2 = node;
      }
      return false;
    }
  }

  String toString() => parent == null ? 'root' : '$parent::$name';
}
