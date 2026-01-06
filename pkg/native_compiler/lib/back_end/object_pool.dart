// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper class for building object pool accessible from generated code.
///
/// TODO: add tags, different kinds of entries.
class ObjectPool {
  final List<Object> entries = [];
  final Map<Object, int> _objects = {};

  int getObject(Object entry) => _objects[entry] ??= _addEntry(entry);

  int _addEntry(Object entry) {
    final index = entries.length;
    entries.add(entry);
    return index;
  }
}
