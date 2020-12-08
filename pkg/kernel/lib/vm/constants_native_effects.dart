// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.constants_native_effects;

import '../ast.dart';
import '../target/targets.dart';
import '../core_types.dart';

class VmConstantsBackend extends ConstantsBackend {
  final Class immutableMapClass;
  final Class unmodifiableSetClass;
  final Field unmodifiableSetMap;

  VmConstantsBackend._(this.immutableMapClass, this.unmodifiableSetMap,
      this.unmodifiableSetClass);

  /// If [defines] is not `null` it will be used for handling
  /// `const {bool,...}.fromEnvironment()` otherwise the current VM's values
  /// will be used.
  factory VmConstantsBackend(CoreTypes coreTypes) {
    final Library coreLibrary = coreTypes.coreLibrary;
    final Class immutableMapClass = coreLibrary.classes
        .firstWhere((Class klass) => klass.name == '_ImmutableMap');
    assert(immutableMapClass != null);
    Field unmodifiableSetMap = coreTypes.index
        .getMember('dart:collection', '_UnmodifiableSet', '_map');

    return new VmConstantsBackend._(immutableMapClass, unmodifiableSetMap,
        unmodifiableSetMap.enclosingClass);
  }

  @override
  Constant lowerMapConstant(MapConstant constant) {
    // The _ImmutableMap class is implemented via one field pointing to a list
    // of key/value pairs -- see runtime/lib/immutable_map.dart!
    final List<Constant> kvListPairs =
        new List<Constant>.filled(2 * constant.entries.length, null);
    for (int i = 0; i < constant.entries.length; i++) {
      final ConstantMapEntry entry = constant.entries[i];
      kvListPairs[2 * i] = entry.key;
      kvListPairs[2 * i + 1] = entry.value;
    }
    // This is a bit fishy, since we merge the key and the value type by
    // putting both into the same list.
    final ListConstant kvListConstant =
        new ListConstant(const DynamicType(), kvListPairs);
    assert(immutableMapClass.fields.length == 1);
    final Field kvPairListField = immutableMapClass.fields[0];
    return new InstanceConstant(immutableMapClass.reference, <DartType>[
      constant.keyType,
      constant.valueType,
    ], <Reference, Constant>{
      // We use getterReference as we refer to the field itself.
      kvPairListField.getterReference: kvListConstant,
    });
  }

  @override
  bool isLoweredMapConstant(Constant constant) {
    return constant is InstanceConstant &&
        constant.classNode == immutableMapClass;
  }

  @override
  void forEachLoweredMapConstantEntry(
      Constant constant, void Function(Constant key, Constant value) f) {
    assert(isLoweredMapConstant(constant));
    final InstanceConstant instance = constant;
    assert(immutableMapClass.fields.length == 1);
    final Field kvPairListField = immutableMapClass.fields[0];
    final ListConstant kvListConstant =
        instance.fieldValues[kvPairListField.getterReference];
    assert(kvListConstant.entries.length % 2 == 0);
    for (int index = 0; index < kvListConstant.entries.length; index += 2) {
      f(kvListConstant.entries[index], kvListConstant.entries[index + 1]);
    }
  }

  @override
  Constant lowerSetConstant(SetConstant constant) {
    final DartType elementType = constant.typeArgument;
    final List<Constant> entries = constant.entries;
    final List<ConstantMapEntry> mapEntries =
        new List<ConstantMapEntry>.filled(entries.length, null);
    for (int i = 0; i < entries.length; ++i) {
      mapEntries[i] = new ConstantMapEntry(entries[i], new NullConstant());
    }
    Constant map = lowerMapConstant(
        new MapConstant(elementType, const NullType(), mapEntries));
    return new InstanceConstant(unmodifiableSetClass.reference, [elementType],
        <Reference, Constant>{unmodifiableSetMap.getterReference: map});
  }

  @override
  bool isLoweredSetConstant(Constant constant) {
    if (constant is InstanceConstant &&
        constant.classNode == unmodifiableSetClass) {
      InstanceConstant instance = constant;
      return isLoweredMapConstant(
          instance.fieldValues[unmodifiableSetMap.getterReference]);
    }
    return false;
  }

  @override
  void forEachLoweredSetConstantElement(
      Constant constant, void Function(Constant element) f) {
    assert(isLoweredSetConstant(constant));
    final InstanceConstant instance = constant;
    final Constant mapConstant =
        instance.fieldValues[unmodifiableSetMap.getterReference];
    forEachLoweredMapConstantEntry(mapConstant, (Constant key, Constant value) {
      f(key);
    });
  }
}
