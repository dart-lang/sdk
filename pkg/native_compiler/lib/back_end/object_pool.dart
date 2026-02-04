// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast;

/// Helper class for building object pool accessible from generated code.
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

/// Base class for specialized object pool entries which are not just
/// object references.
sealed class SpecializedEntry {}

/// Object pool entry representing tags for the new objects of the given class.
final class NewObjectTags extends SpecializedEntry {
  final ast.Class cls;
  NewObjectTags(this.cls);

  @override
  int get hashCode => cls.hashCode + 19;

  @override
  bool operator ==(Object other) =>
      other is NewObjectTags && this.cls == other.cls;
}
