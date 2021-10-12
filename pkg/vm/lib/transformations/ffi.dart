// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains logic which is shared between the ffi_definition and
// ffi_use_site transformers.

library vm.transformations.ffi;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart'
    show TypeEnvironment, SubtypeCheckMode;

/// Represents the (instantiated) ffi.NativeType.
enum NativeType {
  kNativeType,
  kNativeInteger,
  kNativeDouble,
  kPointer,
  kNativeFunction,
  kInt8,
  kInt16,
  kInt32,
  kInt64,
  kUint8,
  kUint16,
  kUint32,
  kUnit64,
  kIntptr,
  kFloat,
  kDouble,
  kVoid,
  kOpaque,
  kStruct,
  kHandle,
}

const NativeType kNativeTypeIntStart = NativeType.kInt8;
const NativeType kNativeTypeIntEnd = NativeType.kIntptr;

/// The [NativeType] class names, indexed by [NativeType].
const List<String> nativeTypeClassNames = [
  'NativeType',
  '_NativeInteger',
  '_NativeDouble',
  'Pointer',
  'NativeFunction',
  'Int8',
  'Int16',
  'Int32',
  'Int64',
  'Uint8',
  'Uint16',
  'Uint32',
  'Uint64',
  'IntPtr',
  'Float',
  'Double',
  'Void',
  'Opaque',
  'Struct',
  'Handle'
];

const int UNKNOWN = 0;
const int WORD_SIZE = -1;

/// The [NativeType] sizes in bytes, indexed by [NativeType].
const List<int> nativeTypeSizes = [
  UNKNOWN, // NativeType
  UNKNOWN, // NativeInteger
  UNKNOWN, // NativeDouble
  WORD_SIZE, // Pointer
  UNKNOWN, // NativeFunction
  1, // Int8
  2, // Int16
  4, // Int32
  8, // Int64
  1, // Uint8
  2, // Uint16
  4, // Uint32
  8, // Uint64
  WORD_SIZE, // IntPtr
  4, // Float
  8, // Double
  UNKNOWN, // Void
  UNKNOWN, // Opaque
  UNKNOWN, // Struct
  WORD_SIZE, // Handle
];

/// The struct layout in various ABIs.
///
/// ABIs differ per architectures and with different compilers.
/// We pick the default struct layout based on the architecture and OS.
///
/// Compilers _can_ deviate from the default layout, but this prevents
/// executables from making system calls. So this seems rather uncommon.
///
/// In the future, we might support custom struct layouts. For more info see
/// https://github.com/dart-lang/sdk/issues/35768.
enum Abi {
  /// Layout in all 64bit ABIs (x64 and arm64).
  wordSize64,

  /// Layout in System V ABI for x386 (ia32 on Linux) and in iOS Arm 32 bit.
  wordSize32Align32,

  /// Layout in both the Arm 32 bit ABI and the Windows ia32 ABI.
  wordSize32Align64,
}

/// WORD_SIZE in bytes.
const wordSize = <Abi, int>{
  Abi.wordSize64: 8,
  Abi.wordSize32Align32: 4,
  Abi.wordSize32Align64: 4,
};

/// Elements that are not aligned to their size.
///
/// Has an entry for all Abis. Empty entries document that every native
/// type is aligned to it's own size in this ABI.
///
/// See runtime/vm/ffi/abi.cc for asserts in the VM that verify these
/// alignments.
///
/// TODO(37470): Add uncommon primitive data types when we want to support them.
const nonSizeAlignment = <Abi, Map<NativeType, int>>{
  Abi.wordSize64: {},

  // x86 System V ABI:
  // > uint64_t | size 8 | alignment 4
  // > double   | size 8 | alignment 4
  // https://github.com/hjl-tools/x86-psABI/wiki/intel386-psABI-1.1.pdf page 8.
  //
  // iOS 32 bit alignment:
  // https://developer.apple.com/documentation/uikit/app_and_environment/updating_your_app_from_32-bit_to_64-bit_architecture/updating_data_structures
  Abi.wordSize32Align32: {
    NativeType.kDouble: 4,
    NativeType.kInt64: 4,
    NativeType.kUnit64: 4
  },

  // The default for MSVC x86:
  // > The alignment-requirement for all data except structures, unions, and
  // > arrays is either the size of the object or the current packing size
  // > (specified with either /Zp or the pack pragma, whichever is less).
  // https://docs.microsoft.com/en-us/cpp/c-language/padding-and-alignment-of-structure-members?view=vs-2019
  //
  // GCC _can_ compile on Linux to this alignment with -malign-double, but does
  // not do so by default:
  // > Warning: if you use the -malign-double switch, structures containing the
  // > above types are aligned differently than the published application
  // > binary interface specifications for the x86-32 and are not binary
  // > compatible with structures in code compiled without that switch.
  // https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
  //
  // Arm always requires 8 byte alignment for 8 byte values:
  // http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042d/IHI0042D_aapcs.pdf 4.1 Fundamental Data Types
  Abi.wordSize32Align64: {},
};

