// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart'
    show FunctionTypeInstantiator, substitute;
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'param_info.dart';
import 'translator.dart';
import 'types.dart';

const int maxArrayNewFixedLength = 10000;

class ConstantInfo {
  final Constant constant;
  final w.Global global;
  final w.BaseFunction? function;

  ConstantInfo(this.constant, this.global, this.function);

  bool get isLazy => function != null;
}

typedef ConstantCodeGenerator = void Function(w.InstructionsBuilder);

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
  late final ClassInfo typeInfo = translator.classInfo[translator.typeClass]!;

  final Map<DartType, InstanceConstant> _loweredTypeConstants = {};
  late final BoolConstant _cachedTrueConstant = BoolConstant(true);
  late final BoolConstant _cachedFalseConstant = BoolConstant(false);
  late final InstanceConstant _cachedDynamicType =
      _makeTopTypeConstant(const DynamicType());
  late final InstanceConstant _cachedVoidType =
      _makeTopTypeConstant(const VoidType());
  late final InstanceConstant _cachedNeverType =
      _makeBottomTypeConstant(const NeverType.nonNullable());
  late final InstanceConstant _cachedNullType =
      _makeBottomTypeConstant(const NullType());
  late final InstanceConstant _cachedNullableObjectType =
      _makeTopTypeConstant(coreTypes.objectRawType(Nullability.nullable));
  late final InstanceConstant _cachedNonNullableObjectType =
      _makeTopTypeConstant(coreTypes.objectRawType(Nullability.nonNullable));
  late final InstanceConstant _cachedNullableFunctionType =
      _makeAbstractFunctionTypeConstant(
          coreTypes.functionRawType(Nullability.nullable));
  late final InstanceConstant _cachedNonNullableFunctionType =
      _makeAbstractFunctionTypeConstant(
          coreTypes.functionRawType(Nullability.nonNullable));
  late final InstanceConstant _cachedNullableRecordType =
      _makeAbstractRecordTypeConstant(
          coreTypes.recordRawType(Nullability.nullable));
  late final InstanceConstant _cachedNonNullableRecordType =
      _makeAbstractRecordTypeConstant(
          coreTypes.recordRawType(Nullability.nonNullable));

  bool currentlyCreating = false;

  Constants(this.translator);

  w.ModuleBuilder get m => translator.m;
  Types get types => translator.types;
  CoreTypes get coreTypes => translator.coreTypes;

  /// Makes a `WasmArray<_Type>` [InstanceConstant].
  InstanceConstant makeTypeArray(Iterable<DartType> types) {
    return makeArrayOf(
        translator.typeType, types.map(_lowerTypeConstant).toList());
  }

  /// Makes a `_NamedParameter` [InstanceConstant].
  InstanceConstant makeNamedParameterConstant(NamedType n) =>
      InstanceConstant(translator.namedParameterClass.reference, const [], {
        translator.namedParameterNameField.fieldReference:
            StringConstant(n.name),
        translator.namedParameterTypeField.fieldReference:
            _lowerTypeConstant(n.type),
        translator.namedParameterIsRequiredField.fieldReference:
            BoolConstant(n.isRequired),
      });

  /// Creates a `WasmArray<_NamedParameter>` to be used as field of
  /// `_FunctionType`.
  InstanceConstant makeNamedParametersArray(FunctionType type) => makeArrayOf(
      translator.namedParameterType,
      [for (final n in type.namedParameters) makeNamedParameterConstant(n)]);

  /// Creates a `WasmArray<T>` with the given [Constant]s
  InstanceConstant makeArrayOf(
          InterfaceType elementType, List<Constant> entries) =>
      InstanceConstant(translator.wasmArrayClass.reference, [
        elementType,
      ], {
        translator.wasmArrayValueField.fieldReference:
            ListConstant(elementType, entries),
      });

  /// Ensure that the constant has a Wasm global assigned.
  ///
  /// Sub-constants must have Wasm globals assigned before the global for the
  /// composite constant is assigned, since global initializers can only refer
  /// to earlier globals.
  ConstantInfo? ensureConstant(Constant constant) {
    return ConstantCreator(this).ensureConstant(constant);
  }

  /// Emit code to push a constant onto the stack.
  void instantiateConstant(
      w.InstructionsBuilder b, Constant constant, w.ValueType expectedType) {
    if (expectedType == translator.voidMarker) return;
    ConstantInstantiator(this, b, expectedType).instantiate(constant);
  }

  InstanceConstant _lowerTypeConstant(DartType type) {
    return _loweredTypeConstants[type] ??= _lowerTypeConstantImpl(type);
  }

  InstanceConstant _lowerTypeConstantImpl(DartType type) {
    return switch (type) {
      DynamicType() => _cachedDynamicType,
      VoidType() => _cachedVoidType,
      NeverType() => _cachedNeverType,
      NullType() => _cachedNullType,
      InterfaceType(classNode: var c) when c == coreTypes.objectClass =>
        type.nullability == Nullability.nullable
            ? _cachedNullableObjectType
            : _cachedNonNullableObjectType,
      InterfaceType(classNode: var c) when c == coreTypes.functionClass =>
        type.nullability == Nullability.nullable
            ? _cachedNullableFunctionType
            : _cachedNonNullableFunctionType,
      InterfaceType(classNode: var c) when c == coreTypes.recordClass =>
        type.nullability == Nullability.nullable
            ? _cachedNullableRecordType
            : _cachedNonNullableRecordType,
      InterfaceType() => _makeInterfaceTypeConstant(type),
      FutureOrType() => _makeFutureOrTypeConstant(type),
      FunctionType() => _makeFunctionTypeConstant(type),
      TypeParameterType() => _makeTypeParameterTypeConstant(type),
      StructuralParameterType() => _makeStructuralParameterTypeConstant(type),
      ExtensionType() => _lowerTypeConstant(type.extensionTypeErasure),
      RecordType() => _makeRecordTypeConstant(type),
      IntersectionType() => throw 'Unexpected DartType: $type',
      TypedefType() => throw 'Unexpected DartType: $type',
      AuxiliaryType() => throw 'Unexpected DartType: $type',
      InvalidType() => throw 'Unexpected DartType: $type',
    };
  }

  InstanceConstant _makeTypeParameterTypeConstant(TypeParameterType type) {
    final int environmentIndex =
        types.interfaceTypeEnvironment.lookup(type.parameter);
    return _makeTypeConstant(
        translator.interfaceTypeParameterTypeClass, type.nullability, {
      translator.interfaceTypeParameterTypeEnvironmentIndexField.fieldReference:
          IntConstant(environmentIndex),
    });
  }

  InstanceConstant _makeStructuralParameterTypeConstant(
      StructuralParameterType type) {
    final int index = types.getFunctionTypeParameterIndex(type.parameter);
    return _makeTypeConstant(
        translator.functionTypeParameterTypeClass, type.nullability, {
      translator.functionTypeParameterTypeIndexField.fieldReference:
          IntConstant(index),
    });
  }

  InstanceConstant _makeInterfaceTypeConstant(InterfaceType type) {
    return _makeTypeConstant(translator.interfaceTypeClass, type.nullability, {
      translator.interfaceTypeClassIdField.fieldReference:
          IntConstant(translator.classIdNumbering.classIds[type.classNode]!),
      translator.interfaceTypeTypeArguments.fieldReference:
          makeTypeArray(type.typeArguments),
    });
  }

  InstanceConstant _makeFutureOrTypeConstant(FutureOrType type) {
    return _makeTypeConstant(translator.futureOrTypeClass, type.nullability, {
      translator.futureOrTypeTypeArgumentField.fieldReference:
          _lowerTypeConstant(type.typeArgument),
    });
  }

  InstanceConstant _makeRecordTypeConstant(RecordType type) {
    final fieldTypes = makeTypeArray([
      ...type.positional,
      ...type.named.map((named) => named.type),
    ]);
    final names = makeArrayOf(coreTypes.stringNonNullableRawType,
        type.named.map((t) => StringConstant(t.name)).toList());
    return _makeTypeConstant(translator.recordTypeClass, type.nullability, {
      translator.recordTypeFieldTypesField.fieldReference: fieldTypes,
      translator.recordTypeNamesField.fieldReference: names,
    });
  }

  InstanceConstant _makeFunctionTypeConstant(FunctionType type) {
    final typeParameterOffset =
        IntConstant(types.computeFunctionTypeParameterOffset(type));
    final typeParameterBoundsConstant =
        makeTypeArray(type.typeParameters.map((p) => p.bound));
    final typeParameterDefaultsConstant =
        makeTypeArray(type.typeParameters.map((p) => p.defaultType));
    final returnTypeConstant = _lowerTypeConstant(type.returnType);
    final positionalParametersConstant =
        makeTypeArray(type.positionalParameters);
    final requiredParameterCountConstant =
        IntConstant(type.requiredParameterCount);
    final namedParametersConstant = makeNamedParametersArray(type);
    return _makeTypeConstant(translator.functionTypeClass, type.nullability, {
      translator.functionTypeTypeParameterOffsetField.fieldReference:
          typeParameterOffset,
      translator.functionTypeTypeParameterBoundsField.fieldReference:
          typeParameterBoundsConstant,
      translator.functionTypeTypeParameterDefaultsField.fieldReference:
          typeParameterDefaultsConstant,
      translator.functionTypeReturnTypeField.fieldReference: returnTypeConstant,
      translator.functionTypePositionalParametersField.fieldReference:
          positionalParametersConstant,
      translator.functionTypeRequiredParameterCountField.fieldReference:
          requiredParameterCountConstant,
      translator.functionTypeTypeParameterNamedParamsField.fieldReference:
          namedParametersConstant,
    });
  }

  InstanceConstant _makeTopTypeConstant(DartType type) {
    assert(type is VoidType ||
        type is DynamicType ||
        type is InterfaceType && type.classNode == coreTypes.objectClass);
    return _makeTypeConstant(translator.topTypeClass, type.nullability, {
      translator.topTypeKindField.fieldReference:
          IntConstant(types.topTypeKind(type)),
    });
  }

  InstanceConstant _makeAbstractFunctionTypeConstant(InterfaceType type) {
    assert(coreTypes.functionClass == type.classNode);
    return _makeTypeConstant(
        translator.abstractFunctionTypeClass, type.nullability, {});
  }

  InstanceConstant _makeAbstractRecordTypeConstant(InterfaceType type) {
    assert(coreTypes.recordClass == type.classNode);
    return _makeTypeConstant(
        translator.abstractRecordTypeClass, type.nullability, {});
  }

  InstanceConstant _makeBottomTypeConstant(DartType type) {
    assert(type is NeverType ||
        type is NullType ||
        type is InterfaceType && types.isSpecializedClass(type.classNode));
    return _makeTypeConstant(translator.bottomTypeClass, type.nullability, {});
  }

  InstanceConstant _makeTypeConstant(Class classNode, Nullability nullability,
      Map<Reference, Constant> fieldValues) {
    fieldValues[translator.typeIsDeclaredNullableField.fieldReference] =
        nullability == Nullability.nullable
            ? _cachedTrueConstant
            : _cachedFalseConstant;
    return InstanceConstant(classNode.reference, const [], fieldValues);
  }
}

