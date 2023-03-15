// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A path that describes location of a [SingleSpace] from the root of
/// enclosing [Space].
abstract class Path {
  const Path();

  /// Create root path.
  const factory Path.root() = _Root;

  /// Returns a path that adds a step by the [name] to the current path.
  Path add(String name) => new _Step(this, name);

  void _toList(List<String> list);

  /// Returns a list of the names from the root to this path.
  List<String> toList();
}

/// The root path object.
class _Root extends Path {
  const _Root();

  @override
  void _toList(List<String> list) {}

  @override
  List<String> toList() => const [];

  @override
  int get hashCode => 1729;

  @override
  bool operator ==(Object other) {
    return other is _Root;
  }

  @override
  String toString() => '@';
}

/// A single step in a path that holds the [parent] pointer the [name] for the
/// step.
class _Step extends Path {
  final Path parent;
  final String name;

  _Step(this.parent, this.name);

  @override
  List<String> toList() {
    List<String> list = [];
    _toList(list);
    return list;
  }

  @override
  void _toList(List<String> list) {
    parent._toList(list);
    list.add(name);
  }

  @override
  late final int hashCode = Object.hash(parent, name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Step && name == other.name && parent == other.parent;
  }

  @override
  String toString() {
    if (parent is _Root) {
      return name;
    } else {
      return '$parent.$name';
    }
  }
}