/// Load, store, and elementAt are rewired to their static type for these types.
const List<NativeType> optimizedTypes = [
  NativeType.kInt8,
  NativeType.kInt16,
  NativeType.kInt32,
  NativeType.kInt64,
  NativeType.kUint8,
  NativeType.kUint16,
  NativeType.kUint32,
  NativeType.kUnit64,
  NativeType.kIntptr,
  NativeType.kFloat,
  NativeType.kDouble,
  NativeType.kPointer,
];

const List<NativeType> unalignedLoadsStores = [
  NativeType.kFloat,
  NativeType.kDouble,
];

/// [FfiTransformer] contains logic which is shared between
/// _FfiUseSiteTransformer and _FfiDefinitionTransformer.
class FfiTransformer extends Transformer {
  final TypeEnvironment env;
  final CoreTypes coreTypes;
  final LibraryIndex index;
  final ClassHierarchy hierarchy;
  final DiagnosticReporter diagnosticReporter;
  final ReferenceFromIndex? referenceFromIndex;

  final Class objectClass;
  final Class intClass;
  final Class doubleClass;
  final Class listClass;
  final Class typeClass;
  final Procedure unsafeCastMethod;
  final Procedure nativeEffectMethod;
  final Class typedDataClass;
  final Procedure typedDataBufferGetter;
  final Procedure typedDataOffsetInBytesGetter;
  final Procedure byteBufferAsUint8List;
  final Procedure uint8ListFactory;
  final Class pragmaClass;
  final Field pragmaName;
  final Field pragmaOptions;
  final Procedure listElementAt;
  final Procedure numAddition;
  final Procedure numMultiplication;

  final Library ffiLibrary;
  final Class allocatorClass;
  final Class nativeFunctionClass;
  final Class handleClass;
  final Class opaqueClass;
  final Class arrayClass;
  final Class arraySizeClass;
  final Field arraySizeDimension1Field;
  final Field arraySizeDimension2Field;
  final Field arraySizeDimension3Field;
  final Field arraySizeDimension4Field;
  final Field arraySizeDimension5Field;
  final Field arraySizeDimensionsField;
  final Class pointerClass;
  final Class compoundClass;
  final Class structClass;
  final Class unionClass;
  final Class ffiNativeClass;
  final Class nativeFieldWrapperClass1Class;
  final Class ffiStructLayoutClass;
  final Field ffiStructLayoutTypesField;
  final Field ffiStructLayoutPackingField;
  final Class ffiInlineArrayClass;
  final Field ffiInlineArrayElementTypeField;
  final Field ffiInlineArrayLengthField;
  final Class packedClass;
  final Field packedMemberAlignmentField;
  final Procedure allocateMethod;
  final Procedure allocatorAllocateMethod;
  final Procedure castMethod;
  final Procedure offsetByMethod;
  final Procedure elementAtMethod;
  final Procedure addressGetter;
  final Procedure structPointerRef;
  final Procedure structPointerElemAt;
  final Procedure unionPointerRef;
  final Procedure unionPointerElemAt;
  final Procedure structArrayElemAt;
  final Procedure unionArrayElemAt;
  final Procedure arrayArrayElemAt;
  final Procedure arrayArrayAssignAt;
  final Procedure asFunctionMethod;
  final Procedure asFunctionInternal;
  final Procedure sizeOfMethod;
  final Procedure lookupFunctionMethod;
  final Procedure fromFunctionMethod;
  final Field compoundTypedDataBaseField;
  final Field arrayTypedDataBaseField;
  final Field arraySizeField;
  final Field arrayNestedDimensionsField;
  final Procedure arrayCheckIndex;
  final Field arrayNestedDimensionsFlattened;
  final Field arrayNestedDimensionsFirst;
  final Field arrayNestedDimensionsRest;
  final Constructor structFromTypedDataBase;
  final Constructor unionFromTypedDataBase;
  final Constructor arrayConstructor;
  final Procedure fromAddressInternal;
  final Procedure libraryLookupMethod;
  final Procedure abiMethod;
  final Procedure pointerFromFunctionProcedure;
  final Procedure nativeCallbackFunctionProcedure;
  final Map<NativeType, Procedure> loadMethods;
  final Map<NativeType, Procedure> loadUnalignedMethods;
  final Map<NativeType, Procedure> storeMethods;
  final Map<NativeType, Procedure> storeUnalignedMethods;
  final Map<NativeType, Procedure> elementAtMethods;
  final Procedure memCopy;
  final Procedure allocationTearoff;
  final Procedure asFunctionTearoff;
  final Procedure lookupFunctionTearoff;
  final Procedure getNativeFieldFunction;
  final Procedure reachabilityFenceFunction;

