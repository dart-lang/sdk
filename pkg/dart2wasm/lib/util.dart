// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:vm/metadata/direct_call.dart' show DirectCallMetadataRepository;
import 'package:vm/metadata/inferred_type.dart'
    show
        InferredTypeMetadataRepository,
        InferredReturnTypeMetadataRepository,
        InferredArgTypeMetadataRepository;
import 'package:vm/metadata/procedure_attributes.dart'
    show ProcedureAttributesMetadataRepository;
import 'package:vm/metadata/table_selector.dart'
    show TableSelectorMetadataRepository;

final bool compilerAssertsEnabled = (() {
  bool compilerAsserts = false;
  assert(compilerAsserts = true);
  return compilerAsserts;
})();

bool hasPragma(CoreTypes coreTypes, Annotatable node, String name) {
  return getPragma(coreTypes, node, name, defaultValue: '') != null;
}

T? getPragma<T>(CoreTypes coreTypes, Annotatable node, String name,
    {T? defaultValue}) {
  for (Expression annotation in node.annotations) {
    if (annotation is ConstantExpression) {
      Constant constant = annotation.constant;
      if (constant is InstanceConstant) {
        if (constant.classNode == coreTypes.pragmaClass) {
          Constant? nameConstant =
              constant.fieldValues[coreTypes.pragmaName.fieldReference];
          if (nameConstant is StringConstant && nameConstant.value == name) {
            Constant? value =
                constant.fieldValues[coreTypes.pragmaOptions.fieldReference];
            if (value == null || value is NullConstant) {
              return defaultValue;
            }
            if (value is PrimitiveConstant<T>) {
              return value.value;
            }
            if (value is! T) {
              throw ArgumentError("$name pragma argument has unexpected type "
                  "${value.runtimeType} (expected $T)");
            }
            return value as T;
          }
        }
      }
    }
  }
  return null;
}

/// Add a `@pragma('wasm:entry-point')` annotation to an annotatable.
T addWasmEntryPointPragma<T extends Annotatable>(T node, CoreTypes coreTypes) =>
    addPragma(node, 'wasm:entry-point', coreTypes);

T addPragma<T extends Annotatable>(
        T node, String pragmaName, CoreTypes coreTypes, {Constant? value}) =>
    node
      ..addAnnotation(ConstantExpression(
          InstanceConstant(coreTypes.pragmaClass.reference, [], {
        coreTypes.pragmaName.fieldReference: StringConstant(pragmaName),
        coreTypes.pragmaOptions.fieldReference: value ?? NullConstant(),
      })));

List<int> _intToLittleEndianBytes(int i) {
  List<int> bytes = [];
  bytes.add(i & 0xFF);
  i >>>= 8;
  while (i != 0) {
    bytes.add(i & 0xFF);
    i >>>= 8;
  }
  return bytes;
}

String intToBase64(int i) => base64.encode(_intToLittleEndianBytes(i));

/// Maps ints to minimal length strings.
///
/// For simplicity, this only uses combinations of 1-byte characters. The 2+
/// byte characters don't significantly impact the average string size.
///
/// Starts at 1 to avoid emitting the empty string.
String intToMinString(int i) {
  assert(i >= 0);
  i += 1;
  final codeUnits = <int>[];
  while (i > 0) {
    int remainder = i % 128;
    i ~/= 128;
    codeUnits.add(remainder);
  }
  return String.fromCharCodes(codeUnits);
}

Component createEmptyComponent() {
  return Component()
    ..addMetadataRepository(ProcedureAttributesMetadataRepository())
    ..addMetadataRepository(TableSelectorMetadataRepository())
    ..addMetadataRepository(DirectCallMetadataRepository())
    ..addMetadataRepository(InferredTypeMetadataRepository())
    ..addMetadataRepository(InferredReturnTypeMetadataRepository())
    ..addMetadataRepository(InferredArgTypeMetadataRepository());
}
