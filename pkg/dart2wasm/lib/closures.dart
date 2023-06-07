// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' show min;

import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:vm/metadata/procedure_attributes.dart';
import 'package:vm/transformations/type_flow/utils.dart' show UnionFind;

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Describes the implementation of a concrete closure, including its vtable
/// contents.
class ClosureImplementation {
  /// The representation of the closure.
  final ClosureRepresentation representation;

  /// The functions pointed to by the function entries in the vtable.
  ///
  /// This list does not include the dynamic call entry and the instantiation
  /// function.
  final List<w.DefinedFunction> functions;

  /// The vtable entry used for dynamic calls.
  final w.DefinedFunction dynamicCallEntry;

  /// The constant global variable pointing to the vtable.
  final w.Global vtable;

  ClosureImplementation(
      this.representation, this.functions, this.dynamicCallEntry, this.vtable);
}

/// Describes the representation of closures for a particular function
/// signature, including the layout of their vtable.
///
/// Each vtable layout will have an entry for each number of positional
/// arguments from 0 up to the maximum number for the signature, followed by
/// an entry for each (non-empty) combination of argument names that closures
/// with this layout can be called with.
class ClosureRepresentation {
  /// The struct field index in the vtable struct at which the function
  /// entries start.
  final int typeCount;

  /// The Wasm struct type for the vtable.
  final w.StructType vtableStruct;

  /// The Wasm struct type for the closure object.
  final w.StructType closureStruct;

  final Map<NameCombination, int>? _indexOfCombination;

  /// The struct type for the context of an instantiated closure.
  final w.StructType? instantiationContextStruct;

  /// Entry point functions for instantiations of this generic closure.
  late final List<w.DefinedFunction> instantiationTrampolines =
      _instantiationTrampolinesThunk!();
  List<w.DefinedFunction> Function()? _instantiationTrampolinesThunk;

  /// The function that instantiates this generic closure.
  late final w.DefinedFunction instantiationFunction =
      _instantiationFunctionThunk!();
  w.DefinedFunction Function()? _instantiationFunctionThunk;

  /// The function that takes instantiation context of this generic closure and
  /// another instantiation context (both as `ref
  /// #InstantiationClosureContextBase`) and compares types in the contexts.
  /// This function is used to implement function equality of instantiations.
  late final w.DefinedFunction instantiationTypeComparisonFunction =
      _instantiationTypeComparisonFunctionThunk!();
  w.DefinedFunction Function()? _instantiationTypeComparisonFunctionThunk;

  /// The signature of the function that instantiates this generic closure.
  w.FunctionType get instantiationFunctionType {
    assert(isGeneric);
    return getVtableFieldType(FieldIndex.vtableInstantiationFunction);
  }

  /// The type of the vtable function at given index.
  w.FunctionType getVtableFieldType(int index) =>
      (vtableStruct.fields[index].type as w.RefType).heapType as w.FunctionType;

  ClosureRepresentation(this.typeCount, this.vtableStruct, this.closureStruct,
      this._indexOfCombination, this.instantiationContextStruct);

  bool get isGeneric => typeCount > 0;

  /// Where the vtable entries for function calls start in the vtable struct.
  int get vtableBaseIndex => isGeneric
      ? ClosureLayouter.vtableBaseIndexGeneric
      : ClosureLayouter.vtableBaseIndexNonGeneric;

  /// The field index in the vtable struct for the function entry to use when
  /// calling the closure with the given number of positional arguments and the
  /// given set of named arguments.
  int fieldIndexForSignature(int posArgCount, List<String> argNames) {
    if (argNames.isEmpty) {
      return vtableBaseIndex + posArgCount;
    } else {
      return vtableBaseIndex +
          (posArgCount + 1) +
          _indexOfCombination![NameCombination(argNames)]!;
    }
  }

  /// The combinations of parameter names for which there are entries in the
  /// vtable of this closure, not including the empty combination, if
  /// applicable.
  Iterable<NameCombination> get nameCombinations =>
      _indexOfCombination?.keys ?? const [];
}

/// A combination of argument names for a call of a closure. The names within a
/// name combination are sorted alphabetically. Name combinations can be sorted
/// lexicographically according to their lists of names, corresponding to the
/// order in which entry points taking named arguments will appear in vtables.
class NameCombination implements Comparable<NameCombination> {
  List<String> names;

  NameCombination(this.names);

  @override
  int compareTo(NameCombination other) {
    int common = min(names.length, other.names.length);
    for (int i = 0; i < common; i++) {
      int comp = names[i].compareTo(other.names[i]);
      if (comp != 0) return comp;
    }
    return names.length - other.names.length;
  }

  @override
  String toString() => names.toString();
}

/// Visitor to collect all closures and closure calls in the program to
/// compute the vtable layouts necessary to cover all signatures that occur.
///
/// For each combination of type parameter count and positional parameter count,
/// the names of named parameters occurring together with that combination are
/// partitioned into clusters such that any combination of names that occurs
/// together is contained within a single cluster.
///
/// Each cluster gets a corresponding vtable layout with en extry point for each
/// combination of names from the cluster that occurs in a call in the program.
class ClosureLayouter extends RecursiveVisitor {
  final Translator translator;
  final Map<TreeNode, ProcedureAttributesMetadata> procedureAttributeMetadata;

  List<List<ClosureRepresentationsForParameterCount>> representations = [];

