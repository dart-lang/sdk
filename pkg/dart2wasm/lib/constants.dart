// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/closures.dart';
import 'package:dart2wasm/param_info.dart';
import 'package:dart2wasm/translator.dart';
import 'package:dart2wasm/types.dart';

import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart' show substitute, Substitution;

import 'package:wasm_builder/wasm_builder.dart' as w;

const int maxArrayNewFixedLength = 10000;

class ConstantInfo {
  final Constant constant;
  final w.Global global;
  final w.BaseFunction? function;

  ConstantInfo(this.constant, this.global, this.function);

  bool get isLazy => function != null;
}

typedef ConstantCodeGenerator = void Function(
    w.FunctionBuilder?, w.InstructionsBuilder);

/// Handles the creation of Dart constants.
///
/// Each (non-trivial) constant is assigned to a Wasm global. Multiple
/// occurrences of the same constant use the same global.
///
/// When possible, the constant is contained within the global initializer,
/// meaning the constant is initialized eagerly during module initialization.
/// If this would exceed built-in Wasm limits (in particular the maximum length
/// for `array.new_fixed`), the constant is lazy, meaning that the global starts
/// out uninitialized, and every use of the constant checks the global to see if
/// it has been initialized and calls an initialization function otherwise.
/// A constant is also forced to be lazy if any sub-constants (e.g. elements of
/// a constant list) are lazy.
class Constants {
  final Translator translator;
  final Map<Constant, ConstantInfo> constantInfo = {};
  w.DataSegmentBuilder? oneByteStringSegment;
  w.DataSegmentBuilder? twoByteStringSegment;
  late final w.Global emptyTypeList;
  late final ClassInfo typeInfo = translator.classInfo[translator.typeClass]!;

  bool currentlyCreating = false;

  Constants(this.translator) {
    _initEmptyTypeList();
  }

  w.ModuleBuilder get m => translator.m;

  void _initEmptyTypeList() {
    ClassInfo info = translator.classInfo[translator.immutableListClass]!;
    translator.functions.allocateClass(info.classId);

    // Create the empty type list with its type parameter uninitialized for now.
    w.RefType emptyListType = info.nonNullableType;
    final emptyTypeListBuilder =
        m.globals.define(w.GlobalType(emptyListType, mutable: false));
    w.InstructionsBuilder ib = emptyTypeListBuilder.initializer;
    ib.i32_const(info.classId);
    ib.i32_const(initialIdentityHash);
    ib.ref_null(w.HeapType.none); // Initialized later
    ib.i64_const(0);
    ib.array_new_fixed(translator.listArrayType, 0);
    ib.struct_new(info.struct);
    ib.end(); // end of global initializer expression
    emptyTypeList = emptyTypeListBuilder;

    Constant emptyTypeListConstant = ListConstant(
        InterfaceType(translator.typeClass, Nullability.nonNullable), const []);
    constantInfo[emptyTypeListConstant] =
        ConstantInfo(emptyTypeListConstant, emptyTypeList, null);

    // Initialize the type parameter of the empty type list to the type object
    // for _Type, which itself refers to the empty type list.
    final b = translator.initFunction.body;
    b.global_get(emptyTypeList);
    instantiateConstant(
        translator.initFunction,
        b,
        TypeLiteralConstant(
            InterfaceType(translator.typeClass, Nullability.nonNullable)),
        typeInfo.nullableType);
    b.struct_set(info.struct,
        translator.typeParameterIndex[info.cls!.typeParameters.single]!);
  }

  /// Makes a type list [ListConstant].
  ListConstant makeTypeList(Iterable<DartType> types) => ListConstant(
      InterfaceType(translator.typeClass, Nullability.nonNullable),
      types.map((t) => TypeLiteralConstant(t)).toList());

  /// Makes a `_NamedParameter` [InstanceConstant].
  InstanceConstant makeNamedParameterConstant(NamedType n) {
    Class namedParameter = translator.namedParameterClass;
    assert(namedParameter.fields[0].name.text == 'name' &&
        namedParameter.fields[1].name.text == 'type' &&
        namedParameter.fields[2].name.text == 'isRequired');
    Reference namedParameterName = namedParameter.fields[0].fieldReference;
    Reference namedParameterType = namedParameter.fields[1].fieldReference;
    Reference namedParameterIsRequired =
        namedParameter.fields[2].fieldReference;
    return InstanceConstant(namedParameter.reference, [], {
      namedParameterName: StringConstant(n.name),
      namedParameterType: TypeLiteralConstant(n.type),
      namedParameterIsRequired: BoolConstant(n.isRequired)
    });
  }

