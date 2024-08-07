// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import '../ir/ir.dart' as ir;
import 'builder.dart';

/// Creates minimally sized rec groups given the types added to the builder.
///
/// The set of [ir.DefType]s defined in the program create a graph. Edges in
/// this graph are either supertype relationships or usage within the structure
/// of the type (e.g. a field in a struct or an input in a function).
///
/// Given this graph each rec group is a strongly connected component in the
/// graph. That is, two types should be in the same rec group if they are part
/// of a cycle in the graph.
///
/// The strongly connected components then form a DAG which defines the order
/// of our rec groups. The root of the DAG is the top type and all other types
/// follow from there.
///
/// Two Dart classes may map to structurally equivalent [ir.StructType]s. Having
/// them in the same rec group disambiguates them for the wasm type system. In
/// order to allow binaryen to optimize these class structs as independent types
/// we put structurally equivalent struct types into the same recursive group as
/// well.
class _RecGroupBuilder {
  late final List<List<ir.DefType>> _allRecursiveGroups =
      _createAllRecursiveGroups();
  final List<ir.DefType> _allDefinedTypes = [];

  _RecGroupBuilder();

  static bool _areStructurallyEqual(ir.DefType type1, ir.DefType type2) {
    return type1.isStructuralSubtypeOf(type2) &&
        type2.isStructuralSubtypeOf(type1);
  }

  /// Get the out-edges for [type] in the wasm type graph.
  Set<ir.DefType> _edgesforType(ir.DefType type) {
    final edges = <ir.DefType>{};
    for (final constituentType in type.constituentTypes) {
      if (constituentType is ir.RefType) {
        final heapType = constituentType.heapType;
        if (heapType is ir.DefType) {
          edges.add(heapType);
        }
      }
    }
    final superType = type.superType;
    if (superType != null) {
      edges.add(superType);
    }

    bool isStructurallyEqual(ir.DefType t) => _areStructurallyEqual(type, t);

    edges.addAll(_allDefinedTypes.where(isStructurallyEqual));
    return edges;
  }

  /// Create minimal recursive groups.
  ///
  /// Some groups may contain only unused types. Those groups can be dropped by
  /// callers of this function.
  List<List<ir.DefType>> _createAllRecursiveGroups() {
    Map<ir.DefType, Set<ir.DefType>> typeGraph = {};
    for (ir.DefType type in _allDefinedTypes) {
      typeGraph[type] = _edgesforType(type);
    }
    final components = stronglyConnectedComponents(typeGraph);
    final groups = <List<ir.DefType>>[];
    // Make sure to reverse the list since the components are returned with the
    // leaves first.
    for (final component in components.reversed) {
      final group = <ir.DefType>[];
      final added = <ir.DefType>{};
      void addToGroup(ir.DefType type) {
        if (!added.add(type)) return;
        if (component.contains(type.superType)) {
          // Supertypes must be added before their subtypes.
          addToGroup(type.superType!);
        }
        group.add(type);
      }

      for (final type in component) {
        addToGroup(type);
      }
      groups.add(group);
    }
    return groups;
  }

  void addDefinedType(ir.DefType type) {
    _allDefinedTypes.add(type);
  }

  /// Create a filtered list of recursive groups in type hierarchy order.
  ///
  /// [directlyUsedTypes] should be the list of types used directly in the
  /// module (i.e. types referenced from code, function definitions, etc.).
  /// Indirectly used types are referenced transitively from directly used
  /// types (i.e. fields of structs, function inputs, etc.).
  ///
  /// The returned list includes all rec groups that contain a directly or
  /// indirectly used type.
  List<List<ir.DefType>> createGroupsForModule(
      Set<ir.DefType> directlyUsedTypes) {
    final allUsedTypes = {...directlyUsedTypes};

    void addUsedType(ir.DefType type) {
      // Visit all the children of type and include them as well.
      for (final edge in _edgesforType(type)) {
        if (!allUsedTypes.add(edge)) continue;
        addUsedType(edge);
      }
    }

    for (final type in directlyUsedTypes) {
      addUsedType(type);
    }

    final usedGroups = <List<ir.DefType>>[];
    for (final group in _allRecursiveGroups) {
      if (group.any((type) => allUsedTypes.contains(type))) {
        usedGroups.add(group);
      }
    }
    return usedGroups;
  }
}

class TypesBuilder with Builder<ir.Types> {
  final ModuleBuilder _module;

  late final Map<_FunctionTypeKey, ir.FunctionType> _functionTypeMap = {};
  late final _RecGroupBuilder _recGroupBuilder = _RecGroupBuilder();

  TypesBuilder(this._module);

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
      final type = ir.FunctionType(inputList, outputList, superType: superType);
      _recGroupBuilder.addDefinedType(type);
      return type;
    });
  }

  /// Add a new struct type to the module.
  ///
  /// Fields can be added later, by adding to the [fields] list. This enables
  /// struct types to be recursive.
  ir.StructType defineStruct(String name,
      {Iterable<ir.FieldType>? fields, ir.DefType? superType}) {
    final type = ir.StructType(name, fields: fields, superType: superType);
    _recGroupBuilder.addDefinedType(type);
    return type;
  }

  /// Add a new array type to the module.
  ///
  /// The element type can be specified later. This enables array types to be
  /// recursive.
  ir.ArrayType defineArray(String name,
      {ir.FieldType? elementType, ir.DefType? superType}) {
    final type =
        ir.ArrayType(name, elementType: elementType, superType: superType);
    _recGroupBuilder.addDefinedType(type);
    return type;
  }

  Set<ir.DefType> _collectUsedTypes() {
    final usedTypes = <ir.DefType>{};
    _module.functions.collectUsedTypes(usedTypes);
    _module.globals.collectUsedTypes(usedTypes);
    _module.tags.collectUsedTypes(usedTypes);
    return usedTypes;
  }

  @override
  ir.Types forceBuild() {
    final usedTypes = _collectUsedTypes();
    final types = _recGroupBuilder.createGroupsForModule(usedTypes);
    final nameCount =
        types.fold(0, (p, e) => p + e.whereType<ir.DataType>().length);
    return ir.Types(types, nameCount);
  }
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