  Set<Constant> visitedConstants = Set.identity();

  // The member currently being visited while collecting function signatures.
  Member? currentMember;

  // For non-generic closures. The entries are:
  // 0: Dynamic call entry
  // 1-...: Entries for calling the closure
  static const int vtableBaseIndexNonGeneric = 1;

  // For generic closures. The entries are:
  // 0: Dynamic call entry
  // 1: Instantiation type comparison function
  // 2: Instantiation function
  // 3-...: Entries for calling the closure
  static const int vtableBaseIndexGeneric = 3;

  // Base struct for vtables without the dynamic call entry added. Referenced
  // by [closureBaseStruct] instead of the fully initialized version
  // ([vtableBaseStruct]) to break the type cycle.
  late final w.StructType _vtableBaseStructBare =
      m.addStructType("#VtableBase");

  /// Base struct for instantiation closure contexts. Type tests against this
  /// type is used in `_Closure._equals` to check if a closure is an
  /// instantiation.
  late final w.StructType instantiationContextBaseStruct =
      m.addStructType("#InstantiationClosureContextBase", fields: [
    w.FieldType(w.RefType.def(closureBaseStruct, nullable: false),
        mutable: false),
  ]);

  /// Base struct for non-generic closure vtables.
  late final w.StructType vtableBaseStruct = _vtableBaseStructBare
    ..fields.add(w.FieldType(
        w.RefType.def(translator.dynamicCallVtableEntryFunctionType,
            nullable: false),
        mutable: false));

  /// Base struct for generic closure vtables.
  late final w.StructType genericVtableBaseStruct = m.addStructType(
      "#GenericVtableBase",
      fields: vtableBaseStruct.fields.toList()
        ..add(w.FieldType(
            w.RefType.def(instantiationClosureTypeComparisonFunctionType,
                nullable: false),
            mutable: false)),
      superType: vtableBaseStruct);

  /// Type of [ClosureRepresentation.instantiationTypeComparisonFunction].
  late final w.FunctionType instantiationClosureTypeComparisonFunctionType =
      m.addFunctionType(
    [
      w.RefType.def(instantiationContextBaseStruct, nullable: false),
      w.RefType.def(instantiationContextBaseStruct, nullable: false)
    ],
    [w.NumType.i32], // bool
  );

  // Base struct for closures.
  late final w.StructType closureBaseStruct = _makeClosureStruct(
      "#ClosureBase", _vtableBaseStructBare, translator.closureInfo.struct);

  late final w.RefType typeType =
      translator.classInfo[translator.typeClass]!.nonNullableType;
  late final w.RefType functionTypeType =
      translator.classInfo[translator.functionTypeClass]!.nonNullableType;

  final Map<int, w.StructType> _instantiationContextBaseStructs = {};

  w.StructType _getInstantiationContextBaseStruct(int numTypes) =>
      _instantiationContextBaseStructs.putIfAbsent(
          numTypes,
          () => m.addStructType("#InstantiationClosureContextBase-$numTypes",
              fields: [
                w.FieldType(w.RefType.def(closureBaseStruct, nullable: false),
                    mutable: false),
                ...List.filled(numTypes, w.FieldType(typeType, mutable: false))
              ],
              superType: instantiationContextBaseStruct));

  final Map<int, w.DefinedFunction> _instantiationTypeComparisonFunctions = {};

  w.DefinedFunction _getInstantiationTypeComparisonFunction(int numTypes) =>
      _instantiationTypeComparisonFunctions.putIfAbsent(
          numTypes, () => _createInstantiationTypeComparisonFunction(numTypes));

  w.StructType _makeClosureStruct(
      String name, w.StructType vtableStruct, w.StructType superType) {
    // A closure contains:
    //  - A class ID (always the `_Closure` class ID)
    //  - An identity hash
    //  - A context reference (used for `this` in tear-offs)
    //  - A vtable reference
    //  - A `_FunctionType`
    return m.addStructType(name,
        fields: [
          w.FieldType(w.NumType.i32),
          w.FieldType(w.NumType.i32),
          w.FieldType(w.RefType.struct(nullable: false)),
          w.FieldType(w.RefType.def(vtableStruct, nullable: false),
              mutable: false),
          w.FieldType(functionTypeType, mutable: false)
        ],
        superType: superType);
  }

  w.Module get m => translator.m;
  w.ValueType get topType => translator.topInfo.nullableType;

  ClosureLayouter(this.translator)
      : procedureAttributeMetadata =
            (translator.component.metadata["vm.procedure-attributes.metadata"]
                    as ProcedureAttributesMetadataRepository)
                .mapping;

  void collect(List<FunctionNode> extraClosurizedFunctions) {
    translator.component.accept(this);
    for (FunctionNode function in extraClosurizedFunctions) {
      _visitFunctionNode(function);
    }
    computeClusters();
  }

  void computeClusters() {
    for (int typeCount = 0; typeCount < representations.length; typeCount++) {
      final representationsForTypeCount = representations[typeCount];
      for (int positionalCount = 0;
          positionalCount < representationsForTypeCount.length;
          positionalCount++) {
        final representationsForCounts =
            representationsForTypeCount[positionalCount];
        if (typeCount > 0) {
          // Due to generic function instantiations, any name combination that
          // occurs in a call of a non-generic function also counts as occurring
          // in a call of all corresponding generic functions.
          // Thus, the generic closure inherits the combinations for the
          // corresponding closure with zero type parameters.
          final instantiatedRepresentations =
              representations[0][positionalCount];
          representationsForCounts
              .inheritCombinationsFrom(instantiatedRepresentations);
        }
        representationsForCounts.computeClusters();
      }
    }
  }

