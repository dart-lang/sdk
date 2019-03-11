// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/summary/idl.dart';

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

  /// The corresponding [Element], or `null` if a named container.
  Element element;

  /// Temporary index used during serialization and linking.
  int index;

  Map<String, Reference> _children;

  Reference.root() : this._(null, '');

  Reference._(this.parent, this.name);

  bool get isClass => parent != null && parent.name == '@class';

  bool get isEnum => parent != null && parent.name == '@enum';

  bool get isGenericTypeAlias => parent != null && parent.name == '@typeAlias';

  bool get isTypeParameter => parent != null && parent.name == '@typeParameter';

  int get numOfChildren => _children != null ? _children.length : 0;

  /// Return the child with the given name, or `null` if does not exist.
  Reference operator [](String name) {
    return _children != null ? _children[name] : null;
  }

  /// Return the child with the given name, create if does not exist yet.
  Reference getChild(String name) {
    var map = _children ??= <String, Reference>{};
    return map[name] ??= new Reference._(this, name);
  }

  String toString() => parent == null ? 'root' : '$parent::$name';
}