class ConstantInstantiator extends ConstantVisitor<w.ValueType>
    with ConstantVisitorDefaultMixin<w.ValueType> {
  final Constants constants;
  final w.InstructionsBuilder b;
  final w.ValueType expectedType;

  ConstantInstantiator(this.constants, this.b, this.expectedType);

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
        b.comment("Constant in incompatible context (constant: $constant, "
            "expectedType: $expectedType, resultType: $resultType)");
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
    if (expectedType == w.NumType.i32) {
      b.i32_const(constant.value);
      return w.NumType.i32;
    }
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

class ConstantCreator extends ConstantVisitor<ConstantInfo?>
    with ConstantVisitorDefaultMixin<ConstantInfo?> {
  final Constants constants;

  ConstantCreator(this.constants);

  Translator get translator => constants.translator;
  Types get types => translator.types;
  w.ModuleBuilder get m => constants.m;

  Constant get _uninitializedHashBaseIndexConstant =>
      (translator.uninitializedHashBaseIndex.initializer as ConstantExpression)
          .constant;

  ConstantInfo? ensureConstant(Constant constant) {
    // To properly canonicalize type literal constants, we normalize the
    // type before canonicalization.
    if (constant is TypeLiteralConstant) {
      DartType type = types.normalize(constant.type);
      constant = constants._lowerTypeConstant(type);
    }

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
      final b2 = function.body;
      generator(b2);
      w.Local temp = b2.addLocal(type);
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
      generator(global.initializer);
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
    return createConstant(constant, info.nonNullableType, (b) {
      b.i32_const(info.classId);
      b.i32_const(constant.value ? 1 : 0);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitIntConstant(IntConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedIntClass]!;
    return createConstant(constant, info.nonNullableType, (b) {
      b.i32_const(info.classId);
      b.i64_const(constant.value);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitDoubleConstant(DoubleConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedDoubleClass]!;
    return createConstant(constant, info.nonNullableType, (b) {
      b.i32_const(info.classId);
      b.f64_const(constant.value);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitStringConstant(StringConstant constant) {
    if (translator.options.jsCompatibility) {
      ClassInfo info = translator.classInfo[translator.jsStringClass]!;
      return createConstant(constant, info.nonNullableType, (b) {
        b.i32_const(info.classId);
        b.i32_const(initialIdentityHash);
        b.global_get(translator.getInternalizedStringGlobal(constant.value));
        b.struct_new(info.struct);
      });
    }
    bool isOneByte = constant.value.codeUnits.every((c) => c <= 255);
    ClassInfo info = translator.classInfo[isOneByte
        ? translator.oneByteStringClass
        : translator.twoByteStringClass]!;
    translator.functions.recordClassAllocation(info.classId);
    w.RefType type = info.nonNullableType;
    bool lazy = constant.value.length > maxArrayNewFixedLength;
    return createConstant(constant, type, lazy: lazy, (b) {
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
    if (cls == translator.wasmArrayClass) {
      return _makeWasmArrayLiteral(constant);
    }

    ClassInfo info = translator.classInfo[cls]!;
    translator.functions.recordClassAllocation(info.classId);
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
        Constant typeArgConstant = constants._lowerTypeConstant(arg);
        subConstants[index] = typeArgConstant;
        ensureConstant(typeArgConstant);
      }
      Supertype? supertype = cls.supertype;
      if (supertype == null) break;
      cls = supertype.classNode;
      args = supertype.typeArguments;
    }

    return createConstant(constant, type, lazy: lazy, (b) {
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      for (int i = baseFieldCount; i < fieldCount; i++) {
        Constant subConstant = subConstants[i]!;
        constants.instantiateConstant(
            b, subConstant, info.struct.fields[i].type.unpacked);
      }
      b.struct_new(info.struct);
    });
  }

  ConstantInfo? _makeWasmArrayLiteral(InstanceConstant constant) {
    w.ArrayType arrayType =
        translator.arrayTypeForDartType(constant.typeArguments.single);
    w.ValueType elementType = arrayType.elementType.type.unpacked;

    List<Constant> elements =
        (constant.fieldValues.values.single as ListConstant).entries;
    final tooLargeForArrayNewFixed = elements.length > maxArrayNewFixedLength;
    bool lazy = tooLargeForArrayNewFixed;
    for (Constant element in elements) {
      lazy |= ensureConstant(element)?.isLazy ?? false;
    }

    return createConstant(constant, w.RefType.def(arrayType, nullable: false),
        lazy: lazy, (b) {
      if (tooLargeForArrayNewFixed) {
        // We will initialize the array with one of the elements (using
        // `array.new`) and update the fields.
        //
        // For the initial element pick the one that occurs the most to save
        // some work when the array has duplicates.
        final Map<Constant, int> occurrences = {};
        for (final element in elements) {
          occurrences.update(element, (i) => i + 1, ifAbsent: () => 1);
        }

        var initialElement = elements[0];
        var initialElementOccurrences = 1;
        for (final entry in occurrences.entries) {
          if (entry.value > initialElementOccurrences) {
            initialElementOccurrences = entry.value;
            initialElement = entry.key;
          }
        }

        w.Local arrayLocal =
            b.addLocal(w.RefType.def(arrayType, nullable: false));
        constants.instantiateConstant(b, initialElement, elementType);
        b.i32_const(elements.length);
        b.array_new(arrayType);
        b.local_set(arrayLocal);

        for (int i = 0; i < elements.length;) {
          // If it's the same as initial element, nothing to do.
          final value = elements[i++];
          if (value == initialElement) continue;

          // Find out how many times the current element repeats.
          final int startInclusive = i - 1;
          while (i < elements.length && elements[i] == value) {
            i++;
          }
          final int endExclusive = i;
          final int count = endExclusive - startInclusive;

          b.local_get(arrayLocal);
          b.i32_const(startInclusive);
          constants.instantiateConstant(b, value, elementType);
          if (count > 1) {
            b.i32_const(count);
            b.array_fill(arrayType);
          } else {
            b.array_set(arrayType);
          }
        }
        b.local_get(arrayLocal);
      } else {
        for (Constant element in elements) {
          constants.instantiateConstant(b, element, elementType);
        }
        b.array_new_fixed(arrayType, elements.length);
      }
    });
  }

  @override
  ConstantInfo? visitListConstant(ListConstant constant) {
    Constant typeArgConstant =
        constants._lowerTypeConstant(constant.typeArgument);
    ensureConstant(typeArgConstant);
    bool lazy = constant.entries.length > maxArrayNewFixedLength;
    for (Constant subConstant in constant.entries) {
      lazy |= ensureConstant(subConstant)?.isLazy ?? false;
    }

    ClassInfo info = translator.classInfo[translator.immutableListClass]!;
    translator.functions.recordClassAllocation(info.classId);
    w.RefType type = info.nonNullableType;
    return createConstant(constant, type, lazy: lazy, (b) {
      w.ArrayType arrayType = translator.listArrayType;
      w.ValueType elementType = arrayType.elementType.type.unpacked;
      int length = constant.entries.length;
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      constants.instantiateConstant(
          b, typeArgConstant, constants.typeInfo.nullableType);
      b.i64_const(length);
      if (lazy) {
        // Allocate array and set each entry to the corresponding sub-constant.
        w.Local arrayLocal =
            b.addLocal(w.RefType.def(arrayType, nullable: false));
        b.i32_const(length);
        b.array_new_default(arrayType);
        b.local_set(arrayLocal);
        for (int i = 0; i < length; i++) {
          b.local_get(arrayLocal);
          b.i32_const(i);
          constants.instantiateConstant(b, constant.entries[i], elementType);
          b.array_set(arrayType);
        }
        b.local_get(arrayLocal);
      } else {
        // Push all sub-constants on the stack and initialize array from them.
        for (int i = 0; i < length; i++) {
          constants.instantiateConstant(b, constant.entries[i], elementType);
        }
        b.array_new_fixed(arrayType, length);
      }
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitMapConstant(MapConstant constant) {
    final listElements = List.generate(constant.entries.length * 2, (i) {
      ConstantMapEntry entry = constant.entries[i >> 1];
      return i.isEven ? entry.key : entry.value;
    });

    final instanceConstant =
        InstanceConstant(translator.immutableMapClass.reference, [
      constant.keyType,
      constant.valueType
    ], {
      // _index = _uninitializedHashBaseIndex
      translator.hashFieldBaseIndexField.fieldReference:
          _uninitializedHashBaseIndexConstant,

      // _hashMask
      translator.hashFieldBaseHashMaskField.fieldReference: IntConstant(0),

      // _data
      translator.hashFieldBaseDataField.fieldReference:
          InstanceConstant(translator.wasmArrayClass.reference, [
        translator.coreTypes.objectNullableRawType
      ], {
        translator.wasmArrayValueField.fieldReference: ListConstant(
            translator.coreTypes.objectNullableRawType, listElements)
      }),

      // _usedData
      translator.hashFieldBaseUsedDataField.fieldReference:
          IntConstant(listElements.length),

      // _deletedKeys
      translator.hashFieldBaseDeletedKeysField.fieldReference: IntConstant(0),
    });

    return ensureConstant(instanceConstant);
  }

  @override
  ConstantInfo? visitSetConstant(SetConstant constant) {
    final instanceConstant =
        InstanceConstant(translator.immutableSetClass.reference, [
      constant.typeArgument
    ], {
      // _index = _uninitializedHashBaseIndex
      translator.hashFieldBaseIndexField.fieldReference:
          _uninitializedHashBaseIndexConstant,

      // _hashMask
      translator.hashFieldBaseHashMaskField.fieldReference: IntConstant(0),

      // _data
      translator.hashFieldBaseDataField.fieldReference:
          InstanceConstant(translator.wasmArrayClass.reference, [
        translator.coreTypes.objectNullableRawType
      ], {
        translator.wasmArrayValueField.fieldReference: ListConstant(
            translator.coreTypes.objectNullableRawType, constant.entries)
      }),

      // _usedData
      translator.hashFieldBaseUsedDataField.fieldReference:
          IntConstant(constant.entries.length),

      // _deletedKeys
      translator.hashFieldBaseDeletedKeysField.fieldReference: IntConstant(0),
    });

    return ensureConstant(instanceConstant);
  }

  @override
  ConstantInfo? visitStaticTearOffConstant(StaticTearOffConstant constant) {
    Procedure member = constant.targetReference.asProcedure;
    Constant functionTypeConstant =
        constants._lowerTypeConstant(translator.getTearOffType(member));
    ensureConstant(functionTypeConstant);
    ClosureImplementation closure = translator.getTearOffClosure(member);
    w.StructType struct = closure.representation.closureStruct;
    w.RefType type = w.RefType.def(struct, nullable: false);
    return createConstant(constant, type, (b) {
      ClassInfo info = translator.closureInfo;
      translator.functions.recordClassAllocation(info.classId);

      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.global_get(translator.globals.dummyStructGlobal); // Dummy context
      b.global_get(closure.vtable);
      constants.instantiateConstant(
          b, functionTypeConstant, types.nonNullableTypeType);
      b.struct_new(struct);
    });
  }

  @override
  ConstantInfo? visitInstantiationConstant(InstantiationConstant constant) {
    TearOffConstant tearOffConstant =
        constant.tearOffConstant as TearOffConstant;
    List<ConstantInfo> types = constant.types
        .map((c) => ensureConstant(constants._lowerTypeConstant(c))!)
        .toList();
    Procedure tearOffProcedure = tearOffConstant.targetReference.asProcedure;
    FunctionType tearOffFunctionType =
        translator.getTearOffType(tearOffProcedure);
    FunctionType instantiatedFunctionType =
        FunctionTypeInstantiator.instantiate(
            tearOffFunctionType, constant.types);
    Constant functionTypeConstant =
        constants._lowerTypeConstant(instantiatedFunctionType);
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
      final InstanceConstant typeArgs = constants.makeTypeArray(constant.types);
      constants.instantiateConstant(b, typeArgs, typeArgsListLocal.type);
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

    return createConstant(constant, type, (b) {
      ClassInfo info = translator.closureInfo;
      translator.functions.recordClassAllocation(info.classId);

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
          b, functionTypeConstant, this.types.nonNullableTypeType);
      b.struct_new(struct);
    });
  }

  @override
  ConstantInfo? visitTypeLiteralConstant(TypeLiteralConstant constant) {
    throw 'Unreachable - should have been lowered';
  }

  @override
  ConstantInfo? visitSymbolConstant(SymbolConstant constant) {
    ClassInfo info = translator.classInfo[translator.symbolClass]!;
    translator.functions.recordClassAllocation(info.classId);
    w.RefType stringType = translator
        .classInfo[translator.coreTypes.stringClass]!.repr.nonNullableType;
    StringConstant nameConstant = StringConstant(constant.name);
    bool lazy = ensureConstant(nameConstant)?.isLazy ?? false;
    return createConstant(constant, info.nonNullableType, lazy: lazy, (b) {
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      constants.instantiateConstant(b, nameConstant, stringType);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitRecordConstant(RecordConstant constant) {
    final ClassInfo recordClassInfo =
        translator.getRecordClassInfo(constant.recordType);
    translator.functions.recordClassAllocation(recordClassInfo.classId);

    final List<Constant> arguments = constant.positional.toList();
    arguments.addAll(constant.named.values);

    for (Constant argument in arguments) {
      ensureConstant(argument);
    }

    return createConstant(constant, recordClassInfo.nonNullableType,
        lazy: false, (b) {
      b.i32_const(recordClassInfo.classId);
      b.i32_const(initialIdentityHash);
      for (Constant argument in arguments) {
        constants.instantiateConstant(
            b, argument, translator.topInfo.nullableType);
      }
      b.struct_new(recordClassInfo.struct);
    });
  }
}