  /// Get the representation for closures with a specific signature, described
  /// by the number of type parameters, the maximum number of positional
  /// parameters and the names of named parameters.
  ClosureRepresentation? getClosureRepresentation(
      int typeCount, int positionalCount, List<String> names) {
    final representations =
        _representationsForCounts(typeCount, positionalCount);
    if (representations.withoutNamed == null) {
      ClosureRepresentation? parent = positionalCount == 0
          ? null
          : getClosureRepresentation(typeCount, positionalCount - 1, const [])!;
      representations.withoutNamed = _createRepresentation(typeCount,
          positionalCount, const [], parent, null, [positionalCount]);
    }

    if (names.isEmpty) return representations.withoutNamed!;

    ClosureRepresentationCluster? cluster =
        representations.clusterForNames(names);
    if (cluster == null) return null;
    return cluster.representation ??= _createRepresentation(
        typeCount,
        positionalCount,
        names,
        representations.withoutNamed!,
        cluster.indexOfCombination,
        cluster.indexOfCombination.keys
            .map((c) => positionalCount + c.names.length));
  }

  ClosureRepresentation _createRepresentation(
      int typeCount,
      int positionalCount,
      List<String> names,
      ClosureRepresentation? parent,
      Map<NameCombination, int>? indexOfCombination,
      Iterable<int> paramCounts) {
    List<String> nameTags = ["$typeCount", "$positionalCount", ...names];
    String vtableName = ["#Vtable", ...nameTags].join("-");
    String closureName = ["#Closure", ...nameTags].join("-");
    w.StructType parentVtableStruct = parent?.vtableStruct ??
        (typeCount == 0 ? vtableBaseStruct : genericVtableBaseStruct);
    w.StructType vtableStruct = m.addStructType(vtableName,
        fields: parentVtableStruct.fields, superType: parentVtableStruct);
    w.StructType closureStruct = _makeClosureStruct(
        closureName, vtableStruct, parent?.closureStruct ?? closureBaseStruct);

    ClosureRepresentation? instantiatedRepresentation;
    w.StructType? instantiationContextStruct;
    if (typeCount > 0) {
      // Add or set vtable field for the instantiation function.
      instantiatedRepresentation =
          getClosureRepresentation(0, positionalCount, names)!;
      w.RefType inputType = w.RefType.def(closureBaseStruct, nullable: false);
      w.RefType outputType = w.RefType.def(
          instantiatedRepresentation.closureStruct,
          nullable: false);
      w.FunctionType instantiationFunctionType = m.addFunctionType(
          [inputType, ...List.filled(typeCount, typeType)], [outputType],
          superType: parent?.instantiationFunctionType);
      w.FieldType functionFieldType = w.FieldType(
          w.RefType.def(instantiationFunctionType, nullable: false),
          mutable: false);
      if (parent == null) {
        assert(vtableStruct.fields.length ==
            FieldIndex.vtableInstantiationFunction);
        vtableStruct.fields.add(functionFieldType);
      } else {
        vtableStruct.fields[FieldIndex.vtableInstantiationFunction] =
            functionFieldType;
      }

      // Build layout for the context of instantiated closures, containing the
      // original closure plus the type arguments.
      String instantiationContextName =
          ["#InstantiationContext", ...nameTags].join("-");
      instantiationContextStruct = m.addStructType(instantiationContextName,
          fields: [
            w.FieldType(w.RefType.def(closureStruct, nullable: false),
                mutable: false),
            ...List.filled(typeCount, w.FieldType(typeType, mutable: false))
          ],
          superType: _getInstantiationContextBaseStruct(typeCount));
    }

    // Add vtable fields for additional entry points relative to the parent.
    for (int paramCount in paramCounts) {
      w.FunctionType entry = m.addFunctionType([
        w.RefType.struct(nullable: false),
        ...List.filled(typeCount, typeType),
        ...List.filled(paramCount, topType)
      ], [
        topType
      ]);
      vtableStruct.fields.add(
          w.FieldType(w.RefType.def(entry, nullable: false), mutable: false));
    }

    ClosureRepresentation representation = ClosureRepresentation(
        typeCount,
        vtableStruct,
        closureStruct,
        indexOfCombination,
        instantiationContextStruct);

    if (typeCount > 0) {
      // The instantiation trampolines and the instantiation function can't be
      // produced now, since we might not have added the module imports yet, and
      // we can't define any functions before we have added the imports.
      // Therefore, we set thunks in the representation which will be called
      // when the instantiation function is needed, which will be during code
      // generation, after the imports have been added.

      representation._instantiationTrampolinesThunk = () {
        List<w.DefinedFunction> instantiationTrampolines = [
          ...?parent?.instantiationTrampolines
        ];
        if (names.isEmpty) {
          // Add trampoline to the corresponding entry in the generic closure.
          w.DefinedFunction trampoline = _createInstantiationTrampoline(
              typeCount,
              closureStruct,
              instantiationContextStruct!,
              instantiatedRepresentation!.vtableStruct,
              vtableBaseIndexNonGeneric + instantiationTrampolines.length,
              vtableStruct,
              vtableBaseIndexGeneric + instantiationTrampolines.length);
          instantiationTrampolines.add(trampoline);
        } else {
          // For each name combination in the instantiated closure, add a
          // trampoline to the entry for the same name combination in the
          // generic closure, or a dummy entry if the generic closure does not
          // have that name combination.
          for (NameCombination combination
              in instantiatedRepresentation!._indexOfCombination!.keys) {
            int? genericIndex = indexOfCombination![combination];
            w.DefinedFunction trampoline = genericIndex != null
                ? _createInstantiationTrampoline(
                    typeCount,
                    closureStruct,
                    instantiationContextStruct!,
                    instantiatedRepresentation.vtableStruct,
                    vtableBaseIndexNonGeneric + instantiationTrampolines.length,
                    vtableStruct,
                    vtableBaseIndexGeneric +
                        (positionalCount + 1) +
                        genericIndex)
                : translator.globals.getDummyFunction(
                    (instantiatedRepresentation
                            .vtableStruct
                            .fields[vtableBaseIndexNonGeneric +
                                instantiationTrampolines.length]
                            .type as w.RefType)
                        .heapType as w.FunctionType);
            instantiationTrampolines.add(trampoline);
          }
        }
        return instantiationTrampolines;
      };

      representation._instantiationFunctionThunk = () {
        String instantiationFunctionName =
            ["#Instantiation", ...nameTags].join("-");
        return _createInstantiationFunction(
            typeCount,
            instantiatedRepresentation!,
            representation.instantiationTrampolines,
            representation.instantiationFunctionType,
            instantiationContextStruct!,
            closureStruct,
            instantiationFunctionName);
      };

      representation._instantiationTypeComparisonFunctionThunk =
          () => _getInstantiationTypeComparisonFunction(typeCount);
    }

    return representation;
  }

