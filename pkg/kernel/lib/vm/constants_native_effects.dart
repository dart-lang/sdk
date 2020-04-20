// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.constants_native_effects;

import '../ast.dart';
import '../target/targets.dart';
import '../core_types.dart';

class VmConstantsBackend extends ConstantsBackend {
  final Class immutableMapClass;

  VmConstantsBackend._(this.immutableMapClass);

  /// If [defines] is not `null` it will be used for handling
  /// `const {bool,...}.fromEnvironment()` otherwise the current VM's values
  /// will be used.
  factory VmConstantsBackend(CoreTypes coreTypes) {
    final Library coreLibrary = coreTypes.coreLibrary;
    final Class immutableMapClass = coreLibrary.classes
        .firstWhere((Class klass) => klass.name == '_ImmutableMap');
    assert(immutableMapClass != null);

    return new VmConstantsBackend._(immutableMapClass);
  }

  @override
  Constant lowerMapConstant(MapConstant constant) {
    // The _ImmutableMap class is implemented via one field pointing to a list
    // of key/value pairs -- see runtime/lib/immutable_map.dart!
    final List<Constant> kvListPairs =
        new List<Constant>(2 * constant.entries.length);
    for (int i = 0; i < constant.entries.length; i++) {
      final ConstantMapEntry entry = constant.entries[i];
      kvListPairs[2 * i] = entry.key;
      kvListPairs[2 * i + 1] = entry.value;
    }
    // This is a bit fishy, since we merge the key and the value type by
    // putting both into the same list.
    final kvListConstant = new ListConstant(const DynamicType(), kvListPairs);
    assert(immutableMapClass.fields.length == 1);
    final Field kvPairListField = immutableMapClass.fields[0];
    return new InstanceConstant(immutableMapClass.reference, <DartType>[
      constant.keyType,
      constant.valueType,
    ], <Reference, Constant>{
      kvPairListField.reference: kvListConstant,
    });
  }
}