  late final InterfaceType nativeFieldWrapperClass1Type;
  late final InterfaceType voidType;
  late final InterfaceType pointerVoidType;

  /// Classes corresponding to [NativeType], indexed by [NativeType].
  final List<Class> nativeTypesClasses;

  Library? _currentLibrary;
  Library get currentLibrary => _currentLibrary!;

  IndexedLibrary? currentLibraryIndex;

  FfiTransformer(this.index, this.coreTypes, this.hierarchy,
      this.diagnosticReporter, this.referenceFromIndex)
      : env = TypeEnvironment(coreTypes, hierarchy),
        objectClass = coreTypes.objectClass,
        intClass = coreTypes.intClass,
        doubleClass = coreTypes.doubleClass,
        listClass = coreTypes.listClass,
        typeClass = coreTypes.typeClass,
        unsafeCastMethod =
            index.getTopLevelProcedure('dart:_internal', 'unsafeCast'),
        nativeEffectMethod =
            index.getTopLevelProcedure('dart:_internal', '_nativeEffect'),
        typedDataClass = index.getClass('dart:typed_data', 'TypedData'),
        typedDataBufferGetter =
            index.getProcedure('dart:typed_data', 'TypedData', 'get:buffer'),
        typedDataOffsetInBytesGetter = index.getProcedure(
            'dart:typed_data', 'TypedData', 'get:offsetInBytes'),
        byteBufferAsUint8List =
            index.getProcedure('dart:typed_data', 'ByteBuffer', 'asUint8List'),
        uint8ListFactory =
            index.getProcedure('dart:typed_data', 'Uint8List', ''),
        pragmaClass = coreTypes.pragmaClass,
        pragmaName = coreTypes.pragmaName,
        pragmaOptions = coreTypes.pragmaOptions,
        listElementAt = coreTypes.index.getProcedure('dart:core', 'List', '[]'),
        numAddition = coreTypes.index.getProcedure('dart:core', 'num', '+'),
        numMultiplication =
            coreTypes.index.getProcedure('dart:core', 'num', '*'),
        ffiLibrary = index.getLibrary('dart:ffi'),
        allocatorClass = index.getClass('dart:ffi', 'Allocator'),
        nativeFunctionClass = index.getClass('dart:ffi', 'NativeFunction'),
        handleClass = index.getClass('dart:ffi', 'Handle'),
        opaqueClass = index.getClass('dart:ffi', 'Opaque'),
        arrayClass = index.getClass('dart:ffi', 'Array'),
        arraySizeClass = index.getClass('dart:ffi', '_ArraySize'),
        arraySizeDimension1Field =
            index.getField('dart:ffi', '_ArraySize', 'dimension1'),
        arraySizeDimension2Field =
            index.getField('dart:ffi', '_ArraySize', 'dimension2'),
        arraySizeDimension3Field =
            index.getField('dart:ffi', '_ArraySize', 'dimension3'),
        arraySizeDimension4Field =
            index.getField('dart:ffi', '_ArraySize', 'dimension4'),
        arraySizeDimension5Field =
            index.getField('dart:ffi', '_ArraySize', 'dimension5'),
        arraySizeDimensionsField =
            index.getField('dart:ffi', '_ArraySize', 'dimensions'),
        pointerClass = index.getClass('dart:ffi', 'Pointer'),
        compoundClass = index.getClass('dart:ffi', '_Compound'),
        structClass = index.getClass('dart:ffi', 'Struct'),
        unionClass = index.getClass('dart:ffi', 'Union'),
        ffiNativeClass = index.getClass('dart:ffi', 'FfiNative'),
        nativeFieldWrapperClass1Class =
            index.getClass('dart:nativewrappers', 'NativeFieldWrapperClass1'),
        ffiStructLayoutClass = index.getClass('dart:ffi', '_FfiStructLayout'),
        ffiStructLayoutTypesField =
            index.getField('dart:ffi', '_FfiStructLayout', 'fieldTypes'),
        ffiStructLayoutPackingField =
            index.getField('dart:ffi', '_FfiStructLayout', 'packing'),
        ffiInlineArrayClass = index.getClass('dart:ffi', '_FfiInlineArray'),
        ffiInlineArrayElementTypeField =
            index.getField('dart:ffi', '_FfiInlineArray', 'elementType'),
        ffiInlineArrayLengthField =
            index.getField('dart:ffi', '_FfiInlineArray', 'length'),
        packedClass = index.getClass('dart:ffi', 'Packed'),
        packedMemberAlignmentField =
            index.getField('dart:ffi', 'Packed', 'memberAlignment'),
        allocateMethod =
            index.getProcedure('dart:ffi', 'AllocatorAlloc', 'call'),
        allocatorAllocateMethod =
            index.getProcedure('dart:ffi', 'Allocator', 'allocate'),
        castMethod = index.getProcedure('dart:ffi', 'Pointer', 'cast'),
        offsetByMethod = index.getProcedure('dart:ffi', 'Pointer', '_offsetBy'),
        elementAtMethod =
            index.getProcedure('dart:ffi', 'Pointer', 'elementAt'),
        addressGetter =
            index.getProcedure('dart:ffi', 'Pointer', 'get:address'),
        compoundTypedDataBaseField =
            index.getField('dart:ffi', '_Compound', '_typedDataBase'),
        arrayTypedDataBaseField =
            index.getField('dart:ffi', 'Array', '_typedDataBase'),
        arraySizeField = index.getField('dart:ffi', 'Array', '_size'),
        arrayNestedDimensionsField =
            index.getField('dart:ffi', 'Array', '_nestedDimensions'),
        arrayCheckIndex =
            index.getProcedure('dart:ffi', 'Array', '_checkIndex'),
        arrayNestedDimensionsFlattened =
            index.getField('dart:ffi', 'Array', '_nestedDimensionsFlattened'),
        arrayNestedDimensionsFirst =
            index.getField('dart:ffi', 'Array', '_nestedDimensionsFirst'),
        arrayNestedDimensionsRest =
            index.getField('dart:ffi', 'Array', '_nestedDimensionsRest'),
        structFromTypedDataBase =
            index.getConstructor('dart:ffi', 'Struct', '_fromTypedDataBase'),
        unionFromTypedDataBase =
            index.getConstructor('dart:ffi', 'Union', '_fromTypedDataBase'),
        arrayConstructor = index.getConstructor('dart:ffi', 'Array', '_'),
        fromAddressInternal =
            index.getTopLevelProcedure('dart:ffi', '_fromAddress'),
        structPointerRef =
            index.getProcedure('dart:ffi', 'StructPointer', 'get:ref'),
        structPointerElemAt =
            index.getProcedure('dart:ffi', 'StructPointer', '[]'),
        unionPointerRef =
            index.getProcedure('dart:ffi', 'UnionPointer', 'get:ref'),
        unionPointerElemAt =
            index.getProcedure('dart:ffi', 'UnionPointer', '[]'),
        structArrayElemAt = index.getProcedure('dart:ffi', 'StructArray', '[]'),
        unionArrayElemAt = index.getProcedure('dart:ffi', 'UnionArray', '[]'),
        arrayArrayElemAt = index.getProcedure('dart:ffi', 'ArrayArray', '[]'),
        arrayArrayAssignAt =
            index.getProcedure('dart:ffi', 'ArrayArray', '[]='),
        asFunctionMethod = index.getProcedure(
            'dart:ffi', 'NativeFunctionPointer', 'asFunction'),
        asFunctionInternal =
            index.getTopLevelProcedure('dart:ffi', '_asFunctionInternal'),
        sizeOfMethod = index.getTopLevelProcedure('dart:ffi', 'sizeOf'),
        lookupFunctionMethod = index.getProcedure(
            'dart:ffi', 'DynamicLibraryExtension', 'lookupFunction'),
        fromFunctionMethod =
            index.getProcedure('dart:ffi', 'Pointer', 'fromFunction'),
        libraryLookupMethod =
            index.getProcedure('dart:ffi', 'DynamicLibrary', 'lookup'),
        abiMethod = index.getTopLevelProcedure('dart:ffi', '_abi'),
        pointerFromFunctionProcedure =
            index.getTopLevelProcedure('dart:ffi', '_pointerFromFunction'),
        nativeCallbackFunctionProcedure =
            index.getTopLevelProcedure('dart:ffi', '_nativeCallbackFunction'),
        nativeTypesClasses = nativeTypeClassNames
            .map((name) => index.getClass('dart:ffi', name))
            .toList(),
        loadMethods = Map.fromIterable(optimizedTypes, value: (t) {
          final name = nativeTypeClassNames[t.index];
          return index.getTopLevelProcedure('dart:ffi', "_load$name");
        }),
        loadUnalignedMethods =
            Map.fromIterable(unalignedLoadsStores, value: (t) {
          final name = nativeTypeClassNames[t.index];
          return index.getTopLevelProcedure(
              'dart:ffi', "_load${name}Unaligned");
        }),
        storeMethods = Map.fromIterable(optimizedTypes, value: (t) {
          final name = nativeTypeClassNames[t.index];
          return index.getTopLevelProcedure('dart:ffi', "_store$name");
        }),
        storeUnalignedMethods =
            Map.fromIterable(unalignedLoadsStores, value: (t) {
          final name = nativeTypeClassNames[t.index];
          return index.getTopLevelProcedure(
              'dart:ffi', "_store${name}Unaligned");
        }),
        elementAtMethods = Map.fromIterable(optimizedTypes, value: (t) {
          final name = nativeTypeClassNames[t.index];
          return index.getTopLevelProcedure('dart:ffi', "_elementAt$name");
        }),
        memCopy = index.getTopLevelProcedure('dart:ffi', '_memCopy'),
        allocationTearoff = index.getProcedure(
            'dart:ffi', 'AllocatorAlloc', LibraryIndex.tearoffPrefix + 'call'),
        asFunctionTearoff = index.getProcedure('dart:ffi',
            'NativeFunctionPointer', LibraryIndex.tearoffPrefix + 'asFunction'),
        lookupFunctionTearoff = index.getProcedure(
            'dart:ffi',
            'DynamicLibraryExtension',
            LibraryIndex.tearoffPrefix + 'lookupFunction'),
        getNativeFieldFunction = index.getTopLevelProcedure(
            'dart:nativewrappers', '_getNativeField'),
        reachabilityFenceFunction =
            index.getTopLevelProcedure('dart:_internal', 'reachabilityFence') {
    nativeFieldWrapperClass1Type = nativeFieldWrapperClass1Class.getThisType(
        coreTypes, Nullability.nonNullable);
    voidType = nativeTypesClasses[NativeType.kVoid.index]
        .getThisType(coreTypes, Nullability.nonNullable);
    pointerVoidType =
        InterfaceType(pointerClass, Nullability.nonNullable, [voidType]);
  }