  w.DefinedFunction _createInstantiationTrampoline(
      int typeCount,
      w.StructType genericClosureStruct,
      w.StructType contextStruct,
      w.StructType instantiatedVtableStruct,
      int instantiatedVtableFieldIndex,
      w.StructType genericVtableStruct,
      int genericVtableFieldIndex) {
    assert(contextStruct.fields.length == 1 + typeCount);
    w.FunctionType instantiatedFunctionType = (instantiatedVtableStruct
            .fields[instantiatedVtableFieldIndex].type as w.RefType)
        .heapType as w.FunctionType;
    w.FunctionType genericFunctionType =
        (genericVtableStruct.fields[genericVtableFieldIndex].type as w.RefType)
            .heapType as w.FunctionType;
    assert(genericFunctionType.inputs.length ==
        instantiatedFunctionType.inputs.length + typeCount);

    w.DefinedFunction trampoline = m.addFunction(instantiatedFunctionType);
    w.Instructions b = trampoline.body;

    // Cast context reference to actual context type.
    w.RefType contextType = w.RefType.def(contextStruct, nullable: false);
    w.Local contextLocal = trampoline.addLocal(contextType);
    b.local_get(trampoline.locals[0]);
    b.ref_cast(contextType);
    b.local_tee(contextLocal);

    // Push inner context
    b.struct_get(contextStruct, FieldIndex.instantiationContextInner);
    b.struct_get(genericClosureStruct, FieldIndex.closureContext);

    // Push type arguments
    for (int t = 0; t < typeCount; t++) {
      b.local_get(contextLocal);
      b.struct_get(
          contextStruct, FieldIndex.instantiationContextTypeArgumentsBase + t);
    }

    // Push arguments
    for (int p = 1; p < instantiatedFunctionType.inputs.length; p++) {
      b.local_get(trampoline.locals[p]);
    }

    // Call inner
    b.local_get(contextLocal);
    b.struct_get(contextStruct, FieldIndex.instantiationContextInner);
    b.struct_get(genericClosureStruct, FieldIndex.closureVtable);
    b.struct_get(genericVtableStruct, genericVtableFieldIndex);
    b.call_ref(genericFunctionType);
    b.end();

    return trampoline;
  }

  w.DefinedFunction _createInstantiationDynamicCallEntry(
      int typeCount, w.StructType instantiationContextStruct) {
    w.DefinedFunction function = m.addFunction(
        translator.dynamicCallVtableEntryFunctionType,
        "instantiation dynamic call entry");
    w.Instructions b = function.body;

    final instantiatedClosureLocal = function.locals[0];
    // First argument is the type list, which will always be empty. We'll pass
    // the instantiation types to the original vtable entry.
    final posArgsListLocal = function.locals[2];
    final namedArgsListLocal = function.locals[3];

    // Get instantiation context, which has the original closure and type
    // arguments
    final w.RefType instantiationContextType =
        w.RefType.def(instantiationContextStruct, nullable: false);
    final w.Local instantiationContextLocal =
        function.addLocal(instantiationContextType);
    b.local_get(instantiatedClosureLocal);
    b.struct_get(closureBaseStruct, FieldIndex.closureContext);
    b.ref_cast(instantiationContextType);
    b.local_tee(instantiationContextLocal);

    // Push original closure
    b.struct_get(
        instantiationContextStruct, FieldIndex.instantiationContextInner);

    // Push types, as list
    translator.makeList(
        function,
        (b) {
          translator.constants.instantiateConstant(
              function,
              b,
              TypeLiteralConstant(
                  InterfaceType(translator.typeClass, Nullability.nonNullable)),
              translator.types.nonNullableTypeType);
        },
        typeCount,
        (elementType, elementIdx) {
          b.local_get(instantiationContextLocal);
          b.struct_get(instantiationContextStruct,
              FieldIndex.instantiationContextTypeArgumentsBase + elementIdx);
        },
        isGrowable: true);

    b.local_get(posArgsListLocal);
    b.local_get(namedArgsListLocal);

    // Call inner
    b.local_get(instantiationContextLocal);
    b.struct_get(
        instantiationContextStruct, FieldIndex.instantiationContextInner);
    b.struct_get(closureBaseStruct, FieldIndex.closureVtable);
    b.struct_get(vtableBaseStruct, FieldIndex.vtableDynamicCallEntry);
    b.call_ref(translator.dynamicCallVtableEntryFunctionType);
    b.end();

    return function;
  }

