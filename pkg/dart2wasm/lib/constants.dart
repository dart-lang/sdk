// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/type_algebra.dart'
    show FunctionTypeInstantiator, substitute;
import 'package:kernel/type_environment.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart';
import 'dynamic_modules.dart';
import 'param_info.dart';
import 'translator.dart';
import 'types.dart';

const int maxArrayNewFixedLength = 10000;

/// For testing we can force all constant uses to be resolved later on (instead
/// of resolving some of them during codegen phase when we know to place them to
/// the main module).
const bool forceDelayedConstantDefinition = false;

/// Describes where the constant slot is defined and how to access it.
sealed class ConstantDefinition {
  bool get isLazy;
  w.BaseFunction initializer(w.ModuleBuilder usingModule);
}

/// The value for the constant is stored in a global slot.
///
/// We use this mechanism if the constant is accessed only within a given
/// module.
final class GlobalBasedConstantDefinition extends ConstantDefinition {
  final w.Global global;
  final w.BaseFunction? _initFunction;

  GlobalBasedConstantDefinition(this.global, this._initFunction);

  @override
  bool get isLazy => _initFunction != null;

  @override
  w.BaseFunction initializer(w.ModuleBuilder usingModule) => _initFunction!;
}

/// The value for the (lazy) constant is stored in a table slot.
///
/// We use this mechanism if the constant is accessed across modules and each
/// module will bring it's own copy of the initializer function.
final class TableBasedConstantDefinition extends ConstantDefinition {
  final w.Table table;
  final int tableIndex;
  final Map<w.ModuleBuilder, w.BaseFunction> _initFunctionPerUsingModule;

  TableBasedConstantDefinition(
      this.table, this.tableIndex, this._initFunctionPerUsingModule);

  @override
  bool get isLazy => true;

  @override
  w.BaseFunction initializer(w.ModuleBuilder usingModule) {
    return _initFunctionPerUsingModule[usingModule]!;
  }
}

class ConstantInfo {
  static const int canBeEagerBit = 1 << 0;
  static const int needsRuntimeCanonicalizationBit = 1 << 1;
  static const int exportByMainAppBit = 1 << 2;

  final Constant constant;
  final List<ConstantInfo> children;
  final ConstantCodeGeneratorLazy _forceLazy;
  final int _bits;
  final w.RefType type;
  final ConstantCodeGenerator _codeGen;
  ConstantDefinition? _definition;

  ConstantInfo(
      this.constant,
      this.children,
      this._forceLazy,
      bool canBeEager,
      bool needsRuntimeCanonicalization,
      bool exportByMainApp,
      this.type,
      this._codeGen)
      : _bits = (canBeEager ? canBeEagerBit : 0) |
            (needsRuntimeCanonicalization
                ? needsRuntimeCanonicalizationBit
                : 0) |
            (exportByMainApp ? exportByMainAppBit : 0);

  /// Whether the [constant] can be made eager (i.e. non lazy).
  ///
  /// If `true` then it will depend on into which modules the constant and it's
  /// transitive closure are placed in. If they are all e.g. placed in the main
  /// module then the constant will be non-lazy. If they are placed across
  /// modules the constant may still become lazy.
  bool get canBeEager => (_bits & canBeEagerBit) != 0;

  /// Whether this constant needs runtime canonicalization. If it does, the
  /// constant definition will be lazy.
  bool get needsRuntimeCanonicalization =>
      (_bits & needsRuntimeCanonicalizationBit) != 0;

  /// Whether the main app was compiled with dynamic module support and exposes
  /// this constant via an export.
  bool get exportByMainApp => (_bits & exportByMainAppBit) != 0;

  void printInitializer(void Function(w.BaseFunction) printFunction,
      void Function(w.Global) printLazyInitializer) {
    final definition = _definition;
    if (definition != null) {
      switch (definition) {
        case GlobalBasedConstantDefinition():
          final initFunction = definition._initFunction;
          if (initFunction != null) {
            printFunction(initFunction);
          } else {
            printLazyInitializer(definition.global);
          }
          break;
        case TableBasedConstantDefinition():
          for (final initFunction
              in definition._initFunctionPerUsingModule.values) {
            printFunction(initFunction);
          }
          break;
      }
    }
  }

  void setDefinition(ConstantDefinition definition) {
    assert(_definition == null);
    _definition = definition;
  }
}

typedef ConstantCodeGenerator = void Function(
    ConstantInfo, w.InstructionsBuilder, bool isLazy);