  @override
  TreeNode visitLibrary(Library node) {
    assert(_currentLibrary == null);
    _currentLibrary = node;
    currentLibraryIndex = referenceFromIndex?.lookupLibrary(node);
    final result = super.visitLibrary(node);
    _currentLibrary = null;
    return result;
  }

  /// Computes the Dart type corresponding to a ffi.[NativeType], returns null
  /// if it is not a valid NativeType.
  ///
  /// [Int8]                               -> [int]
  /// [Int16]                              -> [int]
  /// [Int32]                              -> [int]
  /// [Int64]                              -> [int]
  /// [Uint8]                              -> [int]
  /// [Uint16]                             -> [int]
  /// [Uint32]                             -> [int]
  /// [Uint64]                             -> [int]
  /// [IntPtr]                             -> [int]
  /// [Double]                             -> [double]
  /// [Float]                              -> [double]
  /// [Void]                               -> [void]
  /// [Pointer]<T>                         -> [Pointer]<T>
  /// T extends [Pointer]                  -> T
  /// [Handle]                             -> [Object]
  /// [NativeFunction]<T1 Function(T2, T3) -> S1 Function(S2, S3)
  ///    where DartRepresentationOf(Tn) -> Sn
  DartType? convertNativeTypeToDartType(DartType nativeType,
      {bool allowCompounds = false,
      bool allowHandle = false,
      bool allowInlineArray = false}) {
    if (nativeType is! InterfaceType) {
      return null;
    }
    final InterfaceType native = nativeType;
    final Class nativeClass = native.classNode;
    final NativeType? nativeType_ = getType(nativeClass);

    if (nativeClass == arrayClass) {
      if (!allowInlineArray) {
        return null;
      }
      return nativeType;
    }
    if (hierarchy.isSubclassOf(nativeClass, compoundClass)) {
      if (nativeClass == structClass || nativeClass == unionClass) {
        return null;
      }
      return allowCompounds ? nativeType : null;
    }
    if (nativeType_ == null) {
      return null;
    }
    if (nativeType_ == NativeType.kPointer) {
      return nativeType;
    }
    if (kNativeTypeIntStart.index <= nativeType_.index &&
        nativeType_.index <= kNativeTypeIntEnd.index) {
      return InterfaceType(intClass, Nullability.legacy);
    }
    if (nativeType_ == NativeType.kFloat || nativeType_ == NativeType.kDouble) {
      return InterfaceType(doubleClass, Nullability.legacy);
    }
    if (nativeType_ == NativeType.kVoid) {
      return VoidType();
    }
    if (nativeType_ == NativeType.kHandle && allowHandle) {
      return InterfaceType(objectClass, Nullability.legacy);
    }
    if (nativeType_ != NativeType.kNativeFunction ||
        native.typeArguments[0] is! FunctionType) {
      return null;
    }

    final FunctionType fun = native.typeArguments[0] as FunctionType;
    if (fun.namedParameters.isNotEmpty) return null;
    if (fun.positionalParameters.length != fun.requiredParameterCount) {
      return null;
    }
    if (fun.typeParameters.length != 0) return null;

    final DartType? returnType = convertNativeTypeToDartType(fun.returnType,
        allowCompounds: true, allowHandle: true);
    if (returnType == null) return null;
    final List<DartType> argumentTypes = fun.positionalParameters
        .map((t) =>
            convertNativeTypeToDartType(t,
                allowCompounds: true, allowHandle: true) ??
            dummyDartType)
        .toList();
    if (argumentTypes.contains(dummyDartType)) return null;
    return FunctionType(argumentTypes, returnType, Nullability.legacy);
  }