  w.DefinedFunction _createInstantiationFunction(
      int typeCount,
      ClosureRepresentation instantiatedRepresentation,
      List<w.DefinedFunction> instantiationTrampolines,
      w.FunctionType functionType,
      w.StructType contextStruct,
      w.StructType genericClosureStruct,
      String name) {
    assert(typeCount > 0);
    w.RefType genericClosureType =
        w.RefType.def(genericClosureStruct, nullable: false);
    w.RefType instantiatedClosureType = w.RefType.def(
        instantiatedRepresentation.closureStruct,
        nullable: false);
    assert(functionType.outputs.single == instantiatedClosureType);

    // Create vtable for the instantiated closure, containing the trampolines.
    w.DefinedGlobal vtable = m.addGlobal(w.GlobalType(
        w.RefType.def(instantiatedRepresentation.vtableStruct, nullable: false),
        mutable: false));
    w.Instructions ib = vtable.initializer;
    ib.ref_func(_createInstantiationDynamicCallEntry(typeCount, contextStruct));
    for (w.DefinedFunction trampoline in instantiationTrampolines) {
      ib.ref_func(trampoline);
    }
    ib.struct_new(instantiatedRepresentation.vtableStruct);
    ib.end();

    w.DefinedFunction instantiationFunction = m.addFunction(functionType, name);
    w.Local preciseClosure = instantiationFunction.addLocal(genericClosureType);
    w.Instructions b = instantiationFunction.body;

    // Parameters to the instantiation function
    final w.Local closureParam = instantiationFunction.locals[0];
    w.Local typeParam(int i) => instantiationFunction.locals[1 + i];

    // Header for the closure struct
    b.i32_const(translator.closureInfo.classId);
    b.i32_const(initialIdentityHash);

    // Context for the instantiated closure, containing the original closure and
    // the type arguments
    b.local_get(closureParam);
    b.ref_cast(genericClosureType);
    b.local_tee(preciseClosure);
    for (int i = 0; i < typeCount; i++) {
      b.local_get(typeParam(i));
    }
    b.struct_new(contextStruct);

    b.global_get(vtable);

    // Construct the type of the instantiated closure, which is the type of the
    // original closure with the type arguments of the instantiation substituted
    // for its type parameters.

    // Type of the original closure
    b.local_get(preciseClosure);
    b.struct_get(genericClosureStruct, FieldIndex.closureRuntimeType);

    // Put type arguments into a `List<_Type>`.
    ClassInfo listInfo = translator.classInfo[translator.fixedLengthListClass]!;
    translator.functions.allocateClass(listInfo.classId);
    Constant typeConstant = TypeLiteralConstant(
        InterfaceType(translator.typeClass, Nullability.nonNullable));
    b.i32_const(listInfo.classId);
    b.i32_const(initialIdentityHash);
    translator.constants
        .instantiateConstant(instantiationFunction, b, typeConstant, typeType);
    b.i64_const(typeCount);
    for (int i = 0; i < typeCount; i++) {
      b.local_get(typeParam(i));
    }
    b.array_new_fixed(translator.listArrayType, typeCount);
    b.struct_new(listInfo.struct);

    // Call [_TypeUniverse.substituteFunctionTypeArgument].
    b.call(translator.functions
        .getFunction(translator.substituteFunctionTypeArgument.reference));

    // Finally, allocate closure struct.
    b.struct_new(instantiatedRepresentation.closureStruct);

    b.end();

    return instantiationFunction;
  }

