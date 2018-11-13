// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.constants_native_effects;

import '../ast.dart';
import '../transformations/constants.dart';
import '../core_types.dart';

class VmConstantsBackend implements ConstantsBackend {
  final Map<String, String> defines;

  final Class immutableMapClass;
  final Class internalSymbolClass;
  final Class stringClass;
  final Field symbolNameField;

  VmConstantsBackend._(this.defines, this.immutableMapClass,
      this.internalSymbolClass, this.stringClass, this.symbolNameField);

  /// If [defines] is not `null` it will be used for handling
  /// `const {bool,...}.fromEnvironment()` otherwise the current VM's values
  /// will be used.
  factory VmConstantsBackend(Map<String, String> defines, CoreTypes coreTypes) {
    final Library coreLibrary = coreTypes.coreLibrary;
    final Class immutableMapClass = coreLibrary.classes
        .firstWhere((Class klass) => klass.name == '_ImmutableMap');
    assert(immutableMapClass != null);

    final Class internalSymbolClass = coreTypes.internalSymbolClass;
    assert(internalSymbolClass != null);

    final Class stringClass = coreTypes.stringClass;
    assert(stringClass != null);

    final Field symbolNameField =
        internalSymbolClass.fields.where((Field field) {
      return field.isInstanceMember && field.name.name == '_name';
    }).single;

    return new VmConstantsBackend._(defines, immutableMapClass,
        internalSymbolClass, stringClass, symbolNameField);
  }

  Constant buildConstantForNative(
      String nativeName,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments,
      List<TreeNode> context,
      StaticInvocation node,
      ErrorReporter errorReporter,
      void abortEvaluation()) {
    if ([
      'Bool_fromEnvironment',
      'Integer_fromEnvironment',
      'String_fromEnvironment'
    ].contains(nativeName)) {
      final argument = positionalArguments[0];
      if (argument is StringConstant) {
        final name = argument.value;

        Constant handleFromEnvironment<ValueT, ConstantT>(
            {ValueT defaultValue,
            ValueT parse(String v, {ValueT defaultValue}),
            ValueT fromEnvironment(String name, {ValueT defaultValue}),
            ConstantT makeConstant(ValueT val)}) {
          final Constant constant = namedArguments['defaultValue'];
          if (constant is ConstantT) {
            defaultValue = (constant as dynamic).value;
          } else if (constant is NullConstant) {
            defaultValue = null;
          }
          ValueT value;
          if (defines != null) {
            value = parse(defines[name], defaultValue: defaultValue);
          } else {
            value = fromEnvironment(name, defaultValue: defaultValue);
          }
          return value != null ? makeConstant(value) : new NullConstant();
        }

        switch (nativeName) {
          case 'Bool_fromEnvironment':
            return handleFromEnvironment<bool, BoolConstant>(
                defaultValue: false,
                parse: (String v, {bool defaultValue}) {
                  final String defineValue = defines[name];
                  return defineValue == 'true'
                      ? true
                      : (defineValue == 'false' ? false : defaultValue);
                },
                fromEnvironment: (v, {defaultValue}) =>
                    bool.fromEnvironment(v, defaultValue: defaultValue),
                makeConstant: (v) => BoolConstant(v));
          case 'Integer_fromEnvironment':
            return handleFromEnvironment<int, IntConstant>(
                defaultValue: null,
                parse: (String v, {int defaultValue}) {
                  final String defineValue = defines[name];
                  return defineValue != null
                      ? (int.tryParse(defineValue) ?? defaultValue)
                      : defaultValue;
                },
                fromEnvironment: (v, {defaultValue}) =>
                    int.fromEnvironment(v, defaultValue: defaultValue),
                makeConstant: (v) => new IntConstant(v));
          case 'String_fromEnvironment':
            return handleFromEnvironment<String, StringConstant>(
                defaultValue: null,
                parse: (String v, {String defaultValue}) {
                  final String defineValue = defines[name];
                  return defineValue ?? defaultValue;
                },
                fromEnvironment: (v, {defaultValue}) =>
                    String.fromEnvironment(v, defaultValue: defaultValue),
                makeConstant: (v) => new StringConstant(v));
        }
      } else {
        errorReporter.invalidDartType(context, node.arguments.positional.first,
            argument, new InterfaceType(stringClass));
        abortEvaluation();
      }
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