  /// The [NativeType] corresponding to [c]. Returns `null` for user-defined
  /// structs.
  NativeType? getType(Class c) {
    final int index = nativeTypesClasses.indexOf(c);
    if (index == -1) {
      return null;
    }
    return NativeType.values[index];
  }

  InterfaceType _listOfIntType() => InterfaceType(
      listClass, Nullability.legacy, [coreTypes.intLegacyRawType]);

  ConstantExpression intListConstantExpression(List<int> values) =>
      ConstantExpression(
          ListConstant(coreTypes.intLegacyRawType,
              [for (var v in values) IntConstant(v)]),
          _listOfIntType());

  /// Expression that queries VM internals at runtime to figure out on which ABI
  /// we are.
  Expression runtimeBranchOnLayout(Map<Abi, int> values) {
    return InstanceInvocation(
        InstanceAccessKind.Instance,
        intListConstantExpression([
          values[Abi.wordSize64]!,
          values[Abi.wordSize32Align32]!,
          values[Abi.wordSize32Align64]!
        ]),
        listElementAt.name,
        Arguments([StaticInvocation(abiMethod, Arguments([]))]),
        interfaceTarget: listElementAt,
        functionType: Substitution.fromInterfaceType(_listOfIntType())
            .substituteType(listElementAt.getterType) as FunctionType);
  }

