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
import 'code_generator.dart';
import 'dynamic_module_kernel_metadata.dart'
    show DynamicModuleConstantRepository;
import 'dynamic_modules.dart';
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

  void _readGlobal(Translator translator, w.InstructionsBuilder b) {
    translator.globals.readGlobal(b, global);
  }

  w.ValueType readConstant(Translator translator, w.InstructionsBuilder b) {
    final initFunction = function;
    if (initFunction != null) {
      // Lazily initialized constant.
      w.ValueType type = global.type.type.withNullability(false);
      w.Label done = b.block(const [], [type]);
      _readGlobal(translator, b);
      b.br_on_non_null(done);

      translator.callFunction(initFunction, b);
      b.end();
      return type;
    } else {
      _readGlobal(translator, b);
      return global.type.type;
    }
  }
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
  late final Map<Constant, int>? dynamicMainModuleConstantId = (translator
              .component.metadata[DynamicModuleConstantRepository.repositoryTag]
          as DynamicModuleConstantRepository?)
      ?.mapping[translator.component] ??= {};
  w.DataSegmentBuilder? int32Segment;
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

  // All constant constructs should go in the main module.
  Types get types => translator.types;
  CoreTypes get coreTypes => translator.coreTypes;

  Constant makeWasmI32(int value) {
    return InstanceConstant(translator.wasmI32Class.reference, const [],
        {translator.wasmI32Value.fieldReference: IntConstant(value)});
  }

  // Used as an indicator for interface types that the enclosed class ID must be
  // globalized on instantiation. Resolves to a normal _InterfaceType.
  static final Class _relativeInterfaceTypeIndicator =
      Class(name: '', fileUri: Uri());

  /// Makes a `WasmArray<_Type>` [InstanceConstant].
  InstanceConstant makeTypeArray(Iterable<DartType> types) {
    return makeArrayOf(
        translator.typeType, types.map(_lowerTypeConstant).toList());
  }

  /// Makes a `_NamedParameter` [InstanceConstant].
  InstanceConstant makeNamedParameterConstant(NamedType n) {
    return InstanceConstant(
        translator.namedParameterClass.reference, const [], {
      translator.namedParameterNameField.fieldReference:
          translator.symbols.symbolForNamedParameter(n.name),
      translator.namedParameterTypeField.fieldReference:
          _lowerTypeConstant(n.type),
      translator.namedParameterIsRequiredField.fieldReference:
          BoolConstant(n.isRequired),
    });
  }

  /// Creates a `WasmArray<_NamedParameter>` to be used as field of
  /// `_FunctionType`.
  InstanceConstant makeNamedParametersArray(FunctionType type) => makeArrayOf(
      translator.namedParameterType,
      [for (final n in type.namedParameters) makeNamedParameterConstant(n)]);

  /// Creates a `WasmArray<T>` with the given [Constant]s
  InstanceConstant makeArrayOf(
          InterfaceType elementType, List<Constant> entries,
          {bool mutable = true}) =>
      InstanceConstant(
          mutable
              ? translator.wasmArrayClass.reference
              : translator.immutableWasmArrayClass.reference,
          [
            elementType,
          ],
          {
            mutable
                    ? translator.wasmArrayValueField.fieldReference
                    : translator.immutableWasmArrayValueField.fieldReference:
                ListConstant(elementType, entries),
          });

  /// Ensure that the constant has a Wasm global assigned.
  ///
  /// Sub-constants must have Wasm globals assigned before the global for the
  /// composite constant is assigned, since global initializers can only refer
  /// to earlier globals.
  ConstantInfo? ensureConstant(Constant constant, w.ModuleBuilder module) {
    return ConstantCreator(this, module).ensureConstant(constant);
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
    final wrappedClassId =
        translator.classIdNumbering.classIds[type.classNode]!;
    final (typeClass, classId) = switch (wrappedClassId) {
      RelativeClassId() => (
          _relativeInterfaceTypeIndicator,
          wrappedClassId.relativeValue
        ),
      AbsoluteClassId() => (
          translator.interfaceTypeClass,
          wrappedClassId.value
        ),
    };
    // If the class ID is relative we will detect that when the constant is
    // emitted and adjust it accordingly.
    return _makeTypeConstant(typeClass, type.nullability, {
      translator.interfaceTypeClassIdField.fieldReference: makeWasmI32(classId),
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
        type.named.map((t) => StringConstant(t.name)).toList(),
        mutable: false);
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

  void instantiate(Constant constant) {
    w.ValueType resultType = constant.accept(this);
    if (translator.needsConversion(resultType, expectedType)) {
      if (expectedType == const w.RefType.extern(nullable: true)) {
        assert(resultType.isSubtypeOf(w.RefType.any(nullable: true)));
        b.extern_convert_any();
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
    ConstantInfo info =
        ConstantCreator(constants, b.module).ensureConstant(constant)!;
    return info.readConstant(translator, b);
  }

  @override
  w.ValueType visitUnevaluatedConstant(UnevaluatedConstant constant) {
    if (constant == ParameterInfo.defaultValueSentinel) {
      // Instantiate a sentinel value specific to the parameter type.
      w.ValueType sentinelType = expectedType.withNullability(false);
      assert(sentinelType is w.RefType,
          "Default value sentinel for unboxed parameter");
      translator
          .getDummyValuesCollectorForModule(b.module)
          .instantiateDummyValue(b, sentinelType);
      return sentinelType;
    }
    return super.visitUnevaluatedConstant(constant);
  }

  @override
  w.ValueType visitNullConstant(NullConstant node) {
    if (expectedType == w.RefType.func(nullable: true)) {
      b.ref_null((expectedType as w.RefType).heapType);
      return expectedType;
    }
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
  final w.ModuleBuilder targetModule;

  ConstantCreator(this.constants, w.ModuleBuilder module)
      : targetModule = constants.translator.isDynamicSubmodule
            ? module
            : constants.translator.mainModule;

  Translator get translator => constants.translator;
  Types get types => translator.types;

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

  static String _dynamicModuleConstantExportName(int id) => '#c$id';
  static String _dynamicModuleInitFunctionExportName(int id) => '#cf$id';

  static int _nextGlobalId = 0;
  String _constantName(Constant constant) {
    final id = _nextGlobalId++;
    if (constant is StringConstant) {
      var value = constant.value;
      final newline = value.indexOf('\n');
      if (newline != -1) value = value.substring(0, newline);
      if (value.length > 30) value = '${value.substring(0, 30)}<...>';
      return 'C$id "$value"';
    }
    if (constant is BoolConstant) {
      return 'C$id ${constant.value}';
    }
    if (constant is IntConstant) {
      return 'C$id ${constant.value}';
    }
    if (constant is DoubleConstant) {
      return 'C$id ${constant.value}';
    }
    if (constant is InstanceConstant) {
      final klass = constant.classNode;
      final name = klass.name;
      if (constant.typeArguments.isEmpty) {
        return 'C$id $name';
      }
      final typeArguments = constant.typeArguments.map(_nameType).join(', ');
      if (klass == translator.wasmArrayClass ||
          klass == translator.immutableWasmArrayClass) {
        final entries =
            (constant.fieldValues.values.single as ListConstant).entries;
        return 'C$id $name<$typeArguments>[${entries.length}]';
      }
      return 'C$id $name<$typeArguments>';
    }
    if (constant is TearOffConstant) {
      return 'C$id ${constant.target.name} tear-off';
    }
    return 'C$id $constant';
  }

  String _nameType(DartType type) {
    if (type is InterfaceType) {
      final name = type.classNode.name;
      if (type.typeArguments.isEmpty) return name;
      return '$name<${type.typeArguments.map((t) => _nameType(t)).join(', ')}>';
    }
    return '$type';
  }

  ConstantInfo createConstant(
      Constant constant, w.RefType type, ConstantCodeGenerator generator,
      {bool lazy = false}) {
    assert(!type.nullable);

    // This function is only called once per [Constant]. If we compile a dynamic
    // submodule then the [dynamicModuleConstantIdMap] is pre-populated and
    // we may find an export name. If we compile the main module, then the id
    // will be `null`.
    final dynamicModuleConstantIdMap = constants.dynamicMainModuleConstantId;
    final mainModuleExportId = dynamicModuleConstantIdMap?[constant];
    final isShareableAcrossModules = dynamicModuleConstantIdMap != null &&
        constant.accept(_ConstantDynamicModuleSharedChecker(translator));
    final needsRuntimeCanonicalization = isShareableAcrossModules &&
        translator.isDynamicSubmodule &&
        mainModuleExportId == null;

    if (lazy || needsRuntimeCanonicalization) {
      // Create uninitialized global and function to initialize it.
      final globalType = w.GlobalType(type.withNullability(true));
      w.Global global;
      w.BaseFunction initFunction;

      w.FunctionType ftype =
          translator.typesBuilder.defineFunction(const [], [type]);

      if (mainModuleExportId != null) {
        global = targetModule.globals.import(translator.mainModule.moduleName,
            _dynamicModuleConstantExportName(mainModuleExportId), globalType);
        initFunction = targetModule.functions.import(
            translator.mainModule.moduleName,
            _dynamicModuleInitFunctionExportName(mainModuleExportId),
            ftype);
      } else {
        final name = _constantName(constant);
        final definedGlobal =
            global = targetModule.globals.define(globalType, name);
        definedGlobal.initializer.ref_null(w.HeapType.none);
        definedGlobal.initializer.end();

        final function = initFunction =
            targetModule.functions.define(ftype, '$name (lazy initializer)}');

        if (isShareableAcrossModules) {
          final exportId = dynamicModuleConstantIdMap[constant] =
              dynamicModuleConstantIdMap.length;

          targetModule.exports.export(
              _dynamicModuleConstantExportName(exportId), definedGlobal);
          targetModule.exports
              .export(_dynamicModuleInitFunctionExportName(exportId), function);
        }
        final b2 = function.body;
        generator(b2);
        if (needsRuntimeCanonicalization) {
          final valueLocal = b2.addLocal(type);
          constant.accept(ConstantCanonicalizer(translator, b2, valueLocal));
        }
        w.Local temp = b2.addLocal(type);
        b2.local_tee(temp);
        b2.global_set(global);
        b2.local_get(temp);
        b2.end();
      }

      return ConstantInfo(constant, global, initFunction);
    } else {
      // Create global with the constant in its initializer.
      assert(!constants.currentlyCreating);
      final globalType = w.GlobalType(type, mutable: false);
      w.Global global;
      if (mainModuleExportId != null) {
        global = targetModule.globals.import(translator.mainModule.moduleName,
            _dynamicModuleConstantExportName(mainModuleExportId), globalType);
      } else {
        constants.currentlyCreating = true;
        final definedGlobal = global =
            targetModule.globals.define(globalType, _constantName(constant));
        generator(definedGlobal.initializer);
        definedGlobal.initializer.end();
        constants.currentlyCreating = false;

        if (isShareableAcrossModules) {
          final exportId = dynamicModuleConstantIdMap[constant] =
              dynamicModuleConstantIdMap.length;

          targetModule.exports.export(
              _dynamicModuleConstantExportName(exportId), definedGlobal);
        }
      }

      return ConstantInfo(constant, global, null);
    }
  }

  @override
  ConstantInfo? defaultConstant(Constant constant) => null;

  @override
  ConstantInfo? visitBoolConstant(BoolConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedBoolClass]!;
    return createConstant(constant, info.nonNullableType, (b) {
      b.i32_const((info.classId as AbsoluteClassId).value);
      b.i32_const(constant.value ? 1 : 0);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitIntConstant(IntConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedIntClass]!;
    return createConstant(constant, info.nonNullableType, (b) {
      b.i32_const((info.classId as AbsoluteClassId).value);
      b.i64_const(constant.value);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitDoubleConstant(DoubleConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedDoubleClass]!;
    return createConstant(constant, info.nonNullableType, (b) {
      b.i32_const((info.classId as AbsoluteClassId).value);
      b.f64_const(constant.value);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitStringConstant(StringConstant constant) {
    ClassInfo info = translator.classInfo[translator.jsStringClass]!;
    return createConstant(constant, info.nonNullableType, (b) {
      b.pushObjectHeaderFields(translator, info);
      translator.globals.readGlobal(
          b, translator.getInternalizedStringGlobal(b.module, constant.value));
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitInstanceConstant(InstanceConstant constant) {
    Class cls = constant.classNode;
    bool isRelativeInterfaceType = false;
    if (cls == translator.wasmArrayClass) {
      return _makeWasmArrayLiteral(constant, mutable: true);
    }
    if (cls == translator.immutableWasmArrayClass) {
      return _makeWasmArrayLiteral(constant, mutable: false);
    }
    if (cls == translator.wasmI32Class) {
      return null;
    }

    if (cls == Constants._relativeInterfaceTypeIndicator) {
      cls = translator.interfaceTypeClass;
      constant = InstanceConstant(
          cls.reference, constant.typeArguments, constant.fieldValues);
      isRelativeInterfaceType = true;
    }

    ClassInfo info = translator.classInfo[cls]!;
    translator.functions.recordClassAllocation(info.classId);
    w.RefType type = info.nonNullableType;

    // Collect sub-constants for field values.
    int fieldCount = info.struct.fields.length;
    List<Constant?> subConstants = List.filled(fieldCount, null);
    // Relative class IDs will get adjusted at runtime based on the local
    // class ID base for the enclosing module. This must be done lazily
    // since the global is not const.
    bool lazy = isRelativeInterfaceType;
    constant.fieldValues.forEach((reference, subConstant) {
      final field = reference.asField;
      int index = translator.fieldIndex[field]!;
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

    // If the class ID is relative then it needs to be globalized when
    // initializing the object which is a non-const operation.
    lazy |= info.classId is RelativeClassId;

    return createConstant(constant, type, lazy: lazy, (b) {
      b.pushObjectHeaderFields(translator, info);
      for (int i = FieldIndex.objectFieldBase; i < fieldCount; i++) {
        Constant subConstant = subConstants[i]!;
        constants.instantiateConstant(
            b, subConstant, info.struct.fields[i].type.unpacked);
        if (isRelativeInterfaceType && i == FieldIndex.interfaceTypeClassId) {
          assert(translator.isDynamicSubmodule);
          translator.pushModuleId(b);
          translator.callReference(translator.globalizeClassId.reference, b);
        }
      }
      b.struct_new(info.struct);
    });
  }

  ConstantInfo? _makeWasmArrayLiteral(InstanceConstant constant,
      {required bool mutable}) {
    w.ArrayType arrayType = translator
        .arrayTypeForDartType(constant.typeArguments.single, mutable: mutable);
    w.ValueType elementType = arrayType.elementType.type.unpacked;

    List<Constant> elements =
        (constant.fieldValues.values.single as ListConstant).entries;
    final tooLargeForArrayNewFixed = elements.length > maxArrayNewFixedLength;
    bool lazy = tooLargeForArrayNewFixed;
    for (Constant element in elements) {
      lazy |= ensureConstant(element)?.isLazy ?? false;
    }

    if (tooLargeForArrayNewFixed && !mutable) {
      throw Exception('Cannot allocate immutable wasm array of size '
          '$tooLargeForArrayNewFixed');
    }

    return createConstant(constant, w.RefType.def(arrayType, nullable: false),
        lazy: lazy, (b) {
      if (tooLargeForArrayNewFixed) {
        // We use WasmArray<WasmI32> for some RTT data structures. Those arrays
        // can get rather large and cross the 10k limit.
        //
        // If so, we prefer to initialize the array from data section over
        // emitting a *lot* of code to store individual array elements.
        //
        // This can be a little bit larger than individual array stores, but the
        // data section will compress better, so for app.wasm.gz it'a a win and
        // will cause much faster validation & faster initialization.
        if (arrayType.elementType.type == w.NumType.i32) {
          // Initialize array contents from passive data segment.
          final w.DataSegmentBuilder segment =
              constants.int32Segment ??= targetModule.dataSegments.define();

          final field = translator.wasmI32Value.fieldReference;

          final list = Uint32List(elements.length);
          for (int i = 0; i < list.length; ++i) {
            // The constant is a `const WasmI32 {WasmI32._value: <XXX>}`
            final constant = elements[i] as InstanceConstant;
            assert(constant.classNode == translator.wasmI32Class);
            list[i] = (constant.fieldValues[field] as IntConstant).value;
          }
          final offset = segment.length;
          segment.append(list.buffer.asUint8List());
          b.i32_const(offset);
          b.i32_const(elements.length);
          b.array_new_data(arrayType, segment);
          return;
        }

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
    final instanceConstant =
        InstanceConstant(translator.immutableListClass.reference, [
      constant.typeArgument,
    ], {
      translator.listBaseLengthField.fieldReference:
          IntConstant(constant.entries.length),
      translator.listBaseDataField.fieldReference:
          InstanceConstant(translator.wasmArrayClass.reference, [
        translator.coreTypes.objectNullableRawType
      ], {
        translator.wasmArrayValueField.fieldReference: ListConstant(
            translator.coreTypes.objectNullableRawType, constant.entries)
      }),
    });
    return ensureConstant(instanceConstant);
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
    ClosureImplementation closure =
        translator.getTearOffClosure(member, targetModule);
    w.StructType struct = closure.representation.closureStruct;
    w.RefType type = w.RefType.def(struct, nullable: false);

    // The vtable for the target will be stored on a global in the target's
    // module.
    final isLazy = translator.moduleForReference(constant.targetReference) !=
        translator.mainModule;
    // The dummy struct must be declared before the constant global so that the
    // constant's initializer can reference it.
    final dummyStructGlobal = translator
        .getDummyValuesCollectorForModule(targetModule)
        .dummyStructGlobal;
    return createConstant(constant, type, (b) {
      ClassInfo info = translator.closureInfo;
      translator.functions.recordClassAllocation(info.classId);

      b.pushObjectHeaderFields(translator, info);
      translator.globals.readGlobal(b, dummyStructGlobal); // Dummy context
      translator.globals.readGlobal(b, closure.vtable);
      constants.instantiateConstant(
          b, functionTypeConstant, types.nonNullableTypeType);
      b.struct_new(struct);
    }, lazy: isLazy);
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
        translator.getTearOffClosure(tearOffProcedure, targetModule);
    int positionalCount = tearOffConstant.function.positionalParameters.length;
    List<String> names =
        tearOffConstant.function.namedParameters.map((p) => p.name!).toList();
    ClosureRepresentation instantiationOfTearOffRepresentation = translator
        .closureLayouter
        .getClosureRepresentation(0, positionalCount, names)!;
    ClosureRepresentation tearOffRepresentation = translator.closureLayouter
        .getClosureRepresentation(types.length, positionalCount, names)!;
    w.StructType struct = instantiationOfTearOffRepresentation.closureStruct;
    w.RefType type = w.RefType.def(struct, nullable: false);

    final tearOffConstantInfo = ensureConstant(tearOffConstant)!;

    w.BaseFunction makeDynamicCallEntry() {
      final function = targetModule.functions.define(
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
      translator.callFunction(tearOffClosure.dynamicCallEntry, b);
      b.end();

      return function;
    }

    // Dynamic call entry needs to be created first (before `createConstant`)
    // as it needs to create a constant for the type list, and we cannot create
    // a constant while creating another one.
    final w.BaseFunction dynamicCallEntry = makeDynamicCallEntry();

    final lazy = tearOffConstantInfo.isLazy;

    return createConstant(constant, type, lazy: lazy, (b) {
      ClassInfo info = translator.closureInfo;
      translator.functions.recordClassAllocation(info.classId);

      void declareAndAddRefFunc(w.BaseFunction function) {
        // If the constant is lazy the body will be in a function rather than a
        // global. In order for a function to use a ref.func, the function must
        // be declared in a global (or via the element section).
        if (lazy) {
          final global = b.module.globals
              .define(w.GlobalType(w.RefType(function.type, nullable: false)));
          global.initializer
            ..ref_func(function)
            ..end();
          b.global_get(global);
        } else {
          b.ref_func(function);
        }
      }

      w.BaseFunction makeTrampoline(
          w.FunctionType signature, w.BaseFunction tearOffFunction) {
        assert(tearOffFunction.type.inputs.length ==
            signature.inputs.length + types.length);
        final function = b.module.functions
            .define(signature, "instantiation constant trampoline");
        final b2 = function.body;
        b2.local_get(function.locals[0]);
        for (ConstantInfo typeInfo in types) {
          typeInfo.readConstant(translator, b2);
        }
        for (int i = 1; i < signature.inputs.length; i++) {
          b2.local_get(function.locals[i]);
        }
        translator.callFunction(tearOffFunction, b2);
        b2.end();
        return function;
      }

      void fillVtableEntry(int posArgCount, NameCombination nameCombination) {
        final fieldIndex = instantiationOfTearOffRepresentation
            .fieldIndexForSignature(posArgCount, nameCombination.names);
        final signature =
            instantiationOfTearOffRepresentation.getVtableFieldType(fieldIndex);

        w.BaseFunction function;
        if (nameCombination.names.isNotEmpty &&
            !tearOffRepresentation.nameCombinations.contains(nameCombination)) {
          // This name combination only has
          //   - non-generic closure / non-generic tear-off definitions
          //   - non-generic callers
          // => We make a dummy entry which is unreachable.
          function = translator
              .getDummyValuesCollectorForModule(b.module)
              .getDummyFunction(signature);
        } else {
          final int tearOffFieldIndex = tearOffRepresentation
              .fieldIndexForSignature(posArgCount, nameCombination.names);
          w.BaseFunction tearOffFunction = tearOffClosure.functions[
              tearOffFieldIndex - tearOffRepresentation.vtableBaseIndex];
          if (translator
              .getDummyValuesCollectorForModule(b.module)
              .isDummyFunction(tearOffFunction)) {
            // This name combination may not exist for the target, but got
            // clustered together with other name combinations that do exist.
            // => We make a dummy entry which is unreachable.
            function = translator
                .getDummyValuesCollectorForModule(b.module)
                .getDummyFunction(signature);
          } else {
            function = makeTrampoline(signature, tearOffFunction);
          }
        }
        declareAndAddRefFunc(function);
      }

      void makeVtable() {
        declareAndAddRefFunc(dynamicCallEntry);
        assert(!instantiationOfTearOffRepresentation.isGeneric);

        if (translator.dynamicModuleSupportEnabled) {
          // Dynamic modules only use the dynamic call entry.
          b.struct_new(instantiationOfTearOffRepresentation.vtableStruct);
          return;
        }

        for (int posArgCount = 0;
            posArgCount <= positionalCount;
            posArgCount++) {
          fillVtableEntry(posArgCount, NameCombination(const []));
        }
        for (NameCombination combination
            in instantiationOfTearOffRepresentation.nameCombinations) {
          fillVtableEntry(positionalCount, combination);
        }
        b.struct_new(instantiationOfTearOffRepresentation.vtableStruct);
      }

      b.pushObjectHeaderFields(translator, info);

      // Context is not used by the vtable functions, but it's needed for
      // closure equality checks to work (`_Closure._equals`).
      tearOffConstantInfo.readConstant(translator, b);

      for (final ty in types) {
        ty.readConstant(translator, b);
      }
      b.struct_new(tearOffRepresentation.instantiationContextStruct!);

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
    w.RefType stringType = translator.stringType;
    final nameConstant =
        StringConstant(translator.symbols.getMangledSymbolName(constant));
    bool lazy = ensureConstant(nameConstant)?.isLazy ?? false;
    return createConstant(constant, info.nonNullableType, lazy: lazy, (b) {
      b.pushObjectHeaderFields(translator, info);
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

    bool lazy = false;
    for (Constant argument in arguments) {
      lazy |= ensureConstant(argument)?.isLazy ?? false;
    }

    return createConstant(constant, recordClassInfo.nonNullableType, lazy: lazy,
        (b) {
      b.pushObjectHeaderFields(translator, recordClassInfo);
      for (Constant argument in arguments) {
        constants.instantiateConstant(b, argument, translator.topType);
      }
      b.struct_new(recordClassInfo.struct);
    });
  }
}

/// Resolves to true if the visited Constant is accessible from dynamic
/// submodules.
///
/// Constants that are accessible from dynamic submodules should be:
/// (1) Exported from the main module if they exist there and then imported
/// into dynamic submodules.
/// (2) Runtime canonicalized by dynamic submodules if they are not in the main
/// module.
class _ConstantDynamicModuleSharedChecker extends ConstantVisitor<bool>
    with ConstantVisitorDefaultMixin<bool> {
  final Translator translator;

  _ConstantDynamicModuleSharedChecker(this.translator);

  // TODO(natebiggs): Make this more precise by handling more specific
  // constants.
  @override
  bool defaultConstant(Constant constant) => true;

  @override
  bool visitInstanceConstant(InstanceConstant constant) {
    final cls = constant.classNode;
    if (!cls.enclosingLibrary.isFromMainModule(translator.coreTypes)) {
      return false;
    }
    if (cls == translator.wasmArrayClass ||
        cls == translator.immutableWasmArrayClass) {
      return true;
    }
    return constant.classNode.constructors.any(
        (c) => c.isConst && c.isDynamicSubmoduleCallable(translator.coreTypes));
  }
}
