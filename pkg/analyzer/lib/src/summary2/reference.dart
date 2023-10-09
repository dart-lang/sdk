// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';

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
  /// The name of the container used for duplicate declarations.
  static const _defName = '@def';

  /// The parent of this reference, or `null` if the root.
  Reference? parent;

  /// The simple name of the reference in its [parent].
  String name;

  /// The corresponding [Element], or `null` if a named container.
  Element? element;

  /// Temporary index used during serialization and linking.
  int? index;

  // null, Reference or Map<String, Reference>.
  Object? _childrenUnion;

  Reference.root() : this._(null, '');

  Reference._(this.parent, this.name);

  Iterable<Reference> get children {
    final childrenUnion = _childrenUnion;
    if (childrenUnion == null) return const [];
    if (childrenUnion is Reference) return [childrenUnion];
    return (childrenUnion as Map<String, Reference>).values;
  }

  @visibleForTesting
  Object? get childrenUnionForTesting => _childrenUnion;

  /// The name of the element that this reference represents.
  ///
  /// Normally, this is [name]. But in case of duplicate declarations, such
  /// as augmentations (which is allowed by the specification), or invalid
  /// code, the actual name is the name of the parent of the duplicates
  /// container `@def`.
  String get elementName {
    if (parent?.name == _defName) {
      return parent!.parent!.name;
    }
    return name;
  }

  bool get isLibrary => parent?.isRoot == true;

  bool get isPrefix => parent?.name == '@prefix';

  bool get isRoot => parent == null;

  bool get isSetter => parent?.name == '@setter';

  /// The parent that is not a container like `@method`.
  ///
  /// Usually this is the parent of the parent.
  /// @class::A::@method::foo -> @class::A
  ///
  /// But if this is a duplicates, we go two more levels up.
  /// @class::A::@method::foo::@def::0 -> @class::A
  Reference get parentNotContainer {
    // Should be `@method`, `@constructor`, etc.
    var containerInParent = parent!;

    // Skip the duplicates container.
    if (containerInParent.name == _defName) {
      containerInParent = containerInParent.parent!.parent!;
    }

    return containerInParent.parent!;
  }

  /// Return the child with the given name, or `null` if does not exist.
  Reference? operator [](String name) {
    name = _rewriteDartUi(name);

    final childrenUnion = _childrenUnion;
    if (childrenUnion == null) return null;
    if (childrenUnion is Reference) {
      if (childrenUnion.name == name) return childrenUnion;
      return null;
    }
    return (childrenUnion as Map<String, Reference>)[name];
  }

  /// Adds a new child with the given [name].
  ///
  /// This method should be used when a new declaration of an element with
  /// this name is processed. If there is no existing child with this name,
  /// this method works exactly as [getChild]. If there is a duplicate, which
  /// should happen rarely, an intermediate `@def` container is added, the
  /// existing child is transferred to it and renamed to `0`, then a new child
  /// is added with name `1`. Additional duplicate children get names `2`, etc.
  Reference addChild(String name) {
    final existing = this[name];

    // If not a duplicate.
    if (existing == null) {
      return getChild(name);
    }

    var def = existing[_defName];

    // If no duplicates container yet.
    if (def == null) {
      removeChild(name); // existing
      def = getChild(name).getChild(_defName);
      def._addChild('0', existing);
      existing.parent = def;
      existing.name = '0';
    }

    // Add a new child to the duplicates container.
    final indexStr = '${def.children.length}';
    return def.getChild(indexStr);
  }

  /// Return the child with the given name, create if does not exist yet.
  Reference getChild(String name) {
    name = _rewriteDartUi(name);

    final childrenUnion = _childrenUnion;
    if (childrenUnion == null) {
      // 0 -> 1 children.
      return _childrenUnion = Reference._(this, name);
    }
    if (childrenUnion is Reference) {
      if (childrenUnion.name == name) return childrenUnion;

      // 1 -> 2 children.
      final childrenUnionAsMap = _childrenUnion = <String, Reference>{};
      childrenUnionAsMap[childrenUnion.name] = childrenUnion;
      return childrenUnionAsMap[name] = Reference._(this, name);
    }
    return (childrenUnion as Map<String, Reference>)[name] ??=
        Reference._(this, name);
  }

  Reference? removeChild(String name) {
    name = _rewriteDartUi(name);

    final childrenUnion = _childrenUnion;
    if (childrenUnion == null) return null;
    if (childrenUnion is Reference) {
      if (childrenUnion.name == name) {
        // 1 -> 0 children.
        _childrenUnion = null;
        return childrenUnion;
      }
      return null;
    }
    final childrenUnionAsMap = childrenUnion as Map<String, Reference>;
    final result = childrenUnionAsMap.remove(name);
    if (childrenUnionAsMap.length == 1) {
      // 2 -> 1 children.
      _childrenUnion = childrenUnionAsMap.values.single;
    }
    return result;
  }

  @override
  String toString() => parent == null ? 'root' : '$parent::$name';

  void _addChild(String name, Reference child) {
    name = _rewriteDartUi(name);

    final childrenUnion = _childrenUnion;
    if (childrenUnion == null) {
      // 0 -> 1 children.
      _childrenUnion = child;
      return;
    }
    if (childrenUnion is Reference) {
      // 1 -> 2 children.
      final childrenUnionAsMap = _childrenUnion = <String, Reference>{};
      childrenUnionAsMap[childrenUnion.name] = childrenUnion;
      childrenUnionAsMap[name] = child;
      return;
    }
    (childrenUnion as Map<String, Reference>)[name] ??= child;
  }

  /// TODO(scheglov) Remove it, once when the actual issue is fixed.
  /// https://buganizer.corp.google.com/issues/203423390
  static String _rewriteDartUi(String name) {
    const srcPrefix = 'dart:ui/src/ui/';
    if (name.startsWith(srcPrefix)) {
      return 'dart:ui/${name.substring(srcPrefix.length)}';
    }
    return name;
  }
}
