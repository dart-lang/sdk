// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains logic which is shared between the ffi_definition and
// ffi_use_site transformers.

library vm.transformations.ffi;

// This imports 'codes/cfe_codes.dart' instead of 'api_prototype/codes.dart' to
// avoid cyclic dependency between `package:vm/modular` and `package:front_end`.
import 'package:front_end/src/codes/cfe_codes.dart'
    show
        messageFfiLeafCallMustNotReturnHandle,
        messageFfiLeafCallMustNotTakeHandle,
        messageFfiVariableLengthArrayNotLast,
        messageNonPositiveArrayDimensions,
        templateFfiSizeAnnotation,
        templateFfiSizeAnnotationDimensions,
        templateFfiTypeInvalid,
        templateFfiTypeMismatch;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart'
    show TypeEnvironment, SubtypeCheckMode;
import 'package:kernel/util/graph.dart' as kernelGraph;

import 'abi.dart';
import 'native_type_cfe.dart';

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
  kUint64,
  kFloat,
  kDouble,
  kVoid,
  kOpaque,
  kStruct,
  kHandle,
  kBool,
}

const Set<NativeType> nativeIntTypesFixedSize = <NativeType>{
  NativeType.kInt8,
  NativeType.kInt16,
  NativeType.kInt32,
  NativeType.kInt64,
  NativeType.kUint8,
  NativeType.kUint16,
  NativeType.kUint32,
  NativeType.kUint64,
};

/// The [NativeType] class names.
const Map<NativeType, String> nativeTypeClassNames = <NativeType, String>{
  NativeType.kNativeType: 'NativeType',
  NativeType.kNativeInteger: '_NativeInteger',
  NativeType.kNativeDouble: '_NativeDouble',
  NativeType.kPointer: 'Pointer',
  NativeType.kNativeFunction: 'NativeFunction',
  NativeType.kInt8: 'Int8',
  NativeType.kInt16: 'Int16',
  NativeType.kInt32: 'Int32',
  NativeType.kInt64: 'Int64',
  NativeType.kUint8: 'Uint8',
  NativeType.kUint16: 'Uint16',
  NativeType.kUint32: 'Uint32',
  NativeType.kUint64: 'Uint64',
  NativeType.kFloat: 'Float',
  NativeType.kDouble: 'Double',
  NativeType.kVoid: 'Void',
  NativeType.kOpaque: 'Opaque',
  NativeType.kStruct: 'Struct',
  NativeType.kHandle: 'Handle',
  NativeType.kBool: 'Bool',
};

const int UNKNOWN = 0;
const int WORD_SIZE = -1;

/// The [NativeType] sizes in bytes.
const Map<NativeType, int> nativeTypeSizes = <NativeType, int>{
  NativeType.kNativeType: UNKNOWN,
  NativeType.kNativeInteger: UNKNOWN,
  NativeType.kNativeDouble: UNKNOWN,
  NativeType.kPointer: WORD_SIZE,
  NativeType.kNativeFunction: UNKNOWN,
  NativeType.kInt8: 1,
  NativeType.kInt16: 2,
  NativeType.kInt32: 4,
  NativeType.kInt64: 8,
  NativeType.kUint8: 1,
  NativeType.kUint16: 2,
  NativeType.kUint32: 4,
  NativeType.kUint64: 8,
  NativeType.kFloat: 4,
  NativeType.kDouble: 8,
  NativeType.kVoid: UNKNOWN,
  NativeType.kOpaque: UNKNOWN,
  NativeType.kStruct: UNKNOWN,
  NativeType.kHandle: WORD_SIZE,
  NativeType.kBool: 1,
};

/// Load and store are rewired to their static type for these types.
const List<NativeType> optimizedTypes = [
  NativeType.kBool,
  NativeType.kInt8,
  NativeType.kInt16,
  NativeType.kInt32,
  NativeType.kInt64,
  NativeType.kUint8,
  NativeType.kUint16,
  NativeType.kUint32,
  NativeType.kUint64,
  NativeType.kFloat,
  NativeType.kDouble,
  NativeType.kPointer,
];

const List<NativeType> unalignedLoadsStores = [
  NativeType.kFloat,
  NativeType.kDouble,
];

const List<String> addressOfExtensionsTypedData = [
  'Float32List',
  'Float64List',
  'Int16List',
  'Int32List',
  'Int64List',
  'Int8List',
  'Uint16List',
  'Uint32List',
  'Uint64List',
  'Uint8List',
];

const List<String> addressOfExtensionsCompound = [
  'Array',
  'Struct',
  'Union',
];

const List<String> addressOfExtensionsPrimitive = [
  'Bool',
  'Double',
  'Int',
];

const List<String> addressOfExtensions = [
  ...addressOfExtensionsCompound,
  ...addressOfExtensionsPrimitive,
  ...addressOfExtensionsTypedData,
];

enum FfiTypeCheckDirection {
  // Passing a value from native code to Dart code.
  nativeToDart,

