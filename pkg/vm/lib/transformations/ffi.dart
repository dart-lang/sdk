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
import 'package:kernel/type_environment.dart' show TypeEnvironment;

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

/// [FfiTransformer] contains logic which is shared between
/// _FfiUseSiteTransformer and _FfiDefinitionTransformer.
class FfiTransformer extends Transformer {
  final TypeEnvironment env;
  final CoreTypes coreTypes;
  final LibraryIndex index;
  final ClassHierarchy hierarchy;
  final DiagnosticReporter diagnosticReporter;
  final ReferenceFromIndex referenceFromIndex;

  final Class objectClass;
  final Class intClass;
  final Class doubleClass;
  final Class listClass;
  final Class typeClass;
  final Procedure unsafeCastMethod;
  final Class typedDataClass;
  final Procedure typedDataBufferGetter;
  final Procedure typedDataOffsetInBytesGetter;
  final Procedure byteBufferAsUint8List;
  final Class pragmaClass;
  final Field pragmaName;
  final Field pragmaOptions;
  final Procedure listElementAt;
  final Procedure numAddition;

  final Library ffiLibrary;
  final Class nativeFunctionClass;
  final Class pointerClass;
  final Class structClass;
  final Procedure castMethod;
  final Procedure offsetByMethod;
  final Procedure elementAtMethod;
  final Procedure addressGetter;
  final Procedure asFunctionMethod;
  final Procedure asFunctionInternal;
  final Procedure lookupFunctionMethod;
  final Procedure fromFunctionMethod;
  final Field addressOfField;
  final Constructor structFromPointer;
  final Procedure fromAddressInternal;
  final Procedure libraryLookupMethod;
  final Procedure abiMethod;
  final Procedure pointerFromFunctionProcedure;
  final Procedure nativeCallbackFunctionProcedure;
  final Map<NativeType, Procedure> loadMethods;
  final Map<NativeType, Procedure> storeMethods;
  final Map<NativeType, Procedure> elementAtMethods;
  final Procedure loadStructMethod;
  final Procedure memCopy;
  final Procedure asFunctionTearoff;
  final Procedure lookupFunctionTearoff;

  /// Classes corresponding to [NativeType], indexed by [NativeType].
  final List<Class> nativeTypesClasses;