  /// Makes a [ListConstant] of `_NamedParameters` to initialize a [FunctionType].
  ListConstant makeNamedParametersList(FunctionType type) => ListConstant(
      translator.types.namedParameterType,
      type.namedParameters.map(makeNamedParameterConstant).toList());

  /// Ensure that the constant has a Wasm global assigned.
  ///
  /// Sub-constants must have Wasm globals assigned before the global for the
  /// composite constant is assigned, since global initializers can only refer
  /// to earlier globals.
  ConstantInfo? ensureConstant(Constant constant) {
    return ConstantCreator(this).ensureConstant(constant);
  }

  /// Emit code to push a constant onto the stack.
  void instantiateConstant(w.BaseFunction? function, w.InstructionsBuilder b,
      Constant constant, w.ValueType expectedType) {
    if (expectedType == translator.voidMarker) return;
    ConstantInstantiator(this, function, b, expectedType).instantiate(constant);
  }
}

class ConstantInstantiator extends ConstantVisitor<w.ValueType> {
  final Constants constants;
  final w.BaseFunction? function;
  final w.InstructionsBuilder b;
  final w.ValueType expectedType;

  ConstantInstantiator(
      this.constants, this.function, this.b, this.expectedType);

  Translator get translator => constants.translator;
  w.ModuleBuilder get m => translator.m;

  void instantiate(Constant constant) {
    w.ValueType resultType = constant.accept(this);
    if (translator.needsConversion(resultType, expectedType)) {
      if (expectedType == const w.RefType.extern(nullable: true)) {
        assert(resultType.isSubtypeOf(w.RefType.any(nullable: true)));
        b.extern_externalize();
      } else {
        // This only happens in invalid but unreachable code produced by the
        // TFA dead-code elimination.
        b.comment("Constant in incompatible context");
        b.unreachable();
      }
    }
  }

  @override
  w.ValueType defaultConstant(Constant constant) {
    ConstantInfo info = ConstantCreator(constants).ensureConstant(constant)!;
    if (info.isLazy) {
      // Lazily initialized constant.
      w.ValueType type = info.global.type.type.withNullability(false);
      w.Label done = b.block(const [], [type]);
      b.global_get(info.global);
      b.br_on_non_null(done);
      b.call(info.function!);
      b.end();
      return type;
    } else {
      // Constant initialized eagerly in a global initializer.
      b.global_get(info.global);
      return info.global.type.type;
    }
  }

  @override
  w.ValueType visitUnevaluatedConstant(UnevaluatedConstant constant) {
    if (constant == ParameterInfo.defaultValueSentinel) {
      // Instantiate a sentinel value specific to the parameter type.
      w.ValueType sentinelType = expectedType.withNullability(false);
      assert(sentinelType is w.RefType,
          "Default value sentinel for unboxed parameter");
      translator.globals.instantiateDummyValue(b, sentinelType);
      return sentinelType;
    }
    return super.visitUnevaluatedConstant(constant);
  }

  @override
  w.ValueType visitNullConstant(NullConstant node) {
    b.ref_null(w.HeapType.none);
    return const w.RefType.none(nullable: true);
  }

  @override
  w.ValueType visitBoolConstant(BoolConstant constant) {
    if (expectedType is w.RefType) return defaultConstant(constant);
    b.i32_const(constant.value ? 1 : 0);
    return w.NumType.i32;
  }

  @override
  w.ValueType visitIntConstant(IntConstant constant) {
    if (expectedType is w.RefType) return defaultConstant(constant);
    b.i64_const(constant.value);
    return w.NumType.i64;
  }

  @override
  w.ValueType visitDoubleConstant(DoubleConstant constant) {
    if (expectedType is w.RefType) return defaultConstant(constant);
    b.f64_const(constant.value);
    return w.NumType.f64;
  }