  w.DefinedFunction _createInstantiationTypeComparisonFunction(int numTypes) {
    final function = m.addFunction(
        instantiationClosureTypeComparisonFunctionType,
        "#InstantiationTypeComparison-$numTypes");

    final w.Instructions b = function.body;

    final contextStructType = _getInstantiationContextBaseStruct(numTypes);
    final contextRefType = w.RefType.def(contextStructType, nullable: false);

    final thisContext = function.locals[0];
    final otherContext = function.locals[1];

    final thisContextLocal = function.addLocal(contextRefType);
    final otherContextLocal = function.addLocal(contextRefType);

    // Call site (`_Closure._equals`) checks that closures are instantiations
    // of the same function, so we can assume they have the right instantiation
    // context types.
    b.local_get(otherContext);
    b.ref_cast(contextRefType);
    b.local_set(otherContextLocal);

    b.local_get(thisContext);
    b.ref_cast(contextRefType);
    b.local_set(thisContextLocal);

    for (int i = 0; i < numTypes; i += 1) {
      final typeFieldIdx = FieldIndex.instantiationContextTypeArgumentsBase + i;
      b.local_get(thisContextLocal);
      b.struct_get(contextStructType, typeFieldIdx);
      b.local_get(otherContextLocal);
      b.struct_get(contextStructType, typeFieldIdx);

      // Virtual call to `Object.==`
      final selector = translator.dispatchTable
          .selectorForTarget(translator.coreTypes.objectEquals.reference);
      final selectorOffset = selector.offset!;
      b.local_get(thisContextLocal);
      b.struct_get(contextStructType, typeFieldIdx);
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      if (selectorOffset != 0) {
        b.i32_const(selectorOffset);
        b.i32_add();
      }
      b.call_indirect(selector.signature, translator.dispatchTable.wasmTable);
      b.if_();
    }

    b.i32_const(1); // true
    b.return_();

    for (int i = 0; i < numTypes; i += 1) {
      b.end();
    }

    b.i32_const(0); // false
    b.end(); // end of function
    return function;
  }

  ClosureRepresentationsForParameterCount _representationsForCounts(
      int typeCount, int positionalCount) {
    while (representations.length <= typeCount) {
      representations.add([]);
    }
    List<ClosureRepresentationsForParameterCount> positionals =
        representations[typeCount];
    while (positionals.length <= positionalCount) {
      positionals.add(ClosureRepresentationsForParameterCount());
    }
    return positionals[positionalCount];
  }

  void _visitFunctionNode(FunctionNode functionNode) {
    final representations = _representationsForCounts(
        functionNode.typeParameters.length,
        functionNode.positionalParameters.length);
    representations.registerFunction(functionNode);
    if (functionNode.typeParameters.isNotEmpty) {
      // Due to generic function instantiations, any generic function present
      // in the program also counts as a presence of the corresponding
      // non-generic function.
      final instantiatedRepresentations = _representationsForCounts(
          0, functionNode.positionalParameters.length);
      instantiatedRepresentations.registerFunction(functionNode);
    }
  }

  void _visitFunctionInvocation(Arguments arguments) {
    final representations = _representationsForCounts(
        arguments.types.length, arguments.positional.length);
    representations.registerCall(arguments);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _visitFunctionNode(node.function);
    if (currentMember != null) {
      translator.membersContainingInnerFunctions.add(currentMember!);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _visitFunctionNode(node.function);
    if (currentMember != null) {
      translator.membersContainingInnerFunctions.add(currentMember!);
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.isInstanceMember) {
      ProcedureAttributesMetadata metadata = procedureAttributeMetadata[node]!;
      if (metadata.hasTearOffUses) {
        _visitFunctionNode(node.function);
      }
    }
    currentMember = node;
    super.visitProcedure(node);
    currentMember = null;
  }

  @override
  void visitConstructor(Constructor node) {
    currentMember = node;
    super.visitConstructor(node);
    currentMember = null;
  }

  @override
  void visitStaticTearOffConstantReference(StaticTearOffConstant constant) {
    _visitFunctionNode(constant.function);
  }

  @override
  void defaultConstantReference(Constant constant) {
    if (visitedConstants.add(constant)) {
      constant.visitChildren(this);
    }
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    _visitFunctionInvocation(node.arguments);
    super.visitFunctionInvocation(node);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    if (node.name.text == "call") {
      _visitFunctionInvocation(node.arguments);
    }
    super.visitDynamicInvocation(node);
  }
}

class ClosureRepresentationsForParameterCount {
  ClosureRepresentation? withoutNamed;
  final Set<NameCombination> callCombinations = SplayTreeSet();
  final Map<String, int> nameIds = SplayTreeMap();
  final UnionFind nameUnions = UnionFind();
  final Map<String, ClosureRepresentationCluster> clusterForName = {};

  void registerFunction(FunctionNode functionNode) {
    int? prevIndex = null;
    for (VariableDeclaration named in functionNode.namedParameters) {
      String name = named.name!;
      int nameIndex = nameIds.putIfAbsent(name, () => nameUnions.add());
      if (prevIndex != null) {
        nameUnions.union(prevIndex, nameIndex);
      }
      prevIndex = nameIndex;
    }
  }

  void registerCall(Arguments arguments) {
    if (arguments.named.isNotEmpty) {
      NameCombination combination =
          NameCombination(arguments.named.map((a) => a.name).toList()..sort());
      callCombinations.add(combination);
    }
  }

  void inheritCombinationsFrom(ClosureRepresentationsForParameterCount other) {
    callCombinations.addAll(other.callCombinations);
  }

  ClosureRepresentationCluster? clusterForNames(List<String> names) {
    final cluster = clusterForName[names[0]];
    for (int i = 1; i < names.length; i++) {
      if (clusterForName[names[i]] != cluster) {
        return null;
      }
    }
    return cluster;
  }