  /// Generates an expression that returns a new `Pointer<dartType>` offset
  /// by [offset] from [pointer].
  ///
  /// Sample output:
  ///
  /// ```
  /// _fromAddress<dartType>(pointer.address + #offset)
  /// ```
  Expression _pointerOffset(Expression pointer, Expression offset,
          DartType dartType, int fileOffset) =>
      StaticInvocation(
          fromAddressInternal,
          Arguments([
            add(
                InstanceGet(
                    InstanceAccessKind.Instance, pointer, addressGetter.name,
                    interfaceTarget: addressGetter,
                    resultType: addressGetter.getterType)
                  ..fileOffset = fileOffset,
                offset)
          ], types: [
            dartType
          ]))
        ..fileOffset = fileOffset;

  /// Generates an expression that returns a new `TypedData` offset
  /// by [offset] from [typedData].
  ///
  /// Sample output:
  ///
  /// ```
  /// TypedData #typedData = typedData;
  /// #typedData.buffer.asInt8List(#typedData.offsetInBytes + offset, length)
  /// ```
  Expression _typedDataOffset(Expression typedData, Expression offset,
      Expression length, int fileOffset) {
    final typedDataVar = VariableDeclaration("#typedData",
        initializer: typedData,
        type: InterfaceType(typedDataClass, Nullability.nonNullable))
      ..fileOffset = fileOffset;
    return Let(
        typedDataVar,
        InstanceInvocation(
            InstanceAccessKind.Instance,
            InstanceGet(InstanceAccessKind.Instance, VariableGet(typedDataVar),
                typedDataBufferGetter.name,
                interfaceTarget: typedDataBufferGetter,
                resultType: typedDataBufferGetter.getterType)
              ..fileOffset = fileOffset,
            byteBufferAsUint8List.name,
            Arguments([
              add(
                  InstanceGet(
                      InstanceAccessKind.Instance,
                      VariableGet(typedDataVar),
                      typedDataOffsetInBytesGetter.name,
                      interfaceTarget: typedDataOffsetInBytesGetter,
                      resultType: typedDataOffsetInBytesGetter.getterType)
                    ..fileOffset = fileOffset,
                  offset),
              length
            ]),
            interfaceTarget: byteBufferAsUint8List,
            functionType: byteBufferAsUint8List.getterType as FunctionType));
  }