  FfiTransformer(this.index, this.coreTypes, this.hierarchy,
      this.diagnosticReporter, this.referenceFromIndex)
      : env = new TypeEnvironment(coreTypes, hierarchy),
        objectClass = coreTypes.objectClass,
        intClass = coreTypes.intClass,
        doubleClass = coreTypes.doubleClass,
        listClass = coreTypes.listClass,
        typeClass = coreTypes.typeClass,
        unsafeCastMethod =
            index.getTopLevelMember('dart:_internal', 'unsafeCast'),
        typedDataClass = index.getClass('dart:typed_data', 'TypedData'),
        typedDataBufferGetter =
            index.getMember('dart:typed_data', 'TypedData', 'get:buffer'),
        typedDataOffsetInBytesGetter = index.getMember(
            'dart:typed_data', 'TypedData', 'get:offsetInBytes'),
        byteBufferAsUint8List =
            index.getMember('dart:typed_data', 'ByteBuffer', 'asUint8List'),
        pragmaClass = coreTypes.pragmaClass,
        pragmaName = coreTypes.pragmaName,
        pragmaOptions = coreTypes.pragmaOptions,
        listElementAt = coreTypes.index.getMember('dart:core', 'List', '[]'),
        numAddition = coreTypes.index.getMember('dart:core', 'num', '+'),
        ffiLibrary = index.getLibrary('dart:ffi'),
        nativeFunctionClass = index.getClass('dart:ffi', 'NativeFunction'),
        pointerClass = index.getClass('dart:ffi', 'Pointer'),
        structClass = index.getClass('dart:ffi', 'Struct'),
        castMethod = index.getMember('dart:ffi', 'Pointer', 'cast'),
        offsetByMethod = index.getMember('dart:ffi', 'Pointer', '_offsetBy'),
        elementAtMethod = index.getMember('dart:ffi', 'Pointer', 'elementAt'),
        addressGetter = index.getMember('dart:ffi', 'Pointer', 'get:address'),
        addressOfField = index.getMember('dart:ffi', 'Struct', '_addressOf'),
        structFromPointer =
            index.getMember('dart:ffi', 'Struct', '_fromPointer'),
        fromAddressInternal =
            index.getTopLevelMember('dart:ffi', '_fromAddress'),
        asFunctionMethod =
            index.getMember('dart:ffi', 'NativeFunctionPointer', 'asFunction'),
        asFunctionInternal =
            index.getTopLevelMember('dart:ffi', '_asFunctionInternal'),
        lookupFunctionMethod = index.getMember(
            'dart:ffi', 'DynamicLibraryExtension', 'lookupFunction'),
        fromFunctionMethod =
            index.getMember('dart:ffi', 'Pointer', 'fromFunction'),
        libraryLookupMethod =
            index.getMember('dart:ffi', 'DynamicLibrary', 'lookup'),
        abiMethod = index.getTopLevelMember('dart:ffi', '_abi'),
        pointerFromFunctionProcedure =
            index.getTopLevelMember('dart:ffi', '_pointerFromFunction'),
        nativeCallbackFunctionProcedure =
            index.getTopLevelMember('dart:ffi', '_nativeCallbackFunction'),
        nativeTypesClasses = nativeTypeClassNames
            .map((name) => index.getClass('dart:ffi', name))
            .toList(),
        loadMethods = Map.fromIterable(optimizedTypes, value: (t) {
          final name = nativeTypeClassNames[t.index];
          return index.getTopLevelMember('dart:ffi', "_load$name");
        }),
        storeMethods = Map.fromIterable(optimizedTypes, value: (t) {
          final name = nativeTypeClassNames[t.index];
          return index.getTopLevelMember('dart:ffi', "_store$name");
        }),
        elementAtMethods = Map.fromIterable(optimizedTypes, value: (t) {
          final name = nativeTypeClassNames[t.index];
          return index.getTopLevelMember('dart:ffi', "_elementAt$name");
        }),
        loadStructMethod = index.getTopLevelMember('dart:ffi', '_loadStruct'),
        memCopy = index.getTopLevelMember('dart:ffi', '_memCopy'),
        asFunctionTearoff = index.getMember('dart:ffi', 'NativeFunctionPointer',
            LibraryIndex.tearoffPrefix + 'asFunction'),
        lookupFunctionTearoff = index.getMember(
            'dart:ffi',
            'DynamicLibraryExtension',
            LibraryIndex.tearoffPrefix + 'lookupFunction');

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
  DartType convertNativeTypeToDartType(DartType nativeType,
      {bool allowStructs = false, bool allowHandle = false}) {
    if (nativeType is! InterfaceType) {
      return null;
    }
    final InterfaceType native = nativeType;
    final Class nativeClass = native.classNode;
    final NativeType nativeType_ = getType(nativeClass);

    if (hierarchy.isSubclassOf(nativeClass, structClass)) {
      return allowStructs ? nativeType : null;
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

    final FunctionType fun = native.typeArguments[0];
    if (fun.namedParameters.isNotEmpty) return null;
    if (fun.positionalParameters.length != fun.requiredParameterCount) {
      return null;
    }
    if (fun.typeParameters.length != 0) return null;

    final DartType returnType = convertNativeTypeToDartType(fun.returnType,
        allowStructs: allowStructs, allowHandle: true);
    if (returnType == null) return null;
    final List<DartType> argumentTypes = fun.positionalParameters
        .map((t) => convertNativeTypeToDartType(t,
            allowStructs: allowStructs, allowHandle: true))
        .toList();
    if (argumentTypes.contains(null)) return null;
    return FunctionType(argumentTypes, returnType, Nullability.legacy);
  }

  NativeType getType(Class c) {
    final int index = nativeTypesClasses.indexOf(c);
    if (index == -1) {
      return null;
    }
    return NativeType.values[index];
  }
}

/// Contains all information collected by _FfiDefinitionTransformer that is
/// needed in _FfiUseSiteTransformer.
class FfiTransformerData {
  final Map<Field, Procedure> replacedGetters;
  final Map<Field, Procedure> replacedSetters;
  final Set<Class> emptyStructs;
  FfiTransformerData(
      this.replacedGetters, this.replacedSetters, this.emptyStructs);
}