  @override
  w.ValueType visitInstanceConstant(InstanceConstant constant) {
    if (constant.classNode == translator.wasmI32Class) {
      int value = (constant.fieldValues.values.single as IntConstant).value;
      b.i32_const(value);
      return w.NumType.i32;
    }
    if (constant.classNode == translator.wasmI64Class) {
      int value = (constant.fieldValues.values.single as IntConstant).value;
      b.i64_const(value);
      return w.NumType.i64;
    }
    if (constant.classNode == translator.wasmF32Class) {
      double value =
          (constant.fieldValues.values.single as DoubleConstant).value;
      b.f32_const(value);
      return w.NumType.f32;
    }
    if (constant.classNode == translator.wasmF64Class) {
      double value =
          (constant.fieldValues.values.single as DoubleConstant).value;
      b.f64_const(value);
      return w.NumType.f64;
    }
    return super.visitInstanceConstant(constant);
  }
}

class ConstantCreator extends ConstantVisitor<ConstantInfo?> {
  final Constants constants;

  ConstantCreator(this.constants);

  Translator get translator => constants.translator;
  Types get types => translator.types;
  w.ModuleBuilder get m => constants.m;

  ConstantInfo? ensureConstant(Constant constant) {
    ConstantInfo? info = constants.constantInfo[constant];
    if (info == null) {
      info = constant.accept(this);
      if (info != null) {
        constants.constantInfo[constant] = info;
      }
    }
    return info;
  }

  ConstantInfo createConstant(
      Constant constant, w.RefType type, ConstantCodeGenerator generator,
      {bool lazy = false}) {
    assert(!type.nullable);
    if (lazy) {
      // Create uninitialized global and function to initialize it.
      final global = m.globals.define(w.GlobalType(type.withNullability(true)));
      global.initializer.ref_null(w.HeapType.none);
      global.initializer.end();
      w.FunctionType ftype = m.types.defineFunction(const [], [type]);
      final function = m.functions.define(ftype, "$constant");
      generator(function, function.body);
      w.Local temp = function.addLocal(type);
      final b2 = function.body;
      b2.local_tee(temp);
      b2.global_set(global);
      b2.local_get(temp);
      b2.end();

      return ConstantInfo(constant, global, function);
    } else {
      // Create global with the constant in its initializer.
      assert(!constants.currentlyCreating);
      constants.currentlyCreating = true;
      final global = m.globals.define(w.GlobalType(type, mutable: false));
      generator(null, global.initializer);
      global.initializer.end();
      constants.currentlyCreating = false;

      return ConstantInfo(constant, global, null);
    }
  }

  @override
  ConstantInfo? defaultConstant(Constant constant) => null;