  /// Generates an expression that returns a new `TypedDataBase` offset
  /// by [offset] from [typedDataBase].
  ///
  /// If [typedDataBase] is a `Pointer`, returns a `Pointer<dartType>`.
  /// If [typedDataBase] is a `TypedData` returns a `TypedData`.
  ///
  /// Sample output:
  ///
  /// ```
  /// Object #typedDataBase = typedDataBase;
  /// int #offset = offset;
  /// #typedDataBase is Pointer ?
  ///   _pointerOffset<dartType>(#typedDataBase, #offset) :
  ///   _typedDataOffset((#typedDataBase as TypedData), #offset, length)
  /// ```
  Expression typedDataBaseOffset(Expression typedDataBase, Expression offset,
      Expression length, DartType dartType, int fileOffset) {
    final typedDataBaseVar = VariableDeclaration("#typedDataBase",
        initializer: typedDataBase, type: coreTypes.objectNonNullableRawType)
      ..fileOffset = fileOffset;
    final offsetVar = VariableDeclaration("#offset",
        initializer: offset, type: coreTypes.intNonNullableRawType)
      ..fileOffset = fileOffset;
    return BlockExpression(
        Block([typedDataBaseVar, offsetVar]),
        ConditionalExpression(
            IsExpression(VariableGet(typedDataBaseVar),
                InterfaceType(pointerClass, Nullability.nonNullable)),
            _pointerOffset(VariableGet(typedDataBaseVar),
                VariableGet(offsetVar), dartType, fileOffset),
            _typedDataOffset(
                StaticInvocation(
                    unsafeCastMethod,
                    Arguments([
                      VariableGet(typedDataBaseVar)
                    ], types: [
                      InterfaceType(typedDataClass, Nullability.nonNullable)
                    ])),
                VariableGet(offsetVar),
                length,
                fileOffset),
            coreTypes.objectNonNullableRawType));
  }

