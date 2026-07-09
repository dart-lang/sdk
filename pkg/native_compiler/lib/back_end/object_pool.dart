// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:native_compiler/runtime/names.dart';

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
sealed class const SpecializedEntry() {
  /// Number of object pool entries reserved after this entry.
  int get numReservedEntries => 0;
}

/// Base class for specialized object pool entries which
/// occupy 2 slots in the object pool.
sealed class const PairSpecializedEntry() extends SpecializedEntry {
  /// Number of object pool entries reserved after this entry.
  @override
  int get numReservedEntries => 1;
}

/// Object pool entry representing tags for the new objects of the given class.
final class NewObjectTags(final ast.Class cls) extends SpecializedEntry {
  @override
  int get hashCode => cls.hashCode + 19;

  @override
  bool operator ==(Object other) =>
      other is NewObjectTags && this.cls == other.cls;
}

/// ICData call object pool entries occupies 2 slots: ICData, dispatcher code.
sealed class ICDataCallEntry(
  final CFunction owner,
  final ArgumentsShape argumentsShape, {
  required final Name selector,
}) extends PairSpecializedEntry {
  @override
  int get hashCode =>
      finalizeHash(combineHash(selector.hashCode, argumentsShape.hashCode));

  @override
  bool operator ==(Object other) =>
      other is ICDataCallEntry &&
      this.owner == other.owner &&
      this.argumentsShape == other.argumentsShape &&
      this.selector == other.selector;
}

/// InterfaceCall object pool entry occupies 2 slots: dispatcher data, dispatcher code.
/// TODO: switch from ICData calls to dispatch table calls.
final class InterfaceCallEntry extends ICDataCallEntry {
  InterfaceCallEntry(
    super.owner,
    super.argumentsShape,
    CFunction interfaceTarget,
  ) : super(selector: Name.interfaceCallSelector(interfaceTarget));
}

/// DynamicCall object pool entry occupies 2 slots: ICData, dispatcher code.
final class DynamicCallEntry extends ICDataCallEntry {
  DynamicCallEntry(
    super.owner,
    super.argumentsShape,
    DynamicCallKind kind,
    ast.Name selector,
  ) : super(selector: Name.dynamicCallSelector(kind, selector));
}

/// Reserved entry, filled from a preceeding [SpecializedEntry]
/// with a non-zero [numReservedEntries].
final class const ReservedEntry() extends SpecializedEntry {
  @override
  int get numReservedEntries => 0;
}

/// Object pool entry representing offset of the static field
/// relative to static field table.
final class StaticFieldOffset(final CField field) extends SpecializedEntry {
  @override
  int get hashCode => field.hashCode + 13;

  @override
  bool operator ==(Object other) =>
      other is StaticFieldOffset && this.field == other.field;
}

/// Object pool entry representing a subtype test cache.
/// This is not a specialized entry, it is encoded as a regular object reference.
final class SubtypeTestCache(final int numInputs) {
  // Use identity hashCode and == as separate subtype test caches are
  // used for each type check.
}

/// A pair (subtype test cache, name). VM decodes type testing stub
/// calling sequence and reads name from object pool immediately
/// after subtype test cache when throwing type errors.
final class SubtypeTestCacheWithName extends PairSpecializedEntry {
  final SubtypeTestCache stc;
  final Name name;

  SubtypeTestCacheWithName(this.stc, this.name);

  @override
  int get hashCode => finalizeHash(combineHash(stc.hashCode, name.hashCode));

  @override
  bool operator ==(Object other) =>
      other is SubtypeTestCacheWithName &&
      this.stc == other.stc &&
      this.name == other.name;
}
