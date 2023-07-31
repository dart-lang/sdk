// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

class TypesBuilder with Builder<ir.Types> {
  final _recursionGroupSplits = <int>[];
  final _functionTypeMap = <_FunctionTypeKey, ir.FunctionType>{};
  final _defTypes = <ir.DefType>[];
  int _nameCount = 0;

  /// Add a new function type to the module.
  ///
  /// All function types are canonicalized, such that identical types become
  /// the same type definition in the module, assuming nominal type identity
  /// of all inputs and outputs.
  ///
  /// Inputs and outputs can't be changed after the function type is created.
  /// This means that recursive function types (without any non-function types
  /// on the recursion path) are not supported.
  ir.FunctionType defineFunction(
      Iterable<ir.ValueType> inputs, Iterable<ir.ValueType> outputs,
      {ir.DefType? superType}) {
    final List<ir.ValueType> inputList = List.unmodifiable(inputs);
    final List<ir.ValueType> outputList = List.unmodifiable(outputs);
    final _FunctionTypeKey key = _FunctionTypeKey(inputList, outputList);
    return _functionTypeMap.putIfAbsent(key, () {
      final type = ir.FunctionType(inputList, outputList, superType: superType)
        ..index = _defTypes.length;
      _defTypes.add(type);
      return type;
    });
  }

  /// Add a new struct type to the module.
  ///
  /// Fields can be added later, by adding to the [fields] list. This enables
  /// struct types to be recursive.
  ir.StructType defineStruct(String name,
      {Iterable<ir.FieldType>? fields, ir.DefType? superType}) {
    final type = ir.StructType(name, fields: fields, superType: superType)
      ..index = _defTypes.length;
    _defTypes.add(type);
    _nameCount++;
    return type;
  }

  /// Add a new array type to the module.
  ///
  /// The element type can be specified later. This enables array types to be
  /// recursive.
  ir.ArrayType defineArray(String name,
      {ir.FieldType? elementType, ir.DefType? superType}) {
    final type =
        ir.ArrayType(name, elementType: elementType, superType: superType)
          ..index = _defTypes.length;
    _defTypes.add(type);
    _nameCount++;
    return type;
  }

  /// Insert a recursion group split in the list of type definitions. Types can
  /// only reference other types in the same or earlier recursion groups.
  void splitRecursionGroup() {
    int typeCount = _defTypes.length;
    if (typeCount > 0 &&
        (_recursionGroupSplits.isEmpty ||
            _recursionGroupSplits.last != typeCount)) {
      _recursionGroupSplits.add(typeCount);
    }
  }

  @override
  ir.Types forceBuild() =>
      ir.Types(_defTypes, _recursionGroupSplits, _nameCount);
}

class _FunctionTypeKey {
  final List<ir.ValueType> inputs;
  final List<ir.ValueType> outputs;

  _FunctionTypeKey(this.inputs, this.outputs);

  @override
  bool operator ==(Object other) {
    if (other is! _FunctionTypeKey) return false;
    if (inputs.length != other.inputs.length) return false;
    if (outputs.length != other.outputs.length) return false;
    for (int i = 0; i < inputs.length; i++) {
      if (inputs[i] != other.inputs[i]) return false;
    }
    for (int i = 0; i < outputs.length; i++) {
      if (outputs[i] != other.outputs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int inputHash = 13;
    for (var input in inputs) {
      inputHash = inputHash * 17 + input.hashCode;
    }
    int outputHash = 23;
    for (var output in outputs) {
      outputHash = outputHash * 29 + output.hashCode;
    }
    return (inputHash * 2 + 1) * (outputHash * 2 + 1);
  }
}
