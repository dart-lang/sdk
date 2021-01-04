// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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

  /// The node accessor, used to read nodes lazily.
  /// Or `null` if a named container.
  ReferenceNodeAccessor nodeAccessor;

  /// The corresponding [AstNode], or `null` if a named container.
  AstNode node;

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

  bool get isConstructor => parent != null && parent.name == '@constructor';

  bool get isDynamic => name == 'dynamic' && parent?.name == 'dart:core';

  bool get isEnum => parent != null && parent.name == '@enum';

  bool get isGetter => parent != null && parent.name == '@getter';

  bool get isLibrary => parent != null && parent.isRoot;

  bool get isParameter => parent != null && parent.name == '@parameter';

  bool get isPrefix => parent != null && parent.name == '@prefix';

  bool get isRoot => parent == null;

  bool get isSetter => parent != null && parent.name == '@setter';

  bool get isTypeAlias => parent != null && parent.name == '@typeAlias';

  bool get isUnit => parent != null && parent.name == '@unit';

  /// Return the child with the given name, or `null` if does not exist.
  Reference operator [](String name) {
    return _children != null ? _children[name] : null;
  }

  /// Return the child with the given name, create if does not exist yet.
  Reference getChild(String name) {
    var map = _children ??= <String, Reference>{};
    return map[name] ??= Reference._(this, name);
  }

  /// If the reference has element, and it is for the [node], return `true`.
  ///
  /// The element might be not `null`, but the node is different in case of
  /// duplicate declarations.
  bool hasElementFor(AstNode node) {
    if (element != null && this.node == node) {
      return true;
    } else {
      if (node == null) {
        this.node = node;
      }
      return false;
    }
  }

  void removeChild(String name) {
    _children.remove(name);
  }

  @override
  String toString() => parent == null ? 'root' : '$parent::$name';
}

abstract class ReferenceNodeAccessor {
  /// Return the node that corresponds to this [Reference], read it if not yet.
  AstNode get node;

  /// Fill [Reference.nodeAccessor] for children.
  ///
  /// TODO(scheglov) only class reader has a meaningful implementation.
  void readIndex();
}