  void computeClusters() {
    Map<int, ClosureRepresentationCluster> clusterForId = {};
    nameIds.forEach((name, id) {
      int canonicalId = nameUnions.find(id);
      final cluster = clusterForId.putIfAbsent(canonicalId, () {
        return ClosureRepresentationCluster();
      });
      cluster.names.add(name);
      clusterForName[name] = cluster;
    });
    for (NameCombination combination in callCombinations) {
      final cluster = clusterForNames(combination.names);
      if (cluster != null) {
        cluster.indexOfCombination[combination] =
            cluster.indexOfCombination.length;
      }
    }
  }
}

class ClosureRepresentationCluster {
  final List<String> names = [];
  final Map<NameCombination, int> indexOfCombination = SplayTreeMap();
  ClosureRepresentation? representation;
}

/// A local function or function expression.
class Lambda {
  final FunctionNode functionNode;
  final w.DefinedFunction function;

  Lambda(this.functionNode, this.function);
}

/// The context for one or more closures, containing their captured variables.
///
/// Contexts can be nested, corresponding to the scopes covered by the contexts.
/// Each local function, function expression or loop (`while`, `do`/`while` or
/// `for`) gives rise to its own context nested inside the context of its
/// surrounding scope. At runtime, each context has a reference to its parent
/// context.
///
/// Closures corresponding to local functions or function expressions in the
/// same scope share the same context. Thus, a closure can potentially keep more
/// values alive than the ones captured by the closure itself.
///
/// A context may be empty (containing no captured variables), in which case it
/// is skipped in the context parent chain and never allocated. A context can
/// also be skipped if it only contains variables that are not in scope for the
/// child context (and its descendants).
class Context {
  /// The node containing the scope covered by the context. This is either a
  /// [FunctionNode] (for members, local functions and function expressions),
  /// a [ForStatement], a [DoStatement] or a [WhileStatement].
  final TreeNode owner;

  /// The parent of this context, corresponding to the lexically enclosing
  /// owner. This is null if the context is a member context, or if all contexts
  /// in the parent chain are skipped.
  final Context? parent;

  /// The variables captured by this context.
  final List<VariableDeclaration> variables = [];

  /// The type parameters captured by this context.
  final List<TypeParameter> typeParameters = [];

  /// Whether this context contains a captured `this`. Only member contexts can.
  bool containsThis = false;

  /// The Wasm struct representing this context at runtime.
  late final w.StructType struct;

  /// The local variable currently pointing to this context. Used during code
  /// generation.
  late w.Local currentLocal;

  bool get isEmpty =>
      variables.isEmpty && typeParameters.isEmpty && !containsThis;

  int get parentFieldIndex {
    assert(parent != null);
    return 0;
  }

  int get thisFieldIndex {
    assert(containsThis);
    return 0;
  }

  Context(this.owner, this.parent);
}

/// A captured variable.
class Capture {
  final TreeNode variable;
  late final Context context;
  late final int fieldIndex;

  /// Whether the captured variable is updated after initialization.
  ///
  /// If the variable is not updated, we can create a local for the variable
  /// and use it for reads. If it's updated we need to read it from the
  /// context.
  bool written = false;

  Capture(this.variable);

  w.ValueType get type => context.struct.fields[fieldIndex].type.unpacked;
}

/// Compiler passes to find all captured variables and construct the context
/// tree for a member.
class Closures {
  final CodeGenerator codeGen;
  final Map<TreeNode, Capture> captures = {};
  bool isThisCaptured = false;
  final Map<FunctionNode, Lambda> lambdas = {};
  final Map<TreeNode, Context> contexts = {};
  final Set<FunctionDeclaration> closurizedFunctions = {};

  Closures(this.codeGen);

  Translator get translator => codeGen.translator;

  w.Module get m => translator.m;

  late final w.ValueType typeType =
      translator.classInfo[translator.typeClass]!.nonNullableType;

  void findCaptures(Member member) {
    var find = CaptureFinder(this, member);
    if (member is Constructor) {
      Class cls = member.enclosingClass;
      for (Field field in cls.fields) {
        if (field.isInstanceMember && field.initializer != null) {
          field.initializer!.accept(find);
        }
      }
    }
    member.accept(find);
  }

  void collectContexts(TreeNode node, {TreeNode? container}) {
    if (captures.isNotEmpty || isThisCaptured) {
      node.accept(
          ContextCollector(this, container, translator.options.enableAsserts));
    }
  }

  void buildContexts() {
    // Make struct definitions
    for (Context context in contexts.values) {
      if (!context.isEmpty) {
        context.struct = m.addStructType("<context>");
      }
    }

    // Build object layouts
    for (Context context in contexts.values) {
      if (!context.isEmpty) {
        w.StructType struct = context.struct;
        if (context.parent != null) {
          assert(!context.containsThis);
          assert(!context.parent!.isEmpty);
          struct.fields.add(w.FieldType(
              w.RefType.def(context.parent!.struct, nullable: true)));
        }
        if (context.containsThis) {
          struct.fields.add(w.FieldType(
              codeGen.preciseThisLocal!.type.withNullability(true)));
        }
        for (VariableDeclaration variable in context.variables) {
          int index = struct.fields.length;
          struct.fields.add(w.FieldType(
              translator.translateType(variable.type).withNullability(true)));
          captures[variable]!.fieldIndex = index;
        }
        for (TypeParameter parameter in context.typeParameters) {
          int index = struct.fields.length;
          struct.fields.add(w.FieldType(typeType.withNullability(true)));
          captures[parameter]!.fieldIndex = index;
        }
      }
    }
  }
}

class CaptureFinder extends RecursiveVisitor {
  final Closures closures;
  final Member member;
  final Map<TreeNode, int> variableDepth = {};
  final List<bool> functionIsSyncStarOrAsync = [false];