  // Passing a value from Dart code to native code.
  dartToNative,
}

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
  final Class boolClass;
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
  final Procedure objectEquals;
  final Procedure stateErrorThrowNewFunction;

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
  final Field arraySizeVariableLengthField;
  final Class pointerClass;
  final Class compoundClass;
  final Class structClass;
  final Class unionClass;
  final Class abiSpecificIntegerClass;
  final Class abiSpecificIntegerMappingClass;
  final Class varArgsClass;
  final Class nativeFieldWrapperClass1Class;
  final Class ffiStructLayoutClass;
  final Field ffiStructLayoutTypesField;
  final Field ffiStructLayoutPackingField;
  final Class ffiAbiSpecificMappingClass;
  final Field ffiAbiSpecificMappingNativeTypesField;
  final Class ffiInlineArrayClass;
  final Field ffiInlineArrayElementTypeField;
  final Field ffiInlineArrayLengthField;
  final Class packedClass;
  final Field packedMemberAlignmentField;
  final Procedure allocateMethod;
  final Procedure allocatorAllocateMethod;
  final Procedure castMethod;
  final Procedure offsetByMethod;
  final Procedure addressGetter;
  final Procedure structPointerGetRef;
  final Procedure structPointerSetRef;
  final Procedure structPointerGetElemAt;
  final Procedure structPointerSetElemAt;
  final Procedure structPointerElementAt;
  final Procedure structPointerPlusOperator;
  final Procedure structPointerMinusOperator;
  final Procedure structPointerElementAtTearoff;
  final Procedure unionPointerGetRef;
  final Procedure unionPointerSetRef;
  final Procedure unionPointerGetElemAt;
  final Procedure unionPointerSetElemAt;
  final Procedure unionPointerElementAt;
  final Procedure unionPointerPlusOperator;
  final Procedure unionPointerMinusOperator;
  final Procedure unionPointerElementAtTearoff;
  final Procedure structArrayElemAt;
  final Procedure unionArrayElemAt;
  final Procedure arrayArrayElemAt;
  final Procedure arrayArrayAssignAt;
  final Procedure abiSpecificIntegerPointerGetValue;
  final Procedure abiSpecificIntegerPointerSetValue;
  final Procedure abiSpecificIntegerPointerElemAt;
  final Procedure abiSpecificIntegerPointerSetElemAt;
  final Procedure abiSpecificIntegerPointerElementAt;
  final Procedure abiSpecificIntegerPointerPlusOperator;
  final Procedure abiSpecificIntegerPointerMinusOperator;
  final Procedure abiSpecificIntegerPointerElementAtTearoff;
  final Procedure abiSpecificIntegerArrayElemAt;
  final Procedure abiSpecificIntegerArraySetElemAt;
  final Procedure asFunctionMethod;
  final Procedure ffiCallMethod;
  final Procedure sizeOfMethod;
  final Procedure lookupFunctionMethod;
  final Procedure fromFunctionMethod;
  final Field compoundTypedDataBaseField;
  final Field compoundOffsetInBytesField;
  final Field arraySizeField;
  final Field arrayNestedDimensionsField;
  final Procedure arrayCheckIndex;
  final Procedure arrayNestedDimensionsFlattened;
  final Procedure arrayNestedDimensionsFirst;
  final Procedure arrayNestedDimensionsRest;
  final Procedure structCreate;
  final Procedure unionCreate;
  final Constructor compoundFromTypedDataBase;
  final Constructor structFromTypedDataBase;
  final Constructor unionFromTypedDataBase;
  final Constructor structFromTypedData;
  final Constructor unionFromTypedData;
  final Constructor arrayConstructor;
  final Procedure fromAddressInternal;
  final Procedure libraryLookupMethod;
  final Procedure abiMethod;
  final Procedure createNativeCallableListenerProcedure;
  final Procedure nativeCallbackFunctionProcedure;
  final Procedure nativeAsyncCallbackFunctionProcedure;
  final Procedure createNativeCallableIsolateLocalProcedure;
  final Procedure nativeIsolateLocalCallbackFunctionProcedure;
  final Map<NativeType, Procedure> loadMethods;
  final Map<NativeType, Procedure> loadUnalignedMethods;
  final Map<NativeType, Procedure> storeMethods;
  final Map<NativeType, Procedure> storeUnalignedMethods;
  final Procedure loadAbiSpecificIntMethod;
  final Procedure loadAbiSpecificIntAtIndexMethod;
  final Procedure storeAbiSpecificIntMethod;
  final Procedure storeAbiSpecificIntAtIndexMethod;
  final Procedure abiCurrentMethod;
  final Map<Constant, Abi> constantAbis;
  final Class intptrClass;
  late AbiSpecificNativeTypeCfe intptrNativeTypeCfe;
  final Procedure memCopy;
  final Procedure allocationTearoff;
  final Procedure asFunctionTearoff;
  final Procedure lookupFunctionTearoff;
  final Procedure getNativeFieldFunction;
  final Class finalizableClass;
  final Procedure reachabilityFenceFunction;
  final Procedure checkAbiSpecificIntegerMappingFunction;
  final Class rawRecvPortClass;
  final Class nativeCallableClass;
  final Procedure nativeCallableIsolateLocalConstructor;
  final Constructor nativeCallablePrivateIsolateLocalConstructor;
  final Procedure nativeCallableListenerConstructor;
  final Constructor nativeCallablePrivateListenerConstructor;
  final Field nativeCallablePortField;
  final Field nativeCallablePointerField;
  final Procedure nativeAddressOf;
  final Procedure nativePrivateAddressOf;
  final List<Procedure> addressOfMethods;
  final List<Procedure> addressOfMethodsCompound;
  final List<Procedure> addressOfMethodsPrimitive;
  final List<Procedure> addressOfMethodsTypedData;
  final Class ffiCallClass;
  final Field ffiCallIsLeafField;
  final Field nativeIsLeafField;

  late final InterfaceType nativeFieldWrapperClass1Type;
  late final InterfaceType voidType;
  late final InterfaceType pointerVoidType;
  // The instantiated to bounds type argument for the Pointer class.
  late final InterfaceType nativeTypeType;
  // The Pointer type when instantiated to bounds.
  late final InterfaceType pointerNativeTypeType;
  late final InterfaceType compoundType;

  /// Classes corresponding to [NativeType], indexed by [NativeType].
  final Map<NativeType, Class> nativeTypesClasses;
  final Map<Class, NativeType> classNativeTypes;

  Library? _currentLibrary;
  Library get currentLibrary => _currentLibrary!;

  IndexedLibrary? currentLibraryIndex;

  FfiTransformer(this.index, this.coreTypes, this.hierarchy,
      this.diagnosticReporter, this.referenceFromIndex)
      : env = TypeEnvironment(coreTypes, hierarchy),
        objectClass = coreTypes.objectClass,
        intClass = coreTypes.intClass,
        doubleClass = coreTypes.doubleClass,
        boolClass = coreTypes.boolClass,
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
        objectEquals =
            coreTypes.index.getProcedure('dart:core', 'Object', '=='),
        stateErrorThrowNewFunction = coreTypes.index
            .getProcedure('dart:core', 'StateError', '_throwNew'),
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
        arraySizeVariableLengthField =
            index.getField('dart:ffi', '_ArraySize', 'variableLength'),
        pointerClass = index.getClass('dart:ffi', 'Pointer'),
        compoundClass = index.getClass('dart:ffi', '_Compound'),
        structClass = index.getClass('dart:ffi', 'Struct'),
        unionClass = index.getClass('dart:ffi', 'Union'),
        abiSpecificIntegerClass =
            index.getClass('dart:ffi', 'AbiSpecificInteger'),
        abiSpecificIntegerMappingClass =
            index.getClass('dart:ffi', 'AbiSpecificIntegerMapping'),
        varArgsClass = index.getClass('dart:ffi', 'VarArgs'),
        nativeFieldWrapperClass1Class =
            index.getClass('dart:nativewrappers', 'NativeFieldWrapperClass1'),
        ffiStructLayoutClass = index.getClass('dart:ffi', '_FfiStructLayout'),
        ffiStructLayoutTypesField =
            index.getField('dart:ffi', '_FfiStructLayout', 'fieldTypes'),
        ffiStructLayoutPackingField =
            index.getField('dart:ffi', '_FfiStructLayout', 'packing'),
        ffiAbiSpecificMappingClass =
            index.getClass('dart:ffi', '_FfiAbiSpecificMapping'),
        ffiAbiSpecificMappingNativeTypesField =
            index.getField('dart:ffi', '_FfiAbiSpecificMapping', 'nativeTypes'),
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
        addressGetter =
            index.getProcedure('dart:ffi', 'Pointer', 'get:address'),
        compoundTypedDataBaseField =
            index.getField('dart:ffi', '_Compound', '_typedDataBase'),
        compoundOffsetInBytesField =
            index.getField('dart:ffi', '_Compound', '_offsetInBytes'),
        arraySizeField = index.getField('dart:ffi', 'Array', '_size'),
        arrayNestedDimensionsField =
            index.getField('dart:ffi', 'Array', '_nestedDimensions'),
        arrayCheckIndex =
            index.getProcedure('dart:ffi', 'Array', '_checkIndex'),
        arrayNestedDimensionsFlattened = index.getProcedure(
            'dart:ffi', 'Array', 'get:_nestedDimensionsFlattened'),
        arrayNestedDimensionsFirst = index.getProcedure(
            'dart:ffi', 'Array', 'get:_nestedDimensionsFirst'),
        arrayNestedDimensionsRest = index.getProcedure(
            'dart:ffi', 'Array', 'get:_nestedDimensionsRest'),
        structCreate = index.getProcedure('dart:ffi', 'Struct', 'create'),
        unionCreate = index.getProcedure('dart:ffi', 'Union', 'create'),
        compoundFromTypedDataBase =
            index.getConstructor('dart:ffi', '_Compound', '_fromTypedDataBase'),
        structFromTypedDataBase =
            index.getConstructor('dart:ffi', 'Struct', '_fromTypedDataBase'),
        unionFromTypedDataBase =
            index.getConstructor('dart:ffi', 'Union', '_fromTypedDataBase'),
        structFromTypedData =
            index.getConstructor('dart:ffi', 'Struct', '_fromTypedData'),
        unionFromTypedData =
            index.getConstructor('dart:ffi', 'Union', '_fromTypedData'),
        arrayConstructor = index.getConstructor('dart:ffi', 'Array', '_'),
        fromAddressInternal =
            index.getTopLevelProcedure('dart:ffi', '_fromAddress'),
        structPointerGetRef =
            index.getProcedure('dart:ffi', 'StructPointer', 'get:ref'),
        structPointerSetRef =
            index.getProcedure('dart:ffi', 'StructPointer', 'set:ref'),
        structPointerGetElemAt =
            index.getProcedure('dart:ffi', 'StructPointer', '[]'),
        structPointerSetElemAt =
            index.getProcedure('dart:ffi', 'StructPointer', '[]='),
        structPointerElementAt =
            index.getProcedure('dart:ffi', 'StructPointer', 'elementAt'),
        structPointerPlusOperator =
            index.getProcedure('dart:ffi', 'StructPointer', '+'),
        structPointerMinusOperator =
            index.getProcedure('dart:ffi', 'StructPointer', '-'),
        structPointerElementAtTearoff = index.getProcedure('dart:ffi',
            'StructPointer', LibraryIndex.tearoffPrefix + 'elementAt'),
        unionPointerGetRef =
            index.getProcedure('dart:ffi', 'UnionPointer', 'get:ref'),
        unionPointerSetRef =
            index.getProcedure('dart:ffi', 'UnionPointer', 'set:ref'),
        unionPointerGetElemAt =
            index.getProcedure('dart:ffi', 'UnionPointer', '[]'),
        unionPointerSetElemAt =
            index.getProcedure('dart:ffi', 'UnionPointer', '[]='),
        unionPointerElementAt =
            index.getProcedure('dart:ffi', 'UnionPointer', 'elementAt'),
        unionPointerPlusOperator =
            index.getProcedure('dart:ffi', 'UnionPointer', '+'),
        unionPointerMinusOperator =
            index.getProcedure('dart:ffi', 'UnionPointer', '-'),
        unionPointerElementAtTearoff = index.getProcedure('dart:ffi',
            'UnionPointer', LibraryIndex.tearoffPrefix + 'elementAt'),
        structArrayElemAt = index.getProcedure('dart:ffi', 'StructArray', '[]'),
        unionArrayElemAt = index.getProcedure('dart:ffi', 'UnionArray', '[]'),
        arrayArrayElemAt = index.getProcedure('dart:ffi', 'ArrayArray', '[]'),
        arrayArrayAssignAt =
            index.getProcedure('dart:ffi', 'ArrayArray', '[]='),
        abiSpecificIntegerPointerGetValue = index.getProcedure(
            'dart:ffi', 'AbiSpecificIntegerPointer', 'get:value'),
        abiSpecificIntegerPointerSetValue = index.getProcedure(
            'dart:ffi', 'AbiSpecificIntegerPointer', 'set:value'),
        abiSpecificIntegerPointerElemAt =
            index.getProcedure('dart:ffi', 'AbiSpecificIntegerPointer', '[]'),
        abiSpecificIntegerPointerSetElemAt =
            index.getProcedure('dart:ffi', 'AbiSpecificIntegerPointer', '[]='),
        abiSpecificIntegerPointerElementAt = index.getProcedure(
            'dart:ffi', 'AbiSpecificIntegerPointer', 'elementAt'),
        abiSpecificIntegerPointerPlusOperator =
            index.getProcedure('dart:ffi', 'AbiSpecificIntegerPointer', '+'),
        abiSpecificIntegerPointerMinusOperator =
            index.getProcedure('dart:ffi', 'AbiSpecificIntegerPointer', '-'),
        abiSpecificIntegerPointerElementAtTearoff = index.getProcedure(
            'dart:ffi',
            'AbiSpecificIntegerPointer',
            LibraryIndex.tearoffPrefix + 'elementAt'),
        abiSpecificIntegerArrayElemAt =
            index.getProcedure('dart:ffi', 'AbiSpecificIntegerArray', '[]'),
        abiSpecificIntegerArraySetElemAt =
            index.getProcedure('dart:ffi', 'AbiSpecificIntegerArray', '[]='),
        asFunctionMethod = index.getProcedure(
            'dart:ffi', 'NativeFunctionPointer', 'asFunction'),
        ffiCallMethod = index.getTopLevelProcedure('dart:ffi', '_ffiCall'),
        sizeOfMethod = index.getTopLevelProcedure('dart:ffi', 'sizeOf'),
        lookupFunctionMethod = index.getProcedure(
            'dart:ffi', 'DynamicLibraryExtension', 'lookupFunction'),
        fromFunctionMethod =
            index.getProcedure('dart:ffi', 'Pointer', 'fromFunction'),
        libraryLookupMethod =
            index.getProcedure('dart:ffi', 'DynamicLibrary', 'lookup'),
        abiMethod = index.getTopLevelProcedure('dart:ffi', '_abi'),
        createNativeCallableListenerProcedure = index.getTopLevelProcedure(
            'dart:ffi', '_createNativeCallableListener'),
        createNativeCallableIsolateLocalProcedure = index.getTopLevelProcedure(
            'dart:ffi', '_createNativeCallableIsolateLocal'),
        nativeCallbackFunctionProcedure =
            index.getTopLevelProcedure('dart:ffi', '_nativeCallbackFunction'),
        nativeAsyncCallbackFunctionProcedure = index.getTopLevelProcedure(
            'dart:ffi', '_nativeAsyncCallbackFunction'),
        nativeIsolateLocalCallbackFunctionProcedure =
            index.getTopLevelProcedure(
                'dart:ffi', '_nativeIsolateLocalCallbackFunction'),
        nativeTypesClasses = nativeTypeClassNames.map((nativeType, name) =>
            MapEntry(nativeType, index.getClass('dart:ffi', name))),
        classNativeTypes = nativeTypeClassNames.map((nativeType, name) =>
            MapEntry(index.getClass('dart:ffi', name), nativeType)),
        loadMethods = Map.fromIterable(optimizedTypes, value: (t) {
          final name = nativeTypeClassNames[t];
          return index.getTopLevelProcedure('dart:ffi', "_load$name");
        }),
        loadUnalignedMethods =
            Map.fromIterable(unalignedLoadsStores, value: (t) {
          final name = nativeTypeClassNames[t];
          return index.getTopLevelProcedure(
              'dart:ffi', "_load${name}Unaligned");
        }),
        storeMethods = Map.fromIterable(optimizedTypes, value: (t) {
          final name = nativeTypeClassNames[t];
          return index.getTopLevelProcedure('dart:ffi', "_store$name");
        }),
        storeUnalignedMethods =
            Map.fromIterable(unalignedLoadsStores, value: (t) {
          final name = nativeTypeClassNames[t];
          return index.getTopLevelProcedure(
              'dart:ffi', "_store${name}Unaligned");
        }),
        loadAbiSpecificIntMethod =
            index.getTopLevelProcedure('dart:ffi', "_loadAbiSpecificInt"),
        loadAbiSpecificIntAtIndexMethod = index.getTopLevelProcedure(
            'dart:ffi', "_loadAbiSpecificIntAtIndex"),
        storeAbiSpecificIntMethod =
            index.getTopLevelProcedure('dart:ffi', "_storeAbiSpecificInt"),
        storeAbiSpecificIntAtIndexMethod = index.getTopLevelProcedure(
            'dart:ffi', "_storeAbiSpecificIntAtIndex"),
        abiCurrentMethod = index.getProcedure('dart:ffi', 'Abi', 'current'),
        constantAbis = abiNames.map((abi, name) => MapEntry(
            (index.getField('dart:ffi', 'Abi', name).initializer
                    as ConstantExpression)
                .constant,
            abi)),
        intptrClass = index.getClass('dart:ffi', 'IntPtr'),
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
        finalizableClass = index.getClass('dart:ffi', 'Finalizable'),
        reachabilityFenceFunction =
            index.getTopLevelProcedure('dart:_internal', 'reachabilityFence'),
        checkAbiSpecificIntegerMappingFunction = index.getTopLevelProcedure(
            'dart:ffi', "_checkAbiSpecificIntegerMapping"),
        rawRecvPortClass = index.getClass('dart:isolate', 'RawReceivePort'),
        nativeCallableClass = index.getClass('dart:ffi', 'NativeCallable'),
        nativeCallableIsolateLocalConstructor =
            index.getProcedure('dart:ffi', 'NativeCallable', 'isolateLocal'),
        nativeCallablePrivateIsolateLocalConstructor =
            index.getConstructor('dart:ffi', '_NativeCallableIsolateLocal', ''),
        nativeCallableListenerConstructor =
            index.getProcedure('dart:ffi', 'NativeCallable', 'listener'),
        nativeCallablePrivateListenerConstructor =
            index.getConstructor('dart:ffi', '_NativeCallableListener', ''),
        nativeCallablePortField =
            index.getField('dart:ffi', '_NativeCallableListener', '_port'),
        nativeCallablePointerField =
            index.getField('dart:ffi', '_NativeCallableBase', '_pointer'),
        nativeAddressOf =
            index.getMember('dart:ffi', 'Native', 'addressOf') as Procedure,
        nativePrivateAddressOf =
            index.getMember('dart:ffi', 'Native', '_addressOf') as Procedure,
        addressOfMethods = [
          for (final name in addressOfExtensions)
            index.getProcedure('dart:ffi', '${name}Address', 'get:address'),
        ],
        addressOfMethodsPrimitive = [
          for (final name in addressOfExtensionsPrimitive)
            index.getProcedure('dart:ffi', '${name}Address', 'get:address'),
        ],
        addressOfMethodsCompound = [
          for (final name in addressOfExtensionsCompound)
            index.getProcedure('dart:ffi', '${name}Address', 'get:address'),
        ],
        addressOfMethodsTypedData = [
          for (final name in addressOfExtensionsTypedData)
            index.getProcedure('dart:ffi', '${name}Address', 'get:address'),
        ],
        ffiCallClass = index.getClass('dart:ffi', '_FfiCall'),
        ffiCallIsLeafField = index.getField('dart:ffi', '_FfiCall', 'isLeaf'),
        nativeIsLeafField = index.getField('dart:ffi', 'Native', 'isLeaf') {
    nativeFieldWrapperClass1Type = nativeFieldWrapperClass1Class.getThisType(
        coreTypes, Nullability.nonNullable);
    voidType = nativeTypesClasses[NativeType.kVoid]!
        .getThisType(coreTypes, Nullability.nonNullable);
    pointerVoidType =
        InterfaceType(pointerClass, Nullability.nonNullable, [voidType]);
    nativeTypeType = nativeTypesClasses[NativeType.kNativeType]!
        .getThisType(coreTypes, Nullability.nonNullable);
    pointerNativeTypeType =
        InterfaceType(pointerClass, Nullability.nonNullable, [nativeTypeType]);
    intptrNativeTypeCfe =
        NativeTypeCfe(this, InterfaceType(intptrClass, Nullability.nonNullable))
            as AbiSpecificNativeTypeCfe;
    compoundType = InterfaceType(
      compoundClass,
      Nullability.nonNullable,
      const <DartType>[],
    );
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
  /// T extends [AbiSpecificInteger]       -> [int]
  /// [Double]                             -> [double]
  /// [Float]                              -> [double]
  /// [Bool]                               -> [bool]
  /// [Void]                               -> [void]
  /// [Pointer]<T>                         -> [Pointer]<T>
  /// T extends [Struct]                   -> T
  /// T extends [Union]                    -> T
  /// [Handle]                             -> [Object]
  /// [NativeFunction]<T1 Function(T2, T3) -> S1 Function(S2, S3)
  ///    where DartRepresentationOf(Tn) -> Sn
  DartType? convertNativeTypeToDartType(
    DartType nativeType, {
    bool allowStructAndUnion = false,
    bool allowHandle = false,
    bool allowInlineArray = false,
    bool allowVoid = false,
  }) {
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
      final nested = convertNativeTypeToDartType(
        nativeType.typeArguments.single,
        allowInlineArray: true,
        allowStructAndUnion: true,
      );
      if (nested == null) {
        return null;
      }
      return nativeType;
    }
    if (hierarchy.isSubclassOf(nativeClass, abiSpecificIntegerClass)) {
      if (nativeClass == abiSpecificIntegerClass) {
        return null;
      }
      return coreTypes.intNonNullableRawType;
    }
    if (hierarchy.isSubclassOf(nativeClass, compoundClass)) {
      if (nativeClass == structClass || nativeClass == unionClass) {
        return null;
      }
      return allowStructAndUnion ? nativeType : null;
    }
    if (nativeType_ == null) {
      return null;
    }
    if (nativeType_ == NativeType.kPointer) {
      return nativeType;
    }
    if (nativeIntTypesFixedSize.contains(nativeType_)) {
      return coreTypes.intNonNullableRawType;
    }
    if (nativeType_ == NativeType.kFloat || nativeType_ == NativeType.kDouble) {
      return coreTypes.doubleNonNullableRawType;
    }
    if (nativeType_ == NativeType.kBool) {
      return coreTypes.boolNonNullableRawType;
    }
    if (nativeType_ == NativeType.kVoid) {
      if (!allowVoid) {
        return null;
      }
      return VoidType();
    }
    if (nativeType_ == NativeType.kHandle && allowHandle) {
      return coreTypes.objectNonNullableRawType;
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
    if (fun.typeParameters.isNotEmpty) return null;

    final DartType? returnType = convertNativeTypeToDartType(
      fun.returnType,
      allowStructAndUnion: true,
      allowHandle: true,
      allowVoid: true,
    );
    if (returnType == null) return null;
    final argumentTypes = <DartType>[];
    for (final paramDartType in flattenVarargs(fun).positionalParameters) {
      argumentTypes.add(
        convertNativeTypeToDartType(
              paramDartType,
              allowStructAndUnion: true,
              allowHandle: true,
            ) ??
            dummyDartType,
      );
    }
    if (argumentTypes.contains(dummyDartType)) return null;
    return FunctionType(argumentTypes, returnType, Nullability.nonNullable);
  }

  /// Finds a native type for the given [dartType] if there is only one possible
  /// native type.
  ///
  /// This is impossible for some types (like [int] which needs a specific ffi
  /// type to denote the width in C). This method returns `null` for those
  /// types.
  ///
  /// For types where this returns a non-null value, this is the inverse of
  /// [convertNativeTypeToDartType].
  DartType? convertDartTypeToNativeType(DartType dartType) {
    if (isPointerType(dartType) ||
        isStructOrUnionSubtype(dartType) ||
        isArrayType(dartType)) {
      return dartType;
    } else {
      return null;
    }
  }

  /// Removes the VarArgs from a DartType list.
  ///
  /// ```
  /// [Int8, Int8] -> [Int8, Int8]
  /// [Int8, VarArgs<(Int8,)>] -> [Int8, Int8]
  /// [Int8, VarArgs<(Int8, Int8)>] -> [Int8, Int8, Int8]
  /// ```
  FunctionType flattenVarargs(FunctionType functionTypeWithPossibleVarArgs) {
    final positionalParameters =
        functionTypeWithPossibleVarArgs.positionalParameters;
    if (positionalParameters.isEmpty) {
      return functionTypeWithPossibleVarArgs;
    }
    final lastPositionalParameter = positionalParameters.last;
    if (lastPositionalParameter is InterfaceType &&
        lastPositionalParameter.classNode == varArgsClass) {
      final typeArgument = lastPositionalParameter.typeArguments.single;
      if (typeArgument is! RecordType) {
        return functionTypeWithPossibleVarArgs;
      }

      if (typeArgument.named.isNotEmpty) {
        // Named record fields are not supported.
        return functionTypeWithPossibleVarArgs;
      }

      final positionalParameters = [
        ...functionTypeWithPossibleVarArgs.positionalParameters.sublist(
            0, functionTypeWithPossibleVarArgs.positionalParameters.length - 1),
        for (final paramDartType in typeArgument.positional) paramDartType,
      ];
      return FunctionType(
        positionalParameters,
        functionTypeWithPossibleVarArgs.returnType,
        functionTypeWithPossibleVarArgs.declaredNullability,
        namedParameters: functionTypeWithPossibleVarArgs.namedParameters,
        typeParameters: functionTypeWithPossibleVarArgs.typeParameters,
        requiredParameterCount: positionalParameters.length,
      );
    }
    return functionTypeWithPossibleVarArgs;
  }

  /// The [NativeType] corresponding to [c]. Returns `null` for user-defined
  /// structs.
  NativeType? getType(Class c) {
    return classNativeTypes[c];
  }

  InterfaceType _listOfIntType(Nullability elementNullability) => InterfaceType(
      listClass,
      Nullability.nonNullable,
      [coreTypes.intRawType(elementNullability)]);

  ConstantExpression intListConstantExpression(
          List<int?> values, Nullability elementNullability) =>
      ConstantExpression(
          ListConstant(coreTypes.intRawType(elementNullability), [
            for (var v in values)
              if (v != null) IntConstant(v) else NullConstant()
          ]),
          _listOfIntType(elementNullability));

  /// Expression that queries VM internals at runtime to figure out on which ABI
  /// we are.
  Expression runtimeBranchOnLayout(Map<Abi, int?> values) {
    final elementNullability =
        values.isPartial ? Nullability.nullable : Nullability.nonNullable;
    final result = InstanceInvocation(
        InstanceAccessKind.Instance,
        intListConstantExpression([
          for (final abi in Abi.values) values[abi],
        ], elementNullability),
        listElementAt.name,
        Arguments([StaticInvocation(abiMethod, Arguments([]))]),
        interfaceTarget: listElementAt,
        functionType:
            Substitution.fromInterfaceType(_listOfIntType(elementNullability))
                .substituteType(listElementAt.getterType) as FunctionType);
    if (values.isPartial) {
      return checkAbiSpecificIntegerMapping(result);
    }
    return result;
  }

  Expression checkAbiSpecificIntegerMapping(Expression nullableExpression) =>
      StaticInvocation(
        checkAbiSpecificIntegerMappingFunction,
        Arguments(
          [nullableExpression],
          types: [InterfaceType(intClass, Nullability.nonNullable)],
        ),
      );

  bool isPrimitiveType(DartType type) {
    if (type is InvalidType) {
      return false;
    }
    if (type is NullType) {
      return false;
    }
    if (!env.isSubtypeOf(
        type, nativeTypeType, SubtypeCheckMode.ignoringNullabilities)) {
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
        type, pointerNativeTypeType, SubtypeCheckMode.ignoringNullabilities);
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
        InterfaceType(arrayClass, Nullability.nonNullable, [nativeTypeType]),
        SubtypeCheckMode.ignoringNullabilities);
  }

  /// Returns the single element type nested type argument of `Array`.
  ///
  /// `Array<Array<Array<Int8>>>` -> `Int8`.
  ///
  /// `Array<Array<Array<Unknown>>>` -> [InvalidType].
  DartType arraySingleElementType(DartType dartType) {
    if (dartType is! InterfaceType) {
      return InvalidType();
    }
    InterfaceType elementType = dartType;
    while (elementType.classNode == arrayClass) {
      final elementTypeAny = elementType.typeArguments[0];
      if (elementTypeAny is! InterfaceType) {
        return InvalidType();
      }
      elementType = elementTypeAny;
    }
    return elementType;
  }

  /// Ensures that [node] has an `Array` annotation with valid dimensions
  /// matching its [type].
  ///
  /// Throws an [FfiStaticTypeError] otherwise.
  List<int> ensureArraySizeAnnotation(
    Member node,
    DartType type,
    bool allowVariableLength,
  ) {
    final sizeAnnotations = getArraySizeAnnotations(node);
    List<int> dimensions;
    bool variableLength;
    var success = true;

    if (sizeAnnotations.length == 1) {
      final singleElementType = arraySingleElementType(type);
      if (singleElementType is! InterfaceType) {
        assert(singleElementType is InvalidType);
        throw FfiStaticTypeError();
      } else {
        dimensions = sizeAnnotations.single.$1;
        variableLength = sizeAnnotations.single.$2;
        if (arrayDimensions(type) != dimensions.length) {
          diagnosticReporter.report(
              templateFfiSizeAnnotationDimensions.withArguments(node.name.text),
              node.fileOffset,
              node.name.text.length,
              node.fileUri);
        }
        if (variableLength) {
          if (!allowVariableLength) {
            diagnosticReporter.report(
              messageFfiVariableLengthArrayNotLast,
              node.fileOffset,
              node.name.text.length,
              node.fileUri,
            );
          }
          return dimensions; // Variable length single dimension.
        }
        for (var dimension in dimensions) {
          if (dimension <= 0) {
            diagnosticReporter.report(messageNonPositiveArrayDimensions,
                node.fileOffset, node.name.text.length, node.fileUri);
            success = false;
          }
        }
      }
    } else {
      diagnosticReporter.report(
          templateFfiSizeAnnotation.withArguments(node.name.text),
          node.fileOffset,
          node.name.text.length,
          node.fileUri);
      throw FfiStaticTypeError();
    }

    if (!success) {
      throw FfiStaticTypeError();
    }

    return dimensions;
  }

  Iterable<(List<int>, bool)> getArraySizeAnnotations(Member node) {
    return node.annotations
        .whereType<ConstantExpression>()
        .map((e) => e.constant)
        .whereType<InstanceConstant>()
        .where((e) => e.classNode == arraySizeClass)
        .map(_arraySize);
  }

  /// Reads the dimensions from a constant instance of `_ArraySize`.
  (List<int>, bool) _arraySize(InstanceConstant constant) {
    final variableLength =
        (constant.fieldValues[arraySizeVariableLengthField.fieldReference]
                as BoolConstant)
            .value;
    final dimensions =
        constant.fieldValues[arraySizeDimensionsField.fieldReference];
    if (dimensions != null) {
      if (dimensions is ListConstant) {
        final result =
            dimensions.entries.whereType<IntConstant>().map((e) => e.value);
        return ([if (variableLength) 0, ...result], variableLength);
      }
    }
    final dimensionFields = [
      arraySizeDimension1Field,
      arraySizeDimension2Field,
      arraySizeDimension3Field,
      arraySizeDimension4Field,
      arraySizeDimension5Field
    ];
    final result = dimensionFields
        .map((f) => constant.fieldValues[f.fieldReference])
        .whereType<IntConstant>()
        .map((c) => c.value)
        .toList();
    return (result, variableLength);
  }

  /// Returns the number of dimensions of `Array`.
  ///
  /// `Array<Array<Array<Int8>>>` -> 3.
  ///
  /// `Array<Array<Array<Unknown>>>` -> 3.
  int arrayDimensions(DartType dartType) {
    DartType elementType = dartType;
    int dimensions = 0;
    while (
        elementType is InterfaceType && elementType.classNode == arrayClass) {
      elementType = elementType.typeArguments[0];
      dimensions++;
    }
    return dimensions;
  }

  bool isAbiSpecificIntegerSubtype(DartType type) {
    if (type is InvalidType) {
      return false;
    }
    if (type is NullType) {
      return false;
    }
    if (type is InterfaceType) {
      if (type.classNode == abiSpecificIntegerClass) {
        return false;
      }
    }
    return env.isSubtypeOf(
        type,
        InterfaceType(abiSpecificIntegerClass, Nullability.nonNullable),
        SubtypeCheckMode.ignoringNullabilities);
  }

  bool isStructOrUnionSubtype(DartType type) {
    if (type is InvalidType) {
      return false;
    }
    if (type is NullType) {
      return false;
    }
    if (type is InterfaceType) {
      if (type.classNode == structClass ||
          type.classNode == unionClass ||
          type.classNode == arrayClass) {
        return false;
      }
    }
    return env.isSubtypeOf(
        type,
        InterfaceType(compoundClass, Nullability.nonNullable),
        SubtypeCheckMode.ignoringNullabilities);
  }

  Expression getCompoundTypedDataBaseField(
    Expression receiver,
    int fileOffset,
  ) {
    return InstanceGet(
        InstanceAccessKind.Instance, receiver, compoundTypedDataBaseField.name,
        interfaceTarget: compoundTypedDataBaseField,
        resultType: compoundTypedDataBaseField.type)
      ..fileOffset = fileOffset;
  }

  Expression getCompoundOffsetInBytesField(
    Expression receiver,
    int fileOffset,
  ) {
    return InstanceGet(
        InstanceAccessKind.Instance, receiver, compoundOffsetInBytesField.name,
        interfaceTarget: compoundOffsetInBytesField,
        resultType: compoundOffsetInBytesField.type)
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

  MapConstant? getAbiSpecificIntegerMappingAnnotation(Class node) {
    final annotations = node.annotations
        .whereType<ConstantExpression>()
        .map((e) => e.constant)
        .whereType<InstanceConstant>()
        .where((e) => e.classNode == abiSpecificIntegerMappingClass)
        .map((instanceConstant) =>
            instanceConstant.fieldValues.values.single as MapConstant)
        .toList();

    // There can be at most one annotation (checked by `_FfiDefinitionTransformer`)
    if (annotations.length == 1) {
      return annotations[0];
    }
    return null;
  }

  Expression? inlineSizeOf(InterfaceType nativeType) {
    final Class nativeClass = nativeType.classNode;
    final NativeType? nt = getType(nativeClass);
    if (nt == null) {
      // User-defined compounds.
      final Procedure sizeOfGetter = nativeClass.procedures
          .firstWhere((function) => function.name == Name('#sizeOf'));
      return StaticGet(sizeOfGetter);
    }
    final int size = nativeTypeSizes[nt]!;
    if (size == WORD_SIZE) {
      return runtimeBranchOnLayout(wordSize);
    }
    if (size != UNKNOWN) {
      return ConstantExpression(IntConstant(size),
          InterfaceType(intClass, currentLibrary.nonNullable));
    }
    // Size unknown.
    return null;
  }

  /// Generates an expression performing an Abi specific integer load or store.
  ///
  /// If [value] is provided, it is a store, otherwise a load.
  ///
  /// Provide either [index], or [offsetInBytes], or none for an offset of 0.
  ///
  /// Generates an expression:
  ///
  /// ```dart
  /// _storeAbiSpecificInt(
  ///   [8, 8, 4][_abi()],
  ///   typedDataBase,
  ///   index * [8, 8, 4][_abi()],
  ///   value,
  /// )
  /// ```
  Expression abiSpecificLoadOrStoreExpression(
    AbiSpecificNativeTypeCfe nativeTypeCfe, {
    required Expression typedDataBase,
    Expression? offsetInBytes,
    Expression? index,
    Expression? value,
    required fileOffset,
  }) {
    final method = () {
      if (value != null) {
        if (index != null) {
          return storeAbiSpecificIntAtIndexMethod;
        }
        return storeAbiSpecificIntMethod;
      }
      if (index != null) {
        return loadAbiSpecificIntAtIndexMethod;
      }
      return loadAbiSpecificIntMethod;
    }();

    return StaticInvocation(
      method,
      Arguments([
        typedDataBase,
        offsetInBytes ?? ConstantExpression(IntConstant(0)),
        if (index != null) index,
        if (value != null) value,
      ], types: [
        InterfaceType(nativeTypeCfe.clazz, Nullability.nonNullable)
      ]),
    )..fileOffset = fileOffset;
  }

  /// Prevents the struct from being tree-shaken in TFA by invoking its
  /// constructor in a `_nativeEffect` expression.
  Expression invokeCompoundConstructor(
      Expression nestedExpression, Class compoundClass) {
    final constructor = compoundClass.constructors
        .firstWhere((c) => c.name == Name("#fromTypedDataBase"));
    return BlockExpression(
        Block([
          ExpressionStatement(StaticInvocation(
              nativeEffectMethod,
              Arguments([
                ConstructorInvocation(
                    constructor,
                    Arguments([
                      StaticInvocation(
                          uint8ListFactory,
                          Arguments([
                            ConstantExpression(IntConstant(1)),
                          ]))
                        ..fileOffset = nestedExpression.fileOffset,
                      ConstantExpression(IntConstant(0)),
                    ]))
                  ..fileOffset = nestedExpression.fileOffset
              ])))
        ]),
        nestedExpression)
      ..fileOffset = nestedExpression.fileOffset;
  }

  /// Returns the compound [Class] if a compound is returned, otherwise `null`.
  Class? findCompoundReturnType(DartType dartSignature) {
    if (dartSignature is! FunctionType) {
      return null;
    }
    final returnType = dartSignature.returnType;
    if (returnType is! InterfaceType) {
      return null;
    }
    final clazz = returnType.classNode;
    if (clazz.superclass == structClass || clazz.superclass == unionClass) {
      return clazz;
    }
    return null;
  }

  /// Returns
  /// - `true` if leaf
  /// - `false` if not leaf
  /// - `null` if the expression is not valid (e.g. non-const bool, null)
  bool? getIsLeafBoolean(StaticInvocation node) {
    for (final named in node.arguments.named) {
      if (named.name == 'isLeaf') {
        final expr = named.value;
        if (expr is BoolLiteral) {
          return expr.value;
        } else if (expr is ConstantExpression) {
          final constant = expr.constant;
          if (constant is BoolConstant) {
            return constant.value;
          }
        }
        // isLeaf is passed some invalid value.
        return null;
      }
    }
    // isLeaf defaults to false.
    return false;
  }

  void ensureLeafCallDoesNotUseHandles(
    InterfaceType nativeType,
    bool isLeaf, {
    required TreeNode reportErrorOn,
  }) {
    // Handles are only disallowed for leaf calls.
    if (isLeaf == false) {
      return;
    }

    bool error = false;

    // Check if return type is Handle.
    final functionType = nativeType.typeArguments[0];
    if (functionType is FunctionType) {
      final returnType = functionType.returnType;
      if (returnType is InterfaceType) {
        if (returnType.classNode == handleClass) {
          diagnosticReporter.report(messageFfiLeafCallMustNotReturnHandle,
              reportErrorOn.fileOffset, 1, reportErrorOn.location?.file);
          error = true;
        }
      }
      // Check if any of the argument types are Handle.
      for (DartType param in functionType.positionalParameters) {
        if ((param as InterfaceType).classNode == handleClass) {
          diagnosticReporter.report(messageFfiLeafCallMustNotTakeHandle,
              reportErrorOn.fileOffset, 1, reportErrorOn.location?.file);
          error = true;
        }
      }
    }

    if (error) {
      throw FfiStaticTypeError();
    }
  }

  DartType ensureNativeTypeMatch(
    FfiTypeCheckDirection direction,
    DartType nativeType,
    DartType dartType,
    TreeNode reportErrorOn, {
    bool allowHandle = false,
    bool allowVoid = false,
    bool allowArray = false,
  }) {
    final DartType correspondingDartType = convertNativeTypeToDartType(
      nativeType,
      allowStructAndUnion: true,
      allowHandle: allowHandle,
      allowInlineArray: allowArray,
      allowVoid: allowVoid,
    )!;
    if (dartType == correspondingDartType) return correspondingDartType;
    switch (direction) {
      case FfiTypeCheckDirection.nativeToDart:
        if (env.isSubtypeOf(correspondingDartType, dartType,
            SubtypeCheckMode.ignoringNullabilities)) {
          // If subtype, manually check the return type is not void.
          if (correspondingDartType is FunctionType) {
            if (dartType is FunctionType) {
              if ((dartType.returnType is VoidType) ==
                  (correspondingDartType.returnType is VoidType)) {
                return correspondingDartType;
              }
              // One of the return types is void, the other isn't, report error.
            } else {
              // One is a function type, the other isn't, report error.
            }
          } else {
            return correspondingDartType;
          }
        }
      case FfiTypeCheckDirection.dartToNative:
        if (env.isSubtypeOf(dartType, correspondingDartType,
            SubtypeCheckMode.ignoringNullabilities)) {
          return correspondingDartType;
        }
    }
    diagnosticReporter.report(
        templateFfiTypeMismatch.withArguments(
            dartType, correspondingDartType, nativeType),
        reportErrorOn.fileOffset,
        1,
        reportErrorOn.location?.file);
    throw FfiStaticTypeError();
  }

  void ensureNativeTypeValid(
    DartType nativeType,
    TreeNode reportErrorOn, {
    bool allowHandle = false,
    bool allowStructAndUnion = false,
    bool allowInlineArray = false,
    bool allowVoid = false,
  }) {
    if (!_nativeTypeValid(nativeType,
        allowStructAndUnion: allowStructAndUnion,
        allowHandle: allowHandle,
        allowInlineArray: allowInlineArray,
        allowVoid: allowVoid)) {
      diagnosticReporter.report(
          templateFfiTypeInvalid.withArguments(nativeType),
          reportErrorOn.fileOffset,
          1,
          reportErrorOn.location?.file);
      throw FfiStaticTypeError();
    }
  }

  /// The Dart type system does not enforce that NativeFunction return and
  /// parameter types are only NativeTypes, so we need to check this.
  bool _nativeTypeValid(
    DartType nativeType, {
    bool allowStructAndUnion = false,
    bool allowHandle = false,
    bool allowInlineArray = false,
    bool allowVoid = false,
  }) {
    return convertNativeTypeToDartType(nativeType,
            allowStructAndUnion: allowStructAndUnion,
            allowHandle: allowHandle,
            allowInlineArray: allowInlineArray,
            allowVoid: allowVoid) !=
        null;
  }

  void addPragmaPreferInline(Procedure node) {
    node.addAnnotation(
      ConstantExpression(
        InstanceConstant(
          pragmaClass.reference,
          [],
          {
            pragmaName.fieldReference: StringConstant("vm:prefer-inline"),
            pragmaOptions.fieldReference: NullConstant(),
          },
        ),
      ),
    );
  }
}

