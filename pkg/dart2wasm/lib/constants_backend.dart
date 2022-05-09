// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/core_types.dart';

class WasmConstantsBackend extends ConstantsBackend {
  final Class unmodifiableSetClass;
  final Field unmodifiableSetMap;

  WasmConstantsBackend._(this.unmodifiableSetMap, this.unmodifiableSetClass);

  factory WasmConstantsBackend(CoreTypes coreTypes) {
    Field unmodifiableSetMap =
        coreTypes.index.getField('dart:collection', '_UnmodifiableSet', '_map');

    return new WasmConstantsBackend._(
        unmodifiableSetMap, unmodifiableSetMap.enclosingClass!);
  }

  @override
  Constant lowerSetConstant(SetConstant constant) {
    final DartType elementType = constant.typeArgument;
    final List<Constant> entries = constant.entries;
    final List<ConstantMapEntry> mapEntries =
        new List<ConstantMapEntry>.generate(entries.length, (int index) {
      return new ConstantMapEntry(entries[index], new NullConstant());
    });
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
          instance.fieldValues[unmodifiableSetMap.getterReference]!);
    }
    return false;
  }

  @override
  void forEachLoweredSetConstantElement(
      Constant constant, void Function(Constant element) f) {
    assert(isLoweredSetConstant(constant));
    final InstanceConstant instance = constant as InstanceConstant;
    final Constant mapConstant =
        instance.fieldValues[unmodifiableSetMap.getterReference]!;
    forEachLoweredMapConstantEntry(mapConstant, (Constant key, Constant value) {
      f(key);
    });
  }
}
