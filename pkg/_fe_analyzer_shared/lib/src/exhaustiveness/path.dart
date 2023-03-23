// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'key.dart';

/// A path that describes location of a [SingleSpace] from the root of
/// enclosing [Space].
abstract class Path {
  const Path();

  /// Create root path.
  const factory Path.root() = _Root;

  /// Returns a path that adds a step by the [key] to the current path.
  Path add(Key key) => new _Step(this, key);

  void _toList(List<Key> list);

  /// Returns a list of the keys from the root to this path.
  List<Key> toList();
}

/// The root path object.
class _Root extends Path {
  const _Root();

  @override
  void _toList(List<Key> list) {}

  @override
  List<Key> toList() => const [];

  @override
  int get hashCode => 1729;

  @override
  bool operator ==(Object other) {
    return other is _Root;
  }

  @override
  String toString() => '@';
}

/// A single step in a path that holds the [parent] pointer and the [key] for
/// the step.
class _Step extends Path {
  final Path parent;
  final Key key;

  _Step(this.parent, this.key);

  @override
  List<Key> toList() {
    List<Key> list = [];
    _toList(list);
    return list;
  }

  @override
  void _toList(List<Key> list) {
    parent._toList(list);
    list.add(key);
  }

  @override
  late final int hashCode = Object.hash(parent, key);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Step && key == other.key && parent == other.parent;
  }

  @override
  String toString() {
    if (parent is _Root) {
      return key.name;
    } else {
      return '$parent.${key.name}';
    }
  }
}
