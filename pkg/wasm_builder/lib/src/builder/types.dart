// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:collection/collection.dart';
import '../ir/ir.dart' as ir;
import 'builder.dart';

/// The available field values that can be used in brand type StructTypes.
const List<ir.ValueType> _brandTypeFieldValues = [
  ir.NumType.i32,
  ir.NumType.i64,
  ir.NumType.f32,
  ir.NumType.f64,
  ir.NumType.v128,
  ir.RefType.extern(nullable: false),
  ir.RefType.extern(nullable: true),
  ir.RefType.any(nullable: false),
  ir.RefType.any(nullable: true),
  ir.RefType.func(nullable: false),
  ir.RefType.func(nullable: true),
  ir.RefType.none(nullable: false),
  ir.RefType.none(nullable: true),
  ir.RefType.noextern(nullable: false),
  ir.RefType.noextern(nullable: true),
  ir.RefType.nofunc(nullable: false),
  ir.RefType.nofunc(nullable: true),
];

/// Encodes [index] as a StructType that will not be a subtype of any other
/// index.
///
/// The produced brand type can be added to rec groups that would otherwise be
/// considered equal by the wasm type system. The brand types break the unwanted
/// equivalence relation between the groups.
///
/// The brand type must contain at least one field because every struct is a
/// subtype of the empty struct.
ir.StructType _getBrandType(int index) {
  final brandName = 'brand$index';
  final List<ir.FieldType> fields = [];
  final numDigits = _brandTypeFieldValues.length;
  do {
    final modValue = index % numDigits;
    // It's important that the fields are mutable. This ensures that the
    // contained StorageTypes must be mutual subtypes (i.e. they must be equal)
    // in order for them to match. Some of our brand digit options are subtypes
    // of others so to avoid them matching we need the mutual subtyping.
    fields.add(ir.FieldType(_brandTypeFieldValues[modValue], mutable: true));
    index = index ~/ numDigits;
  } while (index > 0);
  return ir.StructType(brandName, fields: fields);
}

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
/// Two Dart classes may map to structurally equivalent [ir.StructType]s. To
/// disambiguate them we assign unique brand types to rec groups that are
/// structually equivalent.
class _RecGroupBuilder {
  late final List<List<ir.DefType>> _allRecursiveGroups =
      _createAllRecursiveGroups();
  final List<ir.DefType> _allDefinedTypes = [];

  _RecGroupBuilder();

  /// Get the out-edges for [type] in the wasm type graph.
  static Set<ir.DefType> _edgesforType(ir.DefType type) {
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
    return edges;
  }

  /// Checks if two groups contain structurally equivalent struct types in the
  /// same order.
  ///
  /// Assumes both groups are the same size.
  static bool _areGroupsStructurallyEqual(
      List<ir.DefType> group1, List<ir.DefType> group2) {
    for (int i = 0; i < group1.length; i++) {
      final type1 = group1[i];
      final type2 = group2[i];
      if (type1 is! ir.StructType) {
        if (type2 is ir.StructType) return false;
        return type1.isStructuralSubtypeOf(type2) &&
            type2.isStructuralSubtypeOf(type1);
      }
      if (type2 is! ir.StructType) return false;
      if (!type1.isStructurallyEqualTo(type2)) return false;
    }
    return true;
  }

  /// Assigns brand types to structurally equivalent rec groups.
  ///
  /// If a rec group is in an equivalence class with multiple groups, it will be
  /// assigned an index encoded as a brand type. The brand types allows the wasm
  /// type system to disambiguate members of otherwise equivalent rec groups.
  static void _assignBrandTypes(List<List<ir.DefType>> groups) {
    // Collect rec groups joining over:
    // (1) group length
    // (2) length of first struct
    // (3) group structural equality
    final equivalenceGroups =
        LinkedHashMap<(int, int, List<ir.DefType>), List<List<ir.DefType>>>(
      hashCode: (a) => Object.hash(a.$1, a.$2),
      equals: (a, b) =>
          a.$1 == b.$1 &&
          a.$2 == b.$2 &&
          _areGroupsStructurallyEqual(a.$3, b.$3),
    );

    for (final group in groups) {
      final structIndex = group.indexWhere((g) => g is ir.StructType);
      // Skip groups with no struct types.
      if (structIndex == -1) continue;
      final structType = group[structIndex] as ir.StructType;
      equivalenceGroups.putIfAbsent(
          (group.length, structType.fields.length, group), () => []).add(group);
    }

    for (final equalGroups in equivalenceGroups.values) {
      // All the groups in `equalGroups` are structurally equivalent.
      // Skip the first group since we can leave one group as-is.
      for (int i = 1; i < equalGroups.length; i++) {
        equalGroups[i].insert(0, _getBrandType(i - 1));
      }
    }
  }

  /// Create minimal recursive groups.
  ///
  /// Some groups may contain only unused types. Those groups can be dropped by
  /// callers of this function.
  ///
  /// Adds brand types to groups where necessary so that similar struct types
  /// are not considered equivalent.
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

    _assignBrandTypes(groups);

    return groups;
  }

  void addDefinedType(ir.DefType type) {
    _allDefinedTypes.add(type);
  }

  /// Create a filtered list of rec groups in type hierarchy order.
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