/// Returns all libraries including the ones from component except for platform
/// libraries that are only in component.
Set<Library> _getAllRelevantLibraries(
    Component component, List<Library> libraries) {
  Set<Library> allLibs = {};
  allLibs.addAll(libraries);
  for (Library lib in component.libraries) {
    // Skip real dart: libraries. dart:core imports dart:ffi, but that doesn't
    // mean we have to transform anything.
    if (lib.importUri.isScheme("dart") && !lib.isSynthetic) continue;
    allLibs.add(lib);
  }
  return allLibs;
}

/// Checks if any library depends on dart:ffi.
Library? importsFfi(Component component, List<Library> libraries) {
  final Uri dartFfiUri = Uri.parse("dart:ffi");
  Set<Library> allLibs = _getAllRelevantLibraries(component, libraries);
  for (Library lib in allLibs) {
    for (LibraryDependency dependency in lib.dependencies) {
      Library targetLibrary = dependency.targetLibrary;
      if (targetLibrary.importUri == dartFfiUri) {
        return targetLibrary;
      }
    }
  }
  return null;
}

/// Calculates the libraries in [libraries] that transitively imports dart:ffi.
///
/// Returns null if dart:ffi is not imported.
List<Library>? calculateTransitiveImportsOfDartFfiIfUsed(
    Component component, List<Library> libraries) {
  Set<Library> allLibs = _getAllRelevantLibraries(component, libraries);

  final Uri dartFfiUri = Uri.parse("dart:ffi");
  Library? dartFfi;
  canFind:
  for (Library lib in allLibs) {
    for (LibraryDependency dependency in lib.dependencies) {
      Library targetLibrary = dependency.targetLibrary;
      if (targetLibrary.importUri == dartFfiUri) {
        dartFfi = targetLibrary;
        break canFind;
      }
    }
  }
  if (dartFfi == null) return null;

  kernelGraph.LibraryGraph graph = new kernelGraph.LibraryGraph(allLibs);
  Set<Library> result =
      kernelGraph.calculateTransitiveDependenciesOf(graph, {dartFfi});
  return (result..retainAll(libraries)).toList();
}

extension on Map<Abi, Object?> {
  bool get isPartial =>
      [for (final abi in Abi.values) this[abi]].contains(null);
}

/// Used internally for abnormal control flow to prevent cascading error
/// messages.
class FfiStaticTypeError implements Exception {}
