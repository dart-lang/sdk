// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/functions.dart';
import 'package:kernel/ast.dart' as ast;

/// Helper class for building object pool accessible from generated code.
class ObjectPool {
  final List<Object> entries = [];
  final Map<Object, int> _objects = {};

  int getObject(Object entry) => _objects[entry] ??= _addEntry(entry);

  int _addEntry(Object entry) {
    final index = entries.length;
    entries.add(entry);
    if (entry is SpecializedEntry) {
      for (int i = 0, n = entry.numReservedEntries; i < n; ++i) {
        entries.add(const ReservedEntry());
      }
    }
    return index;
  }
}

/// Base class for specialized object pool entries which are not just
/// object references.
sealed class SpecializedEntry {
  const SpecializedEntry();

  /// Number of object pool entries reserved after this entry.
  int get numReservedEntries => 0;
}

/// Base class for specialized object pool entries which
/// occupy 2 slots in the object pool.
sealed class PairSpecializedEntry extends SpecializedEntry {
  const PairSpecializedEntry();

  /// Number of object pool entries reserved after this entry.
  @override
  int get numReservedEntries => 1;
}

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

/// InterfaceCall object pool entry occupies 2 slots: dispatcher data, dispatcher code.
final class InterfaceCallEntry extends PairSpecializedEntry {
  final CFunction owner; // TODO: remove, only needed for ICData.
  final ArgumentsShape argumentsShape;
  final CFunction interfaceTarget;

  InterfaceCallEntry(this.owner, this.argumentsShape, this.interfaceTarget);

  /// Returns selector name corresponding to interface call
  /// in the VM convention (with get: and set: prefixes),
  /// but without a library key (`@nnnn`).
  String get selectorName {
    final simpleName = interfaceTarget.member.name.text;
    return switch (interfaceTarget) {
      GetterFunction() => 'get:$simpleName',
      SetterFunction() => 'set:$simpleName',
      _ => simpleName,
    };
  }

  @override
  int get hashCode => interfaceTarget.hashCode + 23;

  @override
  bool operator ==(Object other) =>
      other is InterfaceCallEntry &&
      this.owner == other.owner &&
      this.argumentsShape == other.argumentsShape &&
      this.interfaceTarget == other.interfaceTarget;
}

/// Reserved entry, filled from a preceeding [SpecializedEntry]
/// with a non-zero [numReservedEntries].
final class ReservedEntry extends SpecializedEntry {
  const ReservedEntry();

  @override
  int get numReservedEntries => 0;
}