  bool isPrimitiveType(DartType type) {
    if (type is InvalidType) {
      return false;
    }
    if (type is NullType) {
      return false;
    }
    if (!env.isSubtypeOf(
        type,
        InterfaceType(nativeTypesClasses[NativeType.kNativeType.index],
            Nullability.legacy),
        SubtypeCheckMode.ignoringNullabilities)) {
      return false;
    }
    if (isPointerType(type)) {
      return false;
    }
    if (type is InterfaceType) {
      final nativeType = getType(type.classNode);
      return nativeType != null;
    }
    return false;
  }

  bool isPointerType(DartType type) {
    if (type is InvalidType) {
      return false;
    }
    if (type is NullType) {
      return false;
    }
    return env.isSubtypeOf(
        type,
        InterfaceType(pointerClass, Nullability.legacy, [
          InterfaceType(nativeTypesClasses[NativeType.kNativeType.index],
              Nullability.legacy)
        ]),
        SubtypeCheckMode.ignoringNullabilities);
  }

  bool isArrayType(DartType type) {
    if (type is InvalidType) {
      return false;
    }
    if (type is NullType) {
      return false;
    }
    return env.isSubtypeOf(
        type,
        InterfaceType(arrayClass, Nullability.legacy, [
          InterfaceType(nativeTypesClasses[NativeType.kNativeType.index],
              Nullability.legacy)
        ]),
        SubtypeCheckMode.ignoringNullabilities);
  }

  /// Returns the single element type nested type argument of `Array`.
  ///
  /// `Array<Array<Array<Int8>>>` -> `Int8`.
  DartType arraySingleElementType(DartType dartType) {
    InterfaceType elementType = dartType as InterfaceType;
    while (elementType.classNode == arrayClass) {
      elementType = elementType.typeArguments[0] as InterfaceType;
    }
    return elementType;
  }

  /// Returns the number of dimensions of `Array`.
  ///
  /// `Array<Array<Array<Int8>>>` -> 3.
  int arrayDimensions(DartType dartType) {
    InterfaceType elementType = dartType as InterfaceType;
    int dimensions = 0;
    while (elementType.classNode == arrayClass) {
      elementType = elementType.typeArguments[0] as InterfaceType;
      dimensions++;
    }
    return dimensions;
  }

  bool isCompoundSubtype(DartType type) {
    if (type is InvalidType) {
      return false;
    }
    if (type is NullType) {
      return false;
    }
    if (type is InterfaceType) {
      if (type.classNode == structClass || type.classNode == unionClass) {
        return false;
      }
    }
    return env.isSubtypeOf(
        type,
        InterfaceType(compoundClass, Nullability.legacy),
        SubtypeCheckMode.ignoringNullabilities);
  }

  Expression getCompoundTypedDataBaseField(
      Expression receiver, int fileOffset) {
    return InstanceGet(
        InstanceAccessKind.Instance, receiver, compoundTypedDataBaseField.name,
        interfaceTarget: compoundTypedDataBaseField,
        resultType: compoundTypedDataBaseField.type)
      ..fileOffset = fileOffset;
  }

  Expression getArrayTypedDataBaseField(Expression receiver,
      [int fileOffset = TreeNode.noOffset]) {
    return InstanceGet(
        InstanceAccessKind.Instance, receiver, arrayTypedDataBaseField.name,
        interfaceTarget: arrayTypedDataBaseField,
        resultType: arrayTypedDataBaseField.type)
      ..fileOffset = fileOffset;
  }

  Expression add(Expression a, Expression b) {
    return InstanceInvocation(
        InstanceAccessKind.Instance, a, numAddition.name, Arguments([b]),
        interfaceTarget: numAddition,
        functionType: numAddition.getterType as FunctionType);
  }

  Expression multiply(Expression a, Expression b) {
    return InstanceInvocation(
        InstanceAccessKind.Instance, a, numMultiplication.name, Arguments([b]),
        interfaceTarget: numMultiplication,
        functionType: numMultiplication.getterType as FunctionType);
  }
}

/// Checks if any library depends on dart:ffi.
bool importsFfi(Component component, List<Library> libraries) {
  Set<Library> allLibs = {...component.libraries, ...libraries};
  final Uri dartFfiUri = Uri.parse("dart:ffi");
  for (Library lib in allLibs) {
    for (LibraryDependency dependency in lib.dependencies) {
      if (dependency.targetLibrary.importUri == dartFfiUri) {
        return true;
      }
    }
  }
  return false;
}