  int get depth => functionIsSyncStarOrAsync.length - 1;

  CaptureFinder(this.closures, this.member);

  Translator get translator => closures.translator;

  w.Module get m => translator.m;

  @override
  void visitFunctionNode(FunctionNode node) {
    assert(depth == 0); // Nested function nodes are skipped by [_visitLambda].
    functionIsSyncStarOrAsync[0] = node.asyncMarker == AsyncMarker.SyncStar ||
        node.asyncMarker == AsyncMarker.Async;
    node.visitChildren(this);
    functionIsSyncStarOrAsync[0] = false;
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (translator.options.enableAsserts) {
      super.visitAssertStatement(node);
    }
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    if (translator.options.enableAsserts) {
      super.visitAssertBlock(node);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (depth > 0) {
      variableDepth[node] = depth;
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    if (node.parent is FunctionNode) {
      if (depth > 0) {
        variableDepth[node] = depth;
      }
    }
    super.visitTypeParameter(node);
  }

  void _visitVariableUse(TreeNode variable) {
    int declDepth = variableDepth[variable] ?? 0;
    assert(declDepth <= depth);
    if (declDepth < depth || functionIsSyncStarOrAsync[declDepth]) {
      final capture = closures.captures[variable] ??= Capture(variable);
      if (functionIsSyncStarOrAsync[declDepth]) capture.written = true;
    } else if (variable is VariableDeclaration &&
        variable.parent is FunctionDeclaration) {
      closures.closurizedFunctions.add(variable.parent as FunctionDeclaration);
    }
  }

  @override
  void visitVariableGet(VariableGet node) {
    _visitVariableUse(node.variable);
    super.visitVariableGet(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    _visitVariableUse(node.variable);
    super.visitVariableSet(node);
  }

  void _visitThis() {
    if (depth > 0 || functionIsSyncStarOrAsync[0]) {
      closures.isThisCaptured = true;
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _visitThis();
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    _visitThis();
    super.visitSuperMethodInvocation(node);
  }

  @override
  void visitSuperPropertyGet(SuperPropertyGet node) {
    _visitThis();
    super.visitSuperPropertyGet(node);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    _visitThis();
    super.visitSuperPropertySet(node);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    if (node.parameter.parent != null &&
        node.parameter.parent == member.enclosingClass) {
      _visitThis();
    } else if (node.parameter.parent is FunctionNode) {
      _visitVariableUse(node.parameter);
    }
    super.visitTypeParameterType(node);
  }

  void _visitLambda(FunctionNode node) {
    List<w.ValueType> inputs = [
      w.RefType.struct(nullable: false),
      ...List.filled(node.typeParameters.length, closures.typeType),
      for (VariableDeclaration param in node.positionalParameters)
        translator.translateType(param.type),
      for (VariableDeclaration param in node.namedParameters)
        translator.translateType(param.type)
    ];
    List<w.ValueType> outputs = [translator.translateType(node.returnType)];
    w.FunctionType type = m.addFunctionType(inputs, outputs);
    w.DefinedFunction function =
        m.addFunction(type, "$member closure at ${node.location}");
    closures.lambdas[node] = Lambda(node, function);

    functionIsSyncStarOrAsync.add(node.asyncMarker == AsyncMarker.SyncStar ||
        node.asyncMarker == AsyncMarker.Async);
    node.visitChildren(this);
    functionIsSyncStarOrAsync.removeLast();
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _visitLambda(node.function);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Variable is in outer scope
    node.variable.accept(this);
    _visitLambda(node.function);
  }
}

class ContextCollector extends RecursiveVisitor {
  final Closures closures;
  Context? currentContext;
  final bool enableAsserts;

  ContextCollector(this.closures, TreeNode? container, this.enableAsserts) {
    if (container != null) {
      currentContext = closures.contexts[container]!;
    }
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (enableAsserts) {
      super.visitAssertStatement(node);
    }
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    if (enableAsserts) {
      super.visitAssertBlock(node);
    }
  }

  void _newContext(TreeNode node) {
    bool outerMost = currentContext == null;
    Context? oldContext = currentContext;
    Context? parent = currentContext;
    while (parent != null && parent.isEmpty) {
      parent = parent.parent;
    }
    currentContext = Context(node, parent);
    if (closures.isThisCaptured && outerMost) {
      currentContext!.containsThis = true;
    }
    closures.contexts[node] = currentContext!;
    node.visitChildren(this);
    currentContext = oldContext;
  }

  @override
  void visitConstructor(Constructor node) {
    node.function.accept(this);
    currentContext = closures.contexts[node.function]!;
    visitList(node.initializers, this);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    _newContext(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _newContext(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _newContext(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _newContext(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    Capture? capture = closures.captures[node];
    if (capture != null) {
      currentContext!.variables.add(node);
      capture.context = currentContext!;
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    Capture? capture = closures.captures[node];
    if (capture != null) {
      currentContext!.typeParameters.add(node);
      capture.context = currentContext!;
    }
    super.visitTypeParameter(node);
  }

  @override
  void visitVariableSet(VariableSet node) {
    closures.captures[node.variable]?.written = true;
    super.visitVariableSet(node);
  }
}
