// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.constants_native_effects;

import '../ast.dart';
import '../transformations/constants.dart';
import '../core_types.dart';

class VmConstantsBackend implements ConstantsBackend {
  final Class immutableMapClass;

  VmConstantsBackend._(this.immutableMapClass);

  factory VmConstantsBackend(CoreTypes coreTypes) {
    final Library coreLibrary = coreTypes.coreLibrary;
    final Class immutableMapClass = coreLibrary.classes
        .firstWhere((Class klass) => klass.name == '_ImmutableMap');
    assert(immutableMapClass != null);
    return new VmConstantsBackend._(immutableMapClass);
  }

  Constant buildConstantForNative(
      String nativeName,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments) {
    switch (nativeName) {
      case 'Bool_fromEnvironment':
        final String name = (positionalArguments[0] as StringConstant).value;
        final Constant constant = namedArguments['defaultValue'];
        final bool defaultValue =
            constant is BoolConstant ? constant.value : false;
        return new BoolConstant(
            new bool.fromEnvironment(name, defaultValue: defaultValue));
      case 'Integer_fromEnvironment':
        final String name = (positionalArguments[0] as StringConstant).value;
        final Constant constant = namedArguments['defaultValue'];
        final int defaultValue =
            constant is IntConstant ? constant.value : null;
        final int value =
            new int.fromEnvironment(name, defaultValue: defaultValue);
        return value != null ? new IntConstant(value) : new NullConstant();
      case 'String_fromEnvironment':
        final String name = (positionalArguments[0] as StringConstant).value;
        final Constant constant = namedArguments['defaultValue'];
        final String defaultValue =
            constant is StringConstant ? constant.value : null;
        final String value =
            new String.fromEnvironment(name, defaultValue: defaultValue);
        return value == null ? new NullConstant() : new StringConstant(value);
    }
    throw 'No native effect registered for constant evaluation: $nativeName';
  }

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
    // Strong mode is a bit fishy here, since we merge the key and the value
    // type by putting both into the same list!
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

  Constant lowerListConstant(ListConstant constant) {
    // Currently we let vipunen deal with the [ListConstant]s.
    return constant;
  }
}