typedef ConstantCodeGeneratorLazy = bool Function(
    ConstantInfo, w.ModuleBuilder);

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
  w.DataSegmentBuilder? byteSegment;
  late final ClassInfo typeInfo = translator.classInfo[translator.typeClass]!;

  late final _constantAccessor = _ConstantAccessor(translator);

  final Map<w.HeapType, DummyValueConstant> _dummyValueConstants = {};
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
        translator.typeType, types.map(_lowerTypeToConstant).toList());
  }

  /// Makes a `_NamedParameter` [InstanceConstant].
  InstanceConstant makeNamedParameterConstant(NamedType n) {
    return InstanceConstant(
        translator.namedParameterClass.reference, const [], {
      translator.namedParameterNameField.fieldReference:
          translator.symbols.symbolForNamedParameter(n.name),
      translator.namedParameterTypeField.fieldReference:
          _lowerTypeToConstant(n.type),
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

  Constant get dummyStructConstant =>
      _getDummyValueConstant(w.HeapType.struct, name: '#DummyStruct');

  Constant _getDummyValueConstant(w.HeapType heapType, {String? name}) {
    if (heapType == w.HeapType.eq || heapType == w.HeapType.any) {
      heapType = w.HeapType.struct;
    }
    return _dummyValueConstants[heapType] ??=
        DummyValueConstant(heapType, name ?? '$heapType');
  }

  void instantiateDummyValueConstant(
      w.InstructionsBuilder b, w.ValueType type) {
    instantiateDummyValue(
        b,
        type,
        (ib, heapType) =>
            instantiateConstant(b, _getDummyValueConstant(heapType), type));
  }

  /// Ensure that the constant has a Wasm global assigned.
  ///
  /// Sub-constants must have Wasm globals assigned before the global for the
  /// composite constant is assigned, since global initializers can only refer
  /// to earlier globals.
  ConstantInfo? ensureConstant(Constant constant) {
    return ConstantCreator(this).ensureConstant(constant);
  }

  /// Whether the constant can be accessed eagerly (i.e. is non lazy) in a
  /// global initializer.
  ///
  /// If the constant can be eager then it'll be immediatly placed in the main
  /// module and return we return `true`. Otherwise we return `false`.
  bool tryInstantiateEagerlyFrom(w.ModuleBuilder usingModule, Constant constant,
      w.ValueType expectedType) {
    if (_constantAccessor.constantIsAlwaysEager(constant)) {
      return true;
    }

    final info = ensureConstant(constant);
    if (info == null) return false;

    final baseModule = translator.isDynamicSubmodule
        ? translator.dynamicSubmodule
        : translator.mainModule;

    var definition = info._definition;
    if (definition == null && info.canBeEager && usingModule == baseModule) {
      // It can be eager and we want to use it from the base module, so let's
      // define it there.
      //
      // If the usage is in a deferred module then we could guarantee it to be
      // eager by placing in the base module as well, but it would make it
      // bigger, so we don't do it.
      definition =
          _constantAccessor._defineConstantInModuleRecursive(baseModule, info);
    }

    if (definition is GlobalBasedConstantDefinition && !definition.isLazy) {
      final definingModule = definition.global.enclosingModule;
      if (definingModule == usingModule.module) return true;
      if (definingModule == baseModule.module) return true;
      if (definingModule == translator.mainModule.module) return true;
    }

    return false;
  }

  /// Defines the constants from main application in the fake main application
  /// module.
  ///
  /// NOTE: We do not recurse into the DAG of the given [constant]:
  ///
  ///   * a sub-constant (directly or indirectly) referred to by [constant] may
  ///     also be exported, in which case the caller will call
  ///     [defineMainAppConstant] for it.
  ///
  ///   * if the dynamic module creates a constant that is structurally equal to
  ///     a non-exported constant from the main app, then it's going to be
  ///     runtime canonicalized.
  ///
  void defineMainAppConstant(
      Constant constant, String globalName, String? initializerName) {
    assert(translator.isDynamicSubmodule);
    final type = constant.accept(TypeOfConstantVisitor(translator));
    final children = const <ConstantInfo>[];
    final guaranteedNonLazy = initializerName == null;
    final needsRuntimeCanonicalization = false;
    final exportByMainApp = true;
    final info = ConstantInfo(
        constant,
        children,
        (_, __) {
          throw StateError(
              'Should not try to generate code for imported constant');
        },
        guaranteedNonLazy,
        needsRuntimeCanonicalization,
        exportByMainApp,
        type,
        (_, __, ___) {
          throw StateError(
              'Should not try to generate code for imported constant');
        });
    constantInfo[constant] = info;
    _constantAccessor.defineMainAppDefinition(
        info, globalName, initializerName);
  }

  /// Emit code to push a constant onto the stack.
  void instantiateConstant(
      w.InstructionsBuilder b, Constant constant, w.ValueType expectedType,
      {w.ModuleBuilder? deferredModuleGuard}) {
    if (expectedType == translator.voidMarker) return;
    ConstantInstantiator(this, b, expectedType, deferredModuleGuard)
        .instantiate(constant);
  }

  InstanceConstant _lowerTypeToConstant(DartType type) {
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
      ExtensionType() => _lowerTypeToConstant(type.extensionTypeErasure),
      RecordType() => _makeRecordTypeConstant(type),
      IntersectionType() => throw 'Unexpected DartType: $type',
      TypedefType() => throw 'Unexpected DartType: $type',
      AuxiliaryType() => throw 'Unexpected DartType: $type',
      InvalidType() => throw 'Unexpected DartType: $type',
      // ignore: unreachable_switch_case
      ExperimentalType() => throw 'Unexpected DartType: $type',
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
          _lowerTypeToConstant(type.typeArgument),
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
    final returnTypeConstant = _lowerTypeToConstant(type.returnType);
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
  final w.ModuleBuilder? deferredModuleGuard;

  ConstantInstantiator(
      this.constants, this.b, this.expectedType, this.deferredModuleGuard);

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
    return constants._constantAccessor
        .loadConstant(b, constant, deferredModuleGuard);
  }

  @override
  w.ValueType visitUnevaluatedConstant(UnevaluatedConstant constant) {
    if (constant == ParameterInfo.defaultValueSentinel) {
      constants.instantiateDummyValueConstant(b, expectedType);
      return expectedType;
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

  ConstantCreator(this.constants);

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
      constant = constants._lowerTypeToConstant(type);
    }

    ConstantInfo? info = constants.constantInfo[constant];
    if (info == null) {
      info = constant.accept(this);
      if (info != null) {
        assert(info.constant.accept(TypeOfConstantVisitor(translator)) ==
            info.type);
        constants.constantInfo[constant] = info;
      }
    }
    return info;
  }

  ConstantInfo createConstant(
      Constant constant,
      List<ConstantInfo> childConstants,
      w.RefType type,
      ConstantCodeGenerator generator,
      {required bool canBeEager,
      ConstantCodeGeneratorLazy? forceLazyConstant}) {
    assert(!type.nullable);

    bool exportByMainApp = false;
    // Dummy values always use runtime canonicalization.
    bool needsRuntimeCanonicalization = constant is DummyValueConstant;
    if (translator.dynamicModuleSupportEnabled) {
      if (!translator.isDynamicSubmodule) {
        // This is main app compilation which allows loading dynamic modules at
        // runtime. We may have to export the constant.
        exportByMainApp =
            constant.accept(_ConstantDynamicModuleSharedChecker(translator)) &&
                constant is! DummyValueConstant;
      } else {
        // This is a dynamic module compilation.
        //
        // If the constant isn't module specific, we need to canonicalize it at
        // runtime.
        assert(!(translator.dynamicModuleConstants?.constantNames
                .containsKey(constant) ??
            false));
        needsRuntimeCanonicalization |=
            constant.accept(_ConstantDynamicModuleSharedChecker(translator));
      }
    }
    canBeEager = canBeEager &&
        !needsRuntimeCanonicalization &&
        childConstants.every((c) => c.canBeEager);

    return ConstantInfo(
        constant,
        childConstants,
        forceLazyConstant ?? (_, __) => false,
        canBeEager,
        needsRuntimeCanonicalization,
        exportByMainApp,
        type,
        generator);
  }

  @override
  ConstantInfo? defaultConstant(Constant constant) => null;

  @override
  ConstantInfo? visitBoolConstant(BoolConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedBoolClass]!;
    return createConstant(constant, const [], info.nonNullableType,
        canBeEager: true, (_, b, __) {
      b.i32_const((info.classId as AbsoluteClassId).value);
      b.i32_const(constant.value ? 1 : 0);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitIntConstant(IntConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedIntClass]!;
    return createConstant(constant, const [], info.nonNullableType,
        canBeEager: true, (_, b, __) {
      b.i32_const((info.classId as AbsoluteClassId).value);
      b.i64_const(constant.value);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitDoubleConstant(DoubleConstant constant) {
    ClassInfo info = translator.classInfo[translator.boxedDoubleClass]!;
    return createConstant(constant, const [], info.nonNullableType,
        canBeEager: true, (_, b, __) {
      b.i32_const((info.classId as AbsoluteClassId).value);
      b.f64_const(constant.value);
      b.struct_new(info.struct);
    });
  }

  @override
  ConstantInfo? visitStringConstant(StringConstant constant) {
    ClassInfo info = translator.classInfo[translator.jsStringClass]!;
    return createConstant(constant, const [], info.nonNullableType,
        canBeEager: true, (_, b, __) {
      b.pushObjectHeaderFields(translator, info);
      translator.globals.readGlobal(
          b,
          translator.getInternalizedStringGlobal(
              b.moduleBuilder, constant.value));
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
    final childConstants = <ConstantInfo>[];
    constant.fieldValues.forEach((reference, subConstant) {
      final field = reference.asField;
      int index = translator.fieldIndex[field]!;
      assert(subConstants[index] == null);
      subConstants[index] = subConstant;
      final info = ensureConstant(subConstant);
      if (info != null) {
        childConstants.add(info);
      }
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
        Constant typeArgConstant = constants._lowerTypeToConstant(arg);
        subConstants[index] = typeArgConstant;
        final info = ensureConstant(typeArgConstant);
        if (info != null) {
          childConstants.add(info);
        }
      }
      Supertype? supertype = cls.supertype;
      if (supertype == null) break;
      cls = supertype.classNode;
      args = supertype.typeArguments;
    }

    // If the class ID is relative then it needs to be globalized when
    // initializing the object which is a non-const operation.
    lazy |= info.classId is RelativeClassId;

    return createConstant(constant, childConstants, type, canBeEager: !lazy,
        (_, b, __) {
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
    final childConstants = <ConstantInfo>[];
    for (Constant element in elements) {
      final info = ensureConstant(element);
      if (info != null) {
        childConstants.add(info);
      }
    }

    if (tooLargeForArrayNewFixed && !mutable) {
      throw Exception('Cannot allocate immutable wasm array of size '
          '$tooLargeForArrayNewFixed');
    }

    return createConstant(
        constant, childConstants, w.RefType.def(arrayType, nullable: false),
        canBeEager: !tooLargeForArrayNewFixed, (_, b, __) {
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
        final fieldType = arrayType.elementType.type;
        final isI32 = fieldType == w.NumType.i32;
        final isI16 = fieldType == w.PackedType.i16;
        if (isI32 || isI16) {
          // Initialize array contents from passive data segment.
          final w.DataSegmentBuilder segment =
              constants.byteSegment ??= b.moduleBuilder.dataSegments.define();
          final field = translator.wasmI32Value.fieldReference;

          Uint8List bytes;
          if (isI16) {
            final list = Uint16List(elements.length);
            for (int i = 0; i < list.length; ++i) {
              // The constant is a `const WasmI32 {WasmI32._value: <XXX>}`
              final constant = elements[i] as InstanceConstant;
              assert(constant.classNode == translator.wasmI32Class);
              list[i] = (constant.fieldValues[field] as IntConstant).value;
            }
            bytes = list.buffer.asUint8List();
          } else {
            assert(isI32);
            final list = Uint32List(elements.length);
            for (int i = 0; i < list.length; ++i) {
              // The constant is a `const WasmI32 {WasmI32._value: <XXX>}`
              final constant = elements[i] as InstanceConstant;
              assert(constant.classNode == translator.wasmI32Class);
              list[i] = (constant.fieldValues[field] as IntConstant).value;
            }
            bytes = list.buffer.asUint8List();
          }
          b.i32_const(segment.length);
          b.i32_const(elements.length);
          b.array_new_data(arrayType, segment);
          segment.append(bytes);
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

    final functionTypeConstant =
        constants._lowerTypeToConstant(translator.getTearOffType(member));
    final functionTypeInfo = ensureConstant(functionTypeConstant)!;
    final childConstants = [functionTypeInfo];

    // Ensure we enqueue the closure body function for compilation.
    //
    // Once we define the constant in a certain module we may be in link phase
    // and have passed the codegen phase and we cannot codegen arbitrary
    // functions in link phase anymore.
    final owningModule = translator.isDynamicSubmodule
        ? translator.dynamicSubmodule
        : translator.moduleForReference(constant.targetReference);
    final closure = translator.getTearOffClosure(member, owningModule);
    final closureClassInfo = translator.closureInfo;
    translator.functions.recordClassAllocation(closureClassInfo.classId);

    // We have a constraint here: The code for the torn off method is in a
    // specific module. The vtable for that closure can (currently) not be setup
    // lazily. That means the tear-off constant can only be an eager constant
    // if we have a guarantee that it will be placed in the same module that can
    // either import the vtable or it's the same module as vtable.
    //
    // Now it's possible that a constant composed of this one is used by
    // different modules. Our constant placement algorithm will then put that
    // one into a shared module (currently the main module) - which will make it
    // lazy as the vtable resides in a module that hasn't been loaded yet at
    // main module instantiation time.
    //
    // So currently we only can guarantee it to be eager if the module owning
    // the vtable is the main module - or we compile a dynamic module.
    final canBeEager =
        owningModule == translator.mainModule || translator.isDynamicSubmodule;

    final closureType =
        w.RefType.def(closure.representation.closureStruct, nullable: false);

    return createConstant(constant, childConstants, closureType,
        canBeEager: canBeEager, forceLazyConstant: (cinfo, m) {
      final constantModule = m.module;
      final vtableModule = closure.vtable.enclosingModule;
      return constantModule != vtableModule &&
          vtableModule != translator.mainModule.module;
    }, (cinfo, b, __) {
      b.pushObjectHeaderFields(translator, closureClassInfo);
      translator
          .getDummyValuesCollectorForModule(b.moduleBuilder)
          .instantiateLocalDummyValue(
              b, const w.RefType.struct(nullable: false));
      translator.globals.readGlobal(b, closure.vtable);
      constants.instantiateConstant(
          b, functionTypeInfo.constant, types.nonNullableTypeType);
      b.struct_new(closure.representation.closureStruct);
    });
  }

  @override
  ConstantInfo? visitInstantiationConstant(InstantiationConstant constant) {
    final tearOffConstant = constant.tearOffConstant as TearOffConstant;
    final tearOffProcedure = tearOffConstant.target as Procedure;
    final tearOffFunctionType = translator.getTearOffType(tearOffProcedure);

    final functionTypeInfo = ensureConstant(constants._lowerTypeToConstant(
        FunctionTypeInstantiator.instantiate(
            tearOffFunctionType, constant.types)))!;
    final tearOffConstantInfo = ensureConstant(tearOffConstant)!;
    final typeConstantInfos = <ConstantInfo>[];
    for (final type in constant.types) {
      typeConstantInfos
          .add(ensureConstant(constants._lowerTypeToConstant(type))!);
    }
    final typeArgsArrayConstantInfo =
        ensureConstant(constants.makeTypeArray(constant.types))!;

    // Ensure we enqueue the closure body function for compilation.
    //
    // Once we define the constant in a certain module we may be in link phase
    // and have passed the codegen phase and we cannot codegen arbitrary
    // functions in link phase anymore.
    final owningModule = translator.isDynamicSubmodule
        ? translator.dynamicSubmodule
        : translator.moduleForReference(tearOffProcedure.reference);
    final tearOffClosure =
        translator.getTearOffClosure(tearOffProcedure, owningModule);
    final closureClassInfo = translator.closureInfo;
    translator.functions.recordClassAllocation(closureClassInfo.classId);

    final childConstants = [
      functionTypeInfo,
      tearOffConstantInfo,
      typeArgsArrayConstantInfo,
      ...typeConstantInfos
    ];

    final function = tearOffConstant.function;
    final positionalCount = function.positionalParameters.length;
    final names = function.namedParameters.map((p) => p.name!).toList();
    final instantiationOfTearOffRepresentation = translator.closureLayouter
        .getClosureRepresentation(0, positionalCount, names)!;
    final tearOffRepresentation = tearOffClosure.representation;
    final closureStruct = instantiationOfTearOffRepresentation.closureStruct;
    final closureType = w.RefType.def(closureStruct, nullable: false);

    return createConstant(constant, childConstants, closureType,
        canBeEager: true, (info, b, isLazy) {
      final targetModule = b.moduleBuilder;

      w.BaseFunction makeDynamicCallEntry() {
        final function = targetModule.functions.define(
            translator.dynamicCallVtableEntryFunctionType,
            "dynamic call entry");

        final b = function.body;

        final typeArgsListLocal = function.locals[1]; // empty
        final posArgsListLocal = function.locals[2];
        final namedArgsListLocal = function.locals[3];

        constants.instantiateConstant(
            b, tearOffConstantInfo.constant, translator.topTypeNonNullable);
        constants.instantiateConstant(
            b, typeArgsArrayConstantInfo.constant, typeArgsListLocal.type);
        b.local_get(posArgsListLocal);
        b.local_get(namedArgsListLocal);
        translator.callFunction(tearOffClosure.dynamicCallEntry!, b);
        b.end();

        return function;
      }

      void declareAndAddRefFunc(w.BaseFunction function) {
        // If the constant is lazy the body will be in a function rather than a
        // global. In order for a function to use a ref.func, the function must
        // be declared in a global (or via the element section).
        if (isLazy) {
          final global = b.moduleBuilder.globals
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
            signature.inputs.length + typeConstantInfos.length);
        final function = b.moduleBuilder.functions
            .define(signature, "instantiation constant trampoline");
        final b2 = function.body;
        b2.local_get(function.locals[0]);
        for (final type in typeConstantInfos) {
          constants.instantiateConstant(
              b2, type.constant, translator.topTypeNonNullable);
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
        final signature = instantiationOfTearOffRepresentation.vtableStruct
            .getVtableEntryAt(fieldIndex);

        w.BaseFunction function;
        if (nameCombination.names.isNotEmpty &&
            !tearOffRepresentation.nameCombinations.contains(nameCombination)) {
          // This name combination only has
          //   - non-generic closure / non-generic tear-off definitions
          //   - non-generic callers
          // => We make a dummy entry which is unreachable.
          function = translator
              .getDummyValuesCollectorForModule(b.moduleBuilder)
              .getDummyFunction(signature);
        } else {
          final int tearOffFieldIndex = tearOffRepresentation
              .fieldIndexForSignature(posArgCount, nameCombination.names);
          w.BaseFunction tearOffFunction = tearOffClosure.functions[
              tearOffFieldIndex - tearOffRepresentation.vtableBaseIndex];
          if (translator
              .getDummyValuesCollectorForModule(b.moduleBuilder)
              .isDummyFunction(tearOffFunction)) {
            // This name combination may not exist for the target, but got
            // clustered together with other name combinations that do exist.
            // => We make a dummy entry which is unreachable.
            function = translator
                .getDummyValuesCollectorForModule(b.moduleBuilder)
                .getDummyFunction(signature);
          } else {
            function = makeTrampoline(signature, tearOffFunction);
          }
        }
        declareAndAddRefFunc(function);
      }

      void makeVtable(w.BaseFunction? dynamicCallEntry) {
        if (dynamicCallEntry != null) {
          declareAndAddRefFunc(dynamicCallEntry);
        }
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

      b.pushObjectHeaderFields(translator, closureClassInfo);

      // Context is not used by the vtable functions, but it's needed for
      // closure equality checks to work (`_Closure._equals`).
      constants.instantiateConstant(
          b, tearOffConstantInfo.constant, translator.topTypeNonNullable);

      for (final type in typeConstantInfos) {
        constants.instantiateConstant(
            b, type.constant, translator.topTypeNonNullable);
      }
      b.struct_new(tearOffRepresentation.instantiationContextStruct!);

      makeVtable((translator.dynamicModuleSupportEnabled ||
              translator.closureLayouter.usesFunctionApplyWithNamedArguments)
          ? makeDynamicCallEntry()
          : null);
      constants.instantiateConstant(
          b, functionTypeInfo.constant, types.nonNullableTypeType);
      b.struct_new(closureStruct);
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
    final nameInfo = ensureConstant(nameConstant);
    final childConstants = <ConstantInfo>[];
    if (nameInfo != null) {
      childConstants.add(nameInfo);
    }

    return createConstant(constant, childConstants, info.nonNullableType,
        canBeEager: true, (_, b, __) {
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

    final childConstants = <ConstantInfo>[];
    for (Constant argument in arguments) {
      final info = ensureConstant(argument);
      if (info != null) {
        childConstants.add(info);
      }
    }

    return createConstant(
        constant, childConstants, recordClassInfo.nonNullableType,
        canBeEager: true, (_, b, __) {
      b.pushObjectHeaderFields(translator, recordClassInfo);
      for (Constant argument in arguments) {
        constants.instantiateConstant(b, argument, translator.topType);
      }
      b.struct_new(recordClassInfo.struct);
    });
  }

  @override
  ConstantInfo? visitAuxiliaryConstant(AuxiliaryConstant constant) {
    if (constant is DummyValueConstant) {
      final type = constant.type;

      final childConstants = <ConstantInfo>[];
      if (type is w.DefType) {
        if (type is w.StructType) {
          for (w.FieldType field in type.fields) {
            final unpackedType = field.type.unpacked;
            if (unpackedType is w.RefType && !unpackedType.nullable) {
              childConstants.add(ensureConstant(
                  constants._getDummyValueConstant(unpackedType.heapType))!);
            }
          }
        }
      }

      return createConstant(
          constant, childConstants, w.RefType(type, nullable: false),
          canBeEager: true, (_, b, __) {
        translator.instantiateDummyValueHeapType(b, type, constant.name,
            (ib, heapType) {
          constants.instantiateConstant(
              ib,
              constants._getDummyValueConstant(heapType),
              w.RefType(heapType, nullable: false));
        });
      });
    }

    throw UnsupportedError("Unsupported auxiliary constant: $constant");
  }
}

class DummyValueConstant extends AuxiliaryConstant {
  final w.HeapType type;
  final String name;

  DummyValueConstant(this.type, this.name) : super();

  @override
  DartType getType(StaticTypeContext context) {
    throw UnsupportedError('DummyValueConstant does not have a type.');
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('Dummy value constant: $name');
  }

  @override
  void visitChildren(Visitor<dynamic> v) {}

  @override
  int get hashCode => type.hashCode;

  @override
  bool operator ==(Object other) =>
      other is DummyValueConstant && other.type == type;
}

class TypeOfConstantVisitor extends ConstantVisitor<w.RefType>
    with ConstantVisitorDefaultMixin<w.RefType> {
  final Translator translator;

  TypeOfConstantVisitor(this.translator);

  @override
  w.RefType defaultConstant(Constant constant) {
    throw UnimplementedError('Unexpected $constant.');
  }

  @override
  w.RefType visitBoolConstant(BoolConstant constant) {
    return _typeOfClass(translator.boxedBoolClass);
  }

  @override
  w.RefType visitIntConstant(IntConstant constant) {
    return _typeOfClass(translator.boxedIntClass);
  }

  @override
  w.RefType visitDoubleConstant(DoubleConstant constant) {
    return _typeOfClass(translator.boxedDoubleClass);
  }

  @override
  w.RefType visitStringConstant(StringConstant constant) {
    return _typeOfClass(translator.jsStringClass);
  }

  @override
  w.RefType visitListConstant(ListConstant constant) {
    return _typeOfClass(translator.immutableListClass);
  }

  @override
  w.RefType visitMapConstant(MapConstant constant) {
    return _typeOfClass(translator.immutableMapClass);
  }

  @override
  w.RefType visitSetConstant(SetConstant constant) {
    return _typeOfClass(translator.immutableSetClass);
  }

  @override
  w.RefType visitTypeLiteralConstant(TypeLiteralConstant constant) {
    throw StateError('Type literal constants should\'ve been lowered already.');
  }

  @override
  w.RefType visitSymbolConstant(SymbolConstant constant) {
    return _typeOfClass(translator.symbolClass);
  }

  @override
  w.RefType visitRecordConstant(RecordConstant constant) {
    return translator.getRecordClassInfo(constant.recordType).nonNullableType;
  }

  @override
  w.RefType visitAuxiliaryConstant(AuxiliaryConstant constant) {
    if (constant is DummyValueConstant) {
      return w.RefType(constant.type, nullable: false);
    }
    throw StateError('Unexpected auxiliary constant: $constant');
  }

  @override
  w.RefType visitInstanceConstant(InstanceConstant constant) {
    w.RefType wasmArrayType(InstanceConstant constant,
        {required bool mutable}) {
      final arrayType = translator.arrayTypeForDartType(
          constant.typeArguments.single,
          mutable: mutable);
      return w.RefType.def(arrayType, nullable: false);
    }

    final cls = constant.classNode;
    if (cls == translator.wasmArrayClass) {
      return wasmArrayType(constant, mutable: true);
    }
    if (cls == translator.immutableWasmArrayClass) {
      return wasmArrayType(constant, mutable: false);
    }
    return _typeOfClass(cls);
  }

  @override
  w.RefType visitStaticTearOffConstant(StaticTearOffConstant constant) {
    final member = constant.targetReference.asProcedure;
    final function = member.function;
    final representation = translator.closureLayouter.getClosureRepresentation(
        function.typeParameters.length,
        function.positionalParameters.length,
        function.namedParameters.map((p) => p.name!).toList())!;
    return w.RefType.def(representation.closureStruct, nullable: false);
  }

  @override
  w.RefType visitInstantiationConstant(InstantiationConstant constant) {
    final tearOffConstant = constant.tearOffConstant as TearOffConstant;
    final function = tearOffConstant.function;
    final representation = translator.closureLayouter.getClosureRepresentation(
        0,
        function.positionalParameters.length,
        function.namedParameters.map((p) => p.name!).toList())!;
    return w.RefType.def(representation.closureStruct, nullable: false);
  }

  w.RefType _typeOfClass(Class klass) =>
      translator.classInfo[klass]!.nonNullableType;
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

/// Responsible for reading constants and defining them.
class _ConstantAccessor {
  final Translator translator;

  /// The modules that use the given constant.
  ///
  /// NOTE: If a module uses constant `c` it uses also all constants `c`
  /// transitively refers to.
  final Map<ConstantInfo, Set<w.ModuleBuilder>> moduleUses = {};

  /// We maintain a table for lazily initialized constants that are used across
  /// modules. This avoids having many invidiual globals of the same type with
  /// null initializer.
  final Map<w.RefType, w.TableBuilder> lazySlotTables = {};
  late final tableImporter = WasmTableImporter(translator, 'constant-table');

  final Map<w.HeapType, w.Global> _dummyValueCanonicalizationCheckers = {};
  late final w.FunctionType _dummyValueCheckerType =
      translator.typesBuilder.defineFunction([
    const w.RefType.any(nullable: false),
  ], [
    w.NumType.i32
  ]);

  _ConstantAccessor(this.translator);

  /// Reads a constant.
  ///
  /// If we haven't decided into which module to place the constant it may emit
  /// a stub in the instruction stream which we'll patch after code generation
  /// is complete.
  ///
  /// We decide the constant placement as follows:
  ///
  ///  * If the main module uses it:
  ///    => Define the constant in main module.
  ///    => This may happen during code generation.
  ///
  ///  * If more than two modules use it:
  ///    => Define the constant in main module.
  ///    => This may happen during code generation.
  ///
  ///  * If a constant is accessed only by a single module:
  ///    => Define the constant in that module.
  ///    => This happens after code generation when we know all constant uses.
  ///
  w.ValueType loadConstant(w.InstructionsBuilder b, Constant c,
      w.ModuleBuilder? deferredModuleGuard) {
    final info = translator.constants.ensureConstant(c)!;
    final existingDefinition = info._definition;

    if (existingDefinition != null) {
      // We already have a defined constant. Possibly import it and then use it.
      return _readDefinedConstant(b, b.moduleBuilder, info, existingDefinition);
    }

    // We have to guarantee that using the constant synchronously works. If the
    // constant use is preceded with a deferred module load guard, we can
    // consider the use to be in that deferred module, possibly allowing us to
    // put the constant in a deferred library (even if the guarded use is e.g.
    // in main library).
    final usingModule = deferredModuleGuard ?? b.moduleBuilder;

    // If the (non-guarded) use is in the main module then the constant has to
    // be placed in the main module.
    if (!forceDelayedConstantDefinition &&
        usingModule == translator.mainModule) {
      final definition =
          _defineConstantInModuleRecursive(translator.mainModule, info);
      return _readDefinedConstant(b, translator.mainModule, info, definition);
    }

    // Remember for the transitive DAG of [constant] that we use it in this
    // module.
    void rememberConstantUse(ConstantInfo info) {
      if (moduleUses.putIfAbsent(info, () => {}).add(usingModule)) {
        for (final child in info.children) {
          rememberConstantUse(child);
        }
      }
    }

    rememberConstantUse(info);

    // The current module is the only one using the constant atm, but in the
    // future other modules may also use it. So we don't know where to place
    // it just yet.
    // => Let's emit a patchable constant read and patch the real read later on.

    // There's no guarantee that the constant is going to be an eager constant.
    // So the code tring to instantiate the constant shouldn't be in a global
    // initailizer.
    assert(!b.constantExpression || constantIsAlwaysEager(info.constant));

    final patchInstructions = b.createPatchableRegion([], [info.type]);
    if (patchInstructions != null) {
      translator.linkingActions.add(() {
        // All constant uses have been discovered during codegen phase so we can
        // now decide into which module to place the constant and patch the
        // constant access to load it from there.
        final definition =
            info._definition ?? _defineConstantInModuleRecursive(null, info);
        _readDefinedConstant(patchInstructions, usingModule, info, definition);
      });
    }

    return info.type;
  }

  /// Reads the given constant.
  ///
  /// Normally `b.moduleBuilder == usingModule`, except for the situation where
  /// the read happens under a load guard.
  ///
  /// In that case the `b.moduleBuilder` may not have an initializer function
  /// (to reduce its size) and instead it can rely on the load guarded deferred
  /// module to be loaded by the time we read the constant, so it can use that
  /// deferred module's constant initializer.
  w.ValueType _readDefinedConstant(
      w.InstructionsBuilder b,
      w.ModuleBuilder usingModule,
      ConstantInfo info,
      ConstantDefinition definition) {
    // Eagerly initialized constant.
    if (definition is GlobalBasedConstantDefinition && !definition.isLazy) {
      translator.globals.readGlobal(b, definition.global);
      return definition.global.type.type;
    }

    // Lazily initialized constant.
    assert(definition.isLazy);

    switch (definition) {
      case GlobalBasedConstantDefinition():
        // Use global & lazy initializer function.
        w.Label done = b.block(const [], [info.type]);
        translator.globals.readGlobal(b, definition.global);
        b.br_on_non_null(done);
        translator.callFunction(definition.initializer(usingModule), b);
        b.end();
        break;
      case TableBasedConstantDefinition():
        // Use table & lazy initializer function.
        w.Label done = b.block(const [], [info.type]);
        b.i32_const(definition.tableIndex);
        b.table_get(tableImporter.get(definition.table, b.moduleBuilder));
        b.br_on_non_null(done);
        translator.callFunction(definition.initializer(usingModule), b);
        b.end();
        break;
    }

    return info.type;
  }

  /// If [assignedModule] is not null assigns all undefined constants to that
  /// module. Otherwise takes into account the uses of a constant to determine
  /// where to place it.
  ConstantDefinition _defineConstantInModuleRecursive(
      w.ModuleBuilder? assignedModule, ConstantInfo info) {
    assert(info._definition == null);

    for (final child in info.children) {
      if (child._definition == null) {
        _defineConstantInModuleRecursive(assignedModule, child);
      }
    }
    // Since constants form a DAG, the [node] shouldn't have a definition yet.
    assert(info._definition == null);

    // If we didn't eagerly assign the constant to be in main module, we make a
    // choice now.
    //
    // We want to choose a module that is available by the time the constant is
    // used. If only one module uses the constant we place it in that module. If
    // it's used by multiple modules we make a global in the main module and
    // make all using modules bring an initializer function with them.
    Set<w.ModuleBuilder>? deferredUses;
    if (assignedModule == null) {
      final uses = moduleUses[info]!;
      assert(uses.isNotEmpty);
      if (uses.length == 1) {
        assignedModule = uses.single;
      } else if (uses.contains(translator.mainModule)) {
        assignedModule = translator.mainModule;
      } else {
        // Will become lazy constant with global in main module and initializer
        // in all using modules.
        deferredUses = uses;
      }
    }
    return _defineConstantInModule(assignedModule, deferredUses, info);
  }

  ConstantDefinition _defineConstantInModule(w.ModuleBuilder? targetModule,
      Set<w.ModuleBuilder>? deferredUses, ConstantInfo info) {
    assert((targetModule != null) != (deferredUses != null));
    assert(deferredUses == null ||
        deferredUses.length > 1 &&
            !deferredUses.contains(translator.mainModule));

    final constant = info.constant;

    // The constant itself may be forced to be lazy (e.g. array size too large).
    bool lazy = !info.canBeEager;

    // If there's uses in N different deferred modules, we make it lazy, define
    // global in main module & initializer in each using module.
    lazy |= deferredUses != null;

    // The constant's children may influence laziness.
    if (!lazy) {
      for (final child in info.children) {
        final definition = child._definition!;

        // If the child is lazy, this constant becomes lazy.
        if (definition.isLazy) {
          lazy = true;
          break;
        }

        // The child isn't lazy, so it cannot be a table-based constant
        // definition.
        definition as GlobalBasedConstantDefinition;

        // If we place the constant in a module that may be loaded before the
        // constants of children, it must get initialized lazily.
        final childModule = definition.global.enclosingModule;
        final baseModule = translator.isDynamicSubmodule
            ? translator.dynamicSubmodule
            : translator.mainModule;
        if (childModule != targetModule?.module &&
            childModule != translator.mainModule.module &&
            childModule != baseModule.module) {
          lazy = true;
          break;
        }
      }
    }

    // The constant itself may be forced to be lazy depending on which module we
    // place it in.
    if (!lazy) {
      // The constant codegen code may decide to make it lazy depending on which
      // module it's going to be placed in.
      lazy = info._forceLazy(info, targetModule!);
    }

    // Define the lazy or non-lazy constant in the module.
    final ConstantDefinition definition;
    if (lazy) {
      if (targetModule == null) {
        final w.TableBuilder table = lazySlotTables.putIfAbsent(info.type, () {
          return translator.mainModule.tables
              .define(info.type.withNullability(true), 0);
        });
        final tableIndex = table.minSize++;
        final name = _constantName(info.constant);
        final initFunctions = {
          for (final usingModule in deferredUses!)
            usingModule: _createLazyTableInitializer(
                usingModule, table, tableIndex, name, info),
        };
        definition =
            TableBasedConstantDefinition(table, tableIndex, initFunctions);
      } else {
        final (global, initFunction) = _createLazyConstant(targetModule, info);
        definition = GlobalBasedConstantDefinition(global, initFunction);
      }
    } else {
      final global = _createNonLazyConstant(targetModule!, info);
      definition = GlobalBasedConstantDefinition(global, null);
    }
    info.setDefinition(definition);

    if (info.exportByMainApp) {
      assert(translator.dynamicModuleSupportEnabled &&
          !translator.isDynamicSubmodule);
      // Current dynamic module implementation requires main module to be
      // monolitic.
      definition as GlobalBasedConstantDefinition;
      translator.exporter.exportDynamicConstant(
          targetModule!, constant, definition.global,
          initializer: definition._initFunction);
    }
    return definition;
  }

  void defineMainAppDefinition(
      ConstantInfo info, String globalName, String? initializeName) {
    assert(translator.isDynamicSubmodule);
    final type = info.type;

    final fakeMainApp = translator.mainModule;

    // Make fake global in the fake main module.
    final globalType = w.GlobalType(
        initializeName != null ? type.withNullability(true) : type,
        mutable: false);
    final fakeGlobal =
        fakeMainApp.globals.define(globalType, _constantName(info.constant));
    translator.globals
        .declareMainAppGlobalExportWithName(globalName, fakeGlobal);

    // Make fake initializer function in the fake main module.
    w.BaseFunction? fakeInitializer;
    if (initializeName != null) {
      final initFunctionType =
          translator.typesBuilder.defineFunction(const [], [info.type]);
      fakeInitializer = fakeMainApp.functions.define(initFunctionType);
      translator.declareMainAppFunctionExportWithName(
          globalName, fakeInitializer);
    }

    info._definition =
        GlobalBasedConstantDefinition(fakeGlobal, fakeInitializer);
  }

  (w.GlobalBuilder, w.FunctionBuilder) _createLazyConstant(
      w.ModuleBuilder targetModule, ConstantInfo info) {
    final name = _constantName(info.constant);

    final definedGlobal = _createLazyGlobal(targetModule, name, info);
    final initFunction =
        _createLazyGlobalInitializer(targetModule, definedGlobal, name, info);

    return (definedGlobal, initFunction);
  }

  w.GlobalBuilder _createLazyGlobal(
      w.ModuleBuilder module, String name, ConstantInfo info) {
    final globalType = w.GlobalType(info.type.withNullability(true));
    final definedGlobal = module.globals.define(globalType, name);
    definedGlobal.initializer.ref_null(w.HeapType.none);
    definedGlobal.initializer.end();
    return definedGlobal;
  }

  w.FunctionBuilder _createLazyGlobalInitializer(w.ModuleBuilder module,
      w.GlobalBuilder definedGlobal, String name, ConstantInfo info) {
    final type = info.type;
    final initFunctionType =
        translator.typesBuilder.defineFunction(const [], [type]);
    final initFunction =
        module.functions.define(initFunctionType, '$name (lazy initializer)');
    final b = initFunction.body;
    info._codeGen(info, b, true);
    if (info.needsRuntimeCanonicalization) {
      final valueLocal = b.addLocal(type);
      info.constant.accept(ConstantCanonicalizer(translator, b, valueLocal,
          _dummyValueCanonicalizationCheckers, _dummyValueCheckerType));
    }
    w.Local temp = b.addLocal(type);
    b.local_tee(temp);
    translator.globals.writeGlobal(b, definedGlobal);
    b.local_get(temp);
    b.end();

    return initFunction;
  }

  w.FunctionBuilder _createLazyTableInitializer(w.ModuleBuilder module,
      w.TableBuilder table, int tableIndex, String name, ConstantInfo info) {
    final type = info.type;
    final initFunctionType =
        translator.typesBuilder.defineFunction(const [], [type]);
    final initFunction =
        module.functions.define(initFunctionType, '$name (lazy initializer)');
    final b = initFunction.body;
    b.i32_const(tableIndex);
    info._codeGen(info, b, true);
    if (info.needsRuntimeCanonicalization) {
      final valueLocal = b.addLocal(type);
      info.constant.accept(ConstantCanonicalizer(translator, b, valueLocal,
          _dummyValueCanonicalizationCheckers, _dummyValueCheckerType));
    }
    w.Local temp = b.addLocal(type);
    b.local_tee(temp);
    b.table_set(tableImporter.get(table, module));
    b.local_get(temp);
    b.end();

    return initFunction;
  }

  w.GlobalBuilder _createNonLazyConstant(
      w.ModuleBuilder targetModule, ConstantInfo info) {
    final constants = translator.constants;

    // Create global with the constant in its initializer.
    assert(!constants.currentlyCreating);
    final globalType = w.GlobalType(info.type, mutable: false);
    constants.currentlyCreating = true;
    final definedGlobal =
        targetModule.globals.define(globalType, _constantName(info.constant));
    info._codeGen(info, definedGlobal.initializer, false);
    definedGlobal.initializer.end();
    constants.currentlyCreating = false;

    return definedGlobal;
  }

  bool constantIsAlwaysEager(Constant constant) {
    if (constant is NullConstant ||
        constant is BoolConstant ||
        constant is IntConstant ||
        constant is DoubleConstant) {
      // We can always eagerly use those constants because
      //   * null is not a heap object
      //   * true/false should always be defined in main module
      //   * int/double do not have identity and can be just materialized (plus
      //     boxed if needed)
      return true;
    }
    if (constant is InstanceConstant) {
      final klass = constant.classNode;
      if (klass == translator.wasmI32Class ||
          klass == translator.wasmI64Class ||
          klass == translator.wasmF32Class ||
          klass == translator.wasmF64Class) {
        return true;
      }
    }
    return false;
  }

  static int _nextGlobalId = 0;
  String _constantName(Constant constant) {
    final id = _nextGlobalId++;
    final prefix = translator.options.uniqueConstantNames ? 'C$id ' : '';
    if (constant is StringConstant) {
      var value = constant.value;
      final newline = value.indexOf('\n');
      if (newline != -1) value = value.substring(0, newline);
      if (value.length > 30) value = '${value.substring(0, 30)}<...>';
      return '$prefix"$value"';
    }
    if (constant is BoolConstant) {
      return '$prefix${constant.value}';
    }
    if (constant is IntConstant) {
      return '$prefix${constant.value}';
    }
    if (constant is DoubleConstant) {
      return '$prefix${constant.value}';
    }
    if (constant is InstanceConstant) {
      final klass = constant.classNode;
      final name = klass.name;
      if (constant.typeArguments.isEmpty) {
        return '$prefix$name';
      }
      final typeArguments = constant.typeArguments.map(_nameType).join(', ');
      if (klass == translator.wasmArrayClass ||
          klass == translator.immutableWasmArrayClass) {
        final entries =
            (constant.fieldValues.values.single as ListConstant).entries;
        return '$prefix$name<$typeArguments>[${entries.length}]';
      }
      return '$prefix$name<$typeArguments>';
    }
    if (constant is TearOffConstant) {
      return '$prefix${constant.target.name} tear-off';
    }
    if (constant is AuxiliaryConstant) {
      if (constant is DummyValueConstant) {
        return '$prefix #Dummy(${constant.type})';
      }
    }
    return '$prefix$constant';
  }

  String _nameType(DartType type) {
    if (type is InterfaceType) {
      final name = type.classNode.name;
      if (type.typeArguments.isEmpty) return name;
      return '$name<${type.typeArguments.map((t) => _nameType(t)).join(', ')}>';
    }
    return '$type';
  }
}