  @override
  ConstantInfo? visitBoolConstant(BoolConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedBoolClass]!;
    return createConstant(constant, info.nonNullableType, (function, b) {
      b.i32_const(info.classId);
      b.i32_const(constant.value ? 1 : 0);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitIntConstant(IntConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedIntClass]!;
    return createConstant(constant, info.nonNullableType, (function, b) {
      b.i32_const(info.classId);
      b.i64_const(constant.value);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitDoubleConstant(DoubleConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedDoubleClass]!;
    return createConstant(constant, info.nonNullableType, (function, b) {
      b.i32_const(info.classId);
      b.f64_const(constant.value);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitStringConstant(StringConstant constant) {
    bool isOneByte = constant.value.codeUnits.every((c) => c <= 255);
    ClassInfo info = translator.classInfo[isOneByte
        ? translator.oneByteStringClass
        : translator.twoByteStringClass]!;
    translator.functions.allocateClass(info.classId);
    w.RefType type = info.nonNullableType;
    bool lazy = constant.value.length > maxArrayNewFixedLength;
    return createConstant(constant, type, lazy: lazy, (function, b) {
      w.ArrayType arrayType =
          (info.struct.fields[FieldIndex.stringArray].type as w.RefType)
              .heapType as w.ArrayType;

      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      if (lazy) {
        // Initialize string contents from passive data segment.
        w.DataSegmentBuilder segment;
        Uint8List bytes;
        if (isOneByte) {
          segment = constants.oneByteStringSegment ??= m.dataSegments.define();
          bytes = Uint8List.fromList(constant.value.codeUnits);
        } else {
          assert(Endian.host == Endian.little);
          segment = constants.twoByteStringSegment ??= m.dataSegments.define();
          bytes = Uint16List.fromList(constant.value.codeUnits)
              .buffer
              .asUint8List();
        }
        int offset = segment.length;
        segment.append(bytes);
        b.i32_const(offset);
        b.i32_const(constant.value.length);
        b.array_new_data(arrayType, segment);
      } else {
        // Initialize string contents from i32 constants on the stack.
        for (int charCode in constant.value.codeUnits) {
          b.i32_const(charCode);
        }
        b.array_new_fixed(arrayType, constant.value.length);
      }
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitInstanceConstant(InstanceConstant constant) {
    Class cls = constant.classNode;
    ClassInfo info = translator.classInfo[cls]!;
    translator.functions.allocateClass(info.classId);
    w.RefType type = info.nonNullableType;

    // Collect sub-constants for field values.
    const int baseFieldCount = 2;
    int fieldCount = info.struct.fields.length;
    List<Constant?> subConstants = List.filled(fieldCount, null);
    bool lazy = false;
    constant.fieldValues.forEach((reference, subConstant) {
      int index = translator.fieldIndex[reference.asField]!;
      assert(subConstants[index] == null);
      subConstants[index] = subConstant;
      lazy |= ensureConstant(subConstant)?.isLazy ?? false;
    });

    // Collect sub-constants for type arguments.
    Map<TypeParameter, DartType> substitution = {};
    List<DartType> args = constant.typeArguments;
    while (true) {
      for (int i = 0; i < cls.typeParameters.length; i++) {
        TypeParameter parameter = cls.typeParameters[i];
        DartType arg = substitute(args[i], substitution);
        substitution[parameter] = arg;
        int index = translator.typeParameterIndex[parameter]!;
        Constant typeArgConstant = TypeLiteralConstant(arg);
        subConstants[index] = typeArgConstant;
        ensureConstant(typeArgConstant);
      }
      Supertype? supertype = cls.supertype;
      if (supertype == null) break;
      cls = supertype.classNode;
      args = supertype.typeArguments;
    }

    return createConstant(constant, type, lazy: lazy, (function, b) {
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      for (int i = baseFieldCount; i < fieldCount; i++) {
        Constant subConstant = subConstants[i]!;
        constants.instantiateConstant(
            function, b, subConstant, info.struct.fields[i].type.unpacked);
      }
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitListConstant(ListConstant constant) {
    Constant typeArgConstant = TypeLiteralConstant(constant.typeArgument);
    ensureConstant(typeArgConstant);
    bool lazy = constant.entries.length > maxArrayNewFixedLength;
    for (Constant subConstant in constant.entries) {
      lazy |= ensureConstant(subConstant)?.isLazy ?? false;
    }

    ClassInfo info = translator.classInfo[translator.immutableListClass]!;
    translator.functions.allocateClass(info.classId);
    w.RefType type = info.nonNullableType;
    return createConstant(constant, type, lazy: lazy, (function, b) {
      w.ArrayType arrayType = translator.listArrayType;
      w.ValueType elementType = arrayType.elementType.type.unpacked;
      int length = constant.entries.length;
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      constants.instantiateConstant(
          function, b, typeArgConstant, constants.typeInfo.nullableType);
      b.i64_const(length);
      if (lazy) {
        // Allocate array and set each entry to the corresponding sub-constant.
        w.Local arrayLocal =
            function!.addLocal(w.RefType.def(arrayType, nullable: false));
        b.i32_const(length);
        b.array_new_default(arrayType);
        b.local_set(arrayLocal);
        for (int i = 0; i < length; i++) {
          b.local_get(arrayLocal);
          b.i32_const(i);
          constants.instantiateConstant(
              function, b, constant.entries[i], elementType);
          b.array_set(arrayType);
        }
        b.local_get(arrayLocal);
      } else {
        // Push all sub-constants on the stack and initialize array from them.
        for (int i = 0; i < length; i++) {
          constants.instantiateConstant(
              function, b, constant.entries[i], elementType);
        }
        b.array_new_fixed(arrayType, length);
      }
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitMapConstant(MapConstant constant) {
    Constant keyTypeConstant = TypeLiteralConstant(constant.keyType);
    ensureConstant(keyTypeConstant);
    Constant valueTypeConstant = TypeLiteralConstant(constant.valueType);
    ensureConstant(valueTypeConstant);
    List<Constant> dataElements =
        List.generate(constant.entries.length * 2, (i) {
      ConstantMapEntry entry = constant.entries[i >> 1];
      return i.isEven ? entry.key : entry.value;
    });
    ListConstant dataList = ListConstant(const DynamicType(), dataElements);
    bool lazy = ensureConstant(dataList)?.isLazy ?? false;

    ClassInfo info = translator.classInfo[translator.immutableMapClass]!;
    translator.functions.allocateClass(info.classId);
    w.RefType type = info.nonNullableType;
    return createConstant(constant, type, lazy: lazy, (function, b) {
      w.RefType indexType =
          info.struct.fields[FieldIndex.hashBaseIndex].type as w.RefType;
      w.RefType dataType =
          info.struct.fields[FieldIndex.hashBaseData].type as w.RefType;

      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.ref_null(indexType.heapType); // _index
      b.i64_const(_computeHashMask(constant.entries.length)); // _hashMask
      constants.instantiateConstant(function, b, dataList, dataType); // _data
      b.i64_const(dataElements.length); // _usedData
      b.i64_const(0); // _deletedKeys
      constants.instantiateConstant(
          function, b, keyTypeConstant, constants.typeInfo.nullableType);
      constants.instantiateConstant(
          function, b, valueTypeConstant, constants.typeInfo.nullableType);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitSetConstant(SetConstant constant) {
    Constant elementTypeConstant = TypeLiteralConstant(constant.typeArgument);
    ensureConstant(elementTypeConstant);
    ListConstant dataList = ListConstant(const DynamicType(), constant.entries);
    bool lazy = ensureConstant(dataList)?.isLazy ?? false;

    ClassInfo info = translator.classInfo[translator.immutableSetClass]!;
    translator.functions.allocateClass(info.classId);
    w.RefType type = info.nonNullableType;
    return createConstant(constant, type, lazy: lazy, (function, b) {
      w.RefType indexType =
          info.struct.fields[FieldIndex.hashBaseIndex].type as w.RefType;
      w.RefType dataType =
          info.struct.fields[FieldIndex.hashBaseData].type as w.RefType;

      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.ref_null(indexType.heapType); // _index
      b.i64_const(_computeHashMask(constant.entries.length)); // _hashMask
      constants.instantiateConstant(function, b, dataList, dataType); // _data
      b.i64_const(constant.entries.length); // _usedData
      b.i64_const(0); // _deletedKeys
      constants.instantiateConstant(
          function, b, elementTypeConstant, constants.typeInfo.nullableType);
      b.struct_new(info.struct);
    });
  }

  int _computeHashMask(int entries) {
    // This computation of the hash mask follows the computations in
    // [_ImmutableLinkedHashMapMixin._createIndex],
    // [_ImmutableLinkedHashSetMixin._createIndex] and
    // [_HashBase._indexSizeToHashMask].
    const int initialIndexSize = 8;
    final int indexSize = max(entries * 2, initialIndexSize);
    final int hashMask = (1 << (31 - (indexSize - 1).bitLength)) - 1;
    return hashMask;
  }

  @override
  ConstantInfo? visitStaticTearOffConstant(StaticTearOffConstant constant) {
    Procedure member = constant.targetReference.asProcedure;
    Constant functionTypeConstant =
        TypeLiteralConstant(translator.getTearOffType(member));
    ensureConstant(functionTypeConstant);
    ClosureImplementation closure = translator.getTearOffClosure(member);
    w.StructType struct = closure.representation.closureStruct;
    w.RefType type = w.RefType.def(struct, nullable: false);
    return createConstant(constant, type, (function, b) {
      ClassInfo info = translator.closureInfo;
      translator.functions.allocateClass(info.classId);

      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.global_get(translator.globals.dummyStructGlobal); // Dummy context
      b.global_get(closure.vtable);
      constants.instantiateConstant(
          function, b, functionTypeConstant, this.types.nonNullableTypeType);
      b.struct_new(struct);
    });
  }

  @override
  ConstantInfo? visitInstantiationConstant(InstantiationConstant constant) {
    TearOffConstant tearOffConstant =
        constant.tearOffConstant as TearOffConstant;
    List<ConstantInfo> types = constant.types
        .map((c) => ensureConstant(TypeLiteralConstant(c))!)
        .toList();
    Procedure tearOffProcedure = tearOffConstant.targetReference.asProcedure;
    FunctionType tearOffFunctionType =
        translator.getTearOffType(tearOffProcedure);
    FunctionType instantiatedFunctionType = Substitution.fromPairs(
                tearOffFunctionType.typeParameters, constant.types)
            .substituteType(tearOffFunctionType.withoutTypeParameters)
        as FunctionType;
    Constant functionTypeConstant =
        TypeLiteralConstant(instantiatedFunctionType);
    ensureConstant(functionTypeConstant);
    ClosureImplementation tearOffClosure =
        translator.getTearOffClosure(tearOffProcedure);
    int positionalCount = tearOffConstant.function.positionalParameters.length;
    List<String> names =
        tearOffConstant.function.namedParameters.map((p) => p.name!).toList();
    ClosureRepresentation representation = translator.closureLayouter
        .getClosureRepresentation(0, positionalCount, names)!;
    ClosureRepresentation instantiationRepresentation = translator
        .closureLayouter
        .getClosureRepresentation(types.length, positionalCount, names)!;
    w.StructType struct = representation.closureStruct;
    w.RefType type = w.RefType.def(struct, nullable: false);

    final tearOffConstantInfo = ensureConstant(tearOffConstant)!;

    w.BaseFunction makeDynamicCallEntry() {
      final function = m.functions.define(
          translator.dynamicCallVtableEntryFunctionType, "dynamic call entry");

      final b = function.body;

      final closureLocal = function.locals[0];
      final typeArgsListLocal = function.locals[1]; // empty
      final posArgsListLocal = function.locals[2];
      final namedArgsListLocal = function.locals[3];

      b.local_get(closureLocal);
      final ListConstant typeArgs = constants.makeTypeList(constant.types);
      constants.instantiateConstant(
          function, b, typeArgs, typeArgsListLocal.type);
      b.local_get(posArgsListLocal);
      b.local_get(namedArgsListLocal);
      b.call(tearOffClosure.dynamicCallEntry);
      b.end();

      return function;
    }

    // Dynamic call entry needs to be created first (before `createConstant`)
    // as it needs to create a constant for the type list, and we cannot create
    // a constant while creating another one.
    final w.BaseFunction dynamicCallEntry = makeDynamicCallEntry();

    return createConstant(constant, type, (function, b) {
      ClassInfo info = translator.closureInfo;
      translator.functions.allocateClass(info.classId);

      w.BaseFunction makeTrampoline(
          w.FunctionType signature, w.BaseFunction tearOffFunction) {
        assert(tearOffFunction.type.inputs.length ==
            signature.inputs.length + types.length);
        final function =
            m.functions.define(signature, "instantiation constant trampoline");
        final b = function.body;
        b.local_get(function.locals[0]);
        for (ConstantInfo typeInfo in types) {
          b.global_get(typeInfo.global);
        }
        for (int i = 1; i < signature.inputs.length; i++) {
          b.local_get(function.locals[i]);
        }
        b.call(tearOffFunction);
        b.end();
        return function;
      }

      void fillVtableEntry(int posArgCount, List<String> argNames) {
        int fieldIndex =
            representation.fieldIndexForSignature(posArgCount, argNames);
        int tearOffFieldIndex = tearOffClosure.representation
            .fieldIndexForSignature(posArgCount, argNames);

        w.FunctionType signature =
            representation.getVtableFieldType(fieldIndex);
        w.BaseFunction tearOffFunction = tearOffClosure.functions[
            tearOffFieldIndex - tearOffClosure.representation.vtableBaseIndex];
        w.BaseFunction function =
            translator.globals.isDummyFunction(tearOffFunction)
                ? translator.globals.getDummyFunction(signature)
                : makeTrampoline(signature, tearOffFunction);
        b.ref_func(function);
      }

      void makeVtable() {
        b.ref_func(dynamicCallEntry);
        if (representation.isGeneric) {
          b.ref_func(representation.instantiationFunction);
        }
        for (int posArgCount = 0;
            posArgCount <= positionalCount;
            posArgCount++) {
          fillVtableEntry(posArgCount, const []);
        }
        for (NameCombination combination in representation.nameCombinations) {
          fillVtableEntry(positionalCount, combination.names);
        }
        b.struct_new(representation.vtableStruct);
      }

      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);

      // Context is not used by the vtable functions, but it's needed for
      // closure equality checks to work (`_Closure._equals`).
      b.global_get(tearOffConstantInfo.global);
      for (final ty in types) {
        b.global_get(ty.global);
      }
      b.struct_new(instantiationRepresentation.instantiationContextStruct!);

      makeVtable();
      constants.instantiateConstant(
          function, b, functionTypeConstant, this.types.nonNullableTypeType);
      b.struct_new(struct);
    });
  }

  ConstantInfo? _makeInterfaceType(
      TypeLiteralConstant constant, InterfaceType type, ClassInfo info) {
    ListConstant typeArgs = constants.makeTypeList(type.typeArguments);
    ensureConstant(typeArgs);
    return createConstant(constant, info.nonNullableType, (function, b) {
      ClassInfo typeInfo = translator.classInfo[type.classNode]!;
      w.ValueType typeListExpectedType = info
          .struct.fields[FieldIndex.interfaceTypeTypeArguments].type.unpacked;

      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.i32_const(types.encodedNullability(type));
      b.i64_const(typeInfo.classId);
      constants.instantiateConstant(
          function, b, typeArgs, typeListExpectedType);
      b.struct_new(info.struct);
    });
  }

  ConstantInfo? _makeFutureOrType(
      TypeLiteralConstant constant, FutureOrType type, ClassInfo info) {
    TypeLiteralConstant typeArgument = TypeLiteralConstant(type.typeArgument);
    ensureConstant(typeArgument);
    return createConstant(constant, info.nonNullableType, (function, b) {
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.i32_const(types.encodedNullability(type));
      constants.instantiateConstant(
          function, b, typeArgument, types.nonNullableTypeType);
      b.struct_new(info.struct);
    });
  }

  ConstantInfo? _makeFunctionType(
      TypeLiteralConstant constant, FunctionType type, ClassInfo info) {
    int typeParameterOffset = types.computeFunctionTypeParameterOffset(type);
    ListConstant typeParameterBoundsConstant =
        constants.makeTypeList(type.typeParameters.map((p) => p.bound));
    ListConstant typeParameterDefaultsConstant =
        constants.makeTypeList(type.typeParameters.map((p) => p.defaultType));
    TypeLiteralConstant returnTypeConstant =
        TypeLiteralConstant(type.returnType);
    ListConstant positionalParametersConstant =
        constants.makeTypeList(type.positionalParameters);
    IntConstant requiredParameterCountConstant =
        IntConstant(type.requiredParameterCount);
    ListConstant namedParametersConstant =
        constants.makeNamedParametersList(type);
    ensureConstant(typeParameterBoundsConstant);
    ensureConstant(typeParameterDefaultsConstant);
    ensureConstant(returnTypeConstant);
    ensureConstant(positionalParametersConstant);
    ensureConstant(requiredParameterCountConstant);
    ensureConstant(namedParametersConstant);
    return createConstant(constant, info.nonNullableType, (function, b) {
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.i32_const(types.encodedNullability(type));
      b.i64_const(typeParameterOffset);
      constants.instantiateConstant(
          function, b, typeParameterBoundsConstant, types.typeListExpectedType);
      constants.instantiateConstant(function, b, typeParameterDefaultsConstant,
          types.typeListExpectedType);
      constants.instantiateConstant(
          function, b, returnTypeConstant, types.nonNullableTypeType);
      constants.instantiateConstant(function, b, positionalParametersConstant,
          types.typeListExpectedType);
      constants.instantiateConstant(
          function, b, requiredParameterCountConstant, w.NumType.i64);
      constants.instantiateConstant(function, b, namedParametersConstant,
          types.namedParametersExpectedType);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitTypeLiteralConstant(TypeLiteralConstant constant) {
    DartType type = types.normalize(constant.type);

    ClassInfo info = translator.classInfo[types.classForType(type)]!;
    translator.functions.allocateClass(info.classId);
    if (type is InterfaceType && !types.isSpecializedClass(type.classNode)) {
      return _makeInterfaceType(constant, type, info);
    } else if (type is FutureOrType) {
      return _makeFutureOrType(constant, type, info);
    } else if (type is FunctionType) {
      return _makeFunctionType(constant, type, info);
    } else if (type is ExtensionType) {
      return ensureConstant(
          TypeLiteralConstant(type.instantiatedRepresentationType));
    } else if (type is TypeParameterType) {
      if (types.isFunctionTypeParameter(type)) {
        // The indexing scheme used by function type parameters ensures that
        // function type parameter types that are identical as constants (have
        // the same nullability and refer to the same type parameter) have the
        // same representation and thus can be canonicalized like other
        // constants.
        return createConstant(constant, info.nonNullableType, (function, b) {
          int index = types.getFunctionTypeParameterIndex(type.parameter);
          b.i32_const(info.classId);
          b.i32_const(initialIdentityHash);
          b.i32_const(types.encodedNullability(type));
          b.i64_const(index);
          b.struct_new(info.struct);
        });
      }
      int environmentIndex =
          types.interfaceTypeEnvironment.lookup(type.parameter);
      return createConstant(constant, info.nonNullableType, (function, b) {
        b.i32_const(info.classId);
        b.i32_const(initialIdentityHash);
        b.i32_const(types.encodedNullability(type));
        b.i64_const(environmentIndex);
        b.struct_new(info.struct);
      });
    } else if (type is RecordType) {
      final names = ListConstant(
          InterfaceType(
              translator.coreTypes.stringClass, Nullability.nonNullable),
          type.named.map((t) => StringConstant(t.name)).toList());
      ensureConstant(names);
      final fieldTypes = constants.makeTypeList(
          type.positional.followedBy(type.named.map((n) => n.type)));
      ensureConstant(fieldTypes);
      return createConstant(constant, info.nonNullableType, (function, b) {
        b.i32_const(info.classId);
        b.i32_const(initialIdentityHash);
        b.i32_const(types.encodedNullability(type));
        final namesExpectedType =
            info.struct.fields[FieldIndex.recordTypeNames].type.unpacked;
        constants.instantiateConstant(function, b, names, namesExpectedType);
        final typeListExpectedType =
            info.struct.fields[FieldIndex.recordTypeFieldTypes].type.unpacked;
        constants.instantiateConstant(
            function, b, fieldTypes, typeListExpectedType);
        b.struct_new(info.struct);
      });
    } else {
      assert(type is VoidType ||
          type is NeverType ||
          type is NullType ||
          type is DynamicType ||
          type is InterfaceType && types.isSpecializedClass(type.classNode));
      return createConstant(constant, info.nonNullableType, (function, b) {
        b.i32_const(info.classId);
        b.i32_const(initialIdentityHash);
        b.i32_const(types.encodedNullability(type));
        b.struct_new(info.struct);
      });
    }
  }

  @override
  ConstantInfo? visitSymbolConstant(SymbolConstant constant) {
    ClassInfo info = translator.classInfo[translator.symbolClass]!;
    translator.functions.allocateClass(info.classId);
    w.RefType stringType =
        translator.classInfo[translator.coreTypes.stringClass]!.nonNullableType;
    StringConstant nameConstant = StringConstant(constant.name);
    bool lazy = ensureConstant(nameConstant)?.isLazy ?? false;
    return createConstant(constant, info.nonNullableType, lazy: lazy,
        (function, b) {
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      constants.instantiateConstant(function, b, nameConstant, stringType);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitRecordConstant(RecordConstant constant) {
    final ClassInfo recordClassInfo =
        translator.getRecordClassInfo(constant.recordType);
    translator.functions.allocateClass(recordClassInfo.classId);

    final List<Constant> arguments = constant.positional.toList();
    arguments.addAll(constant.named.values);

    for (Constant argument in arguments) {
      ensureConstant(argument);
    }

    return createConstant(constant, recordClassInfo.nonNullableType,
        lazy: false, (function, b) {
      b.i32_const(recordClassInfo.classId);
      b.i32_const(initialIdentityHash);
      for (Constant argument in arguments) {
        constants.instantiateConstant(
            function, b, argument, translator.topInfo.nullableType);
      }
      b.struct_new(recordClassInfo.struct);
    });
  }
}
