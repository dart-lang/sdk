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
  kStruct
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
  'Struct'
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
];

/// [FfiTransformer] contains logic which is shared between
/// _FfiUseSiteTransformer and _FfiDefinitionTransformer.
class FfiTransformer extends Transformer {
  final TypeEnvironment env;
  final CoreTypes coreTypes;
  final LibraryIndex index;
  final ClassHierarchy hierarchy;
  final DiagnosticReporter diagnosticReporter;

  final Class intClass;
  final Class doubleClass;
  final Class pragmaClass;
  final Field pragmaName;
  final Field pragmaOptions;

  final Library ffiLibrary;
  final Class nativeFunctionClass;
  final Class pointerClass;
  final Class structClass;
  final Procedure castMethod;
  final Procedure loadMethod;
  final Procedure storeMethod;
  final Procedure offsetByMethod;
  final Procedure asFunctionMethod;
  final Procedure asFunctionInternal;
  final Procedure lookupFunctionMethod;
  final Procedure fromFunctionMethod;
  final Field addressOfField;
  final Constructor structFromPointer;
  final Procedure libraryLookupMethod;

  /// Classes corresponding to [NativeType], indexed by [NativeType].
  final List<Class> nativeTypesClasses;

  FfiTransformer(
      this.index, this.coreTypes, this.hierarchy, this.diagnosticReporter)
      : env = new TypeEnvironment(coreTypes, hierarchy),
        intClass = coreTypes.intClass,
        doubleClass = coreTypes.doubleClass,
        pragmaClass = coreTypes.pragmaClass,
        pragmaName = coreTypes.pragmaName,
        pragmaOptions = coreTypes.pragmaOptions,
        ffiLibrary = index.getLibrary('dart:ffi'),
        nativeFunctionClass = index.getClass('dart:ffi', 'NativeFunction'),
        pointerClass = index.getClass('dart:ffi', 'Pointer'),
        structClass = index.getClass('dart:ffi', 'Struct'),
        castMethod = index.getMember('dart:ffi', 'Pointer', 'cast'),
        loadMethod = index.getMember('dart:ffi', 'Pointer', 'load'),
        storeMethod = index.getMember('dart:ffi', 'Pointer', 'store'),
        offsetByMethod = index.getMember('dart:ffi', 'Pointer', 'offsetBy'),
        addressOfField = index.getMember('dart:ffi', 'Struct', 'addressOf'),
        structFromPointer =
            index.getMember('dart:ffi', 'Struct', 'fromPointer'),
        asFunctionMethod = index.getMember('dart:ffi', 'Pointer', 'asFunction'),
        asFunctionInternal =
            index.getTopLevelMember('dart:ffi', '_asFunctionInternal'),
        lookupFunctionMethod =
            index.getMember('dart:ffi', 'DynamicLibrary', 'lookupFunction'),
        fromFunctionMethod =
            index.getMember('dart:ffi', 'Pointer', 'fromFunction'),
        libraryLookupMethod =
            index.getMember('dart:ffi', 'DynamicLibrary', 'lookup'),
        nativeTypesClasses = nativeTypeClassNames
            .map((name) => index.getClass('dart:ffi', name))
            .toList();

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
  /// [NativeFunction]<T1 Function(T2, T3) -> S1 Function(S2, S3)
  ///    where DartRepresentationOf(Tn) -> Sn
  DartType convertNativeTypeToDartType(DartType nativeType, bool allowStructs) {
    if (nativeType is! InterfaceType) {
      return null;
    }
    InterfaceType native = nativeType;
    Class nativeClass = native.classNode;
    NativeType nativeType_ = getType(nativeClass);

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
      return InterfaceType(intClass);
    }
    if (nativeType_ == NativeType.kFloat || nativeType_ == NativeType.kDouble) {
      return InterfaceType(doubleClass);
    }
    if (nativeType_ == NativeType.kVoid) {
      return VoidType();
    }
    if (nativeType_ != NativeType.kNativeFunction ||
        native.typeArguments[0] is! FunctionType) {
      return null;
    }

    FunctionType fun = native.typeArguments[0];
    if (fun.namedParameters.isNotEmpty) return null;
    if (fun.positionalParameters.length != fun.requiredParameterCount) {
      return null;
    }
    if (fun.typeParameters.length != 0) return null;
    // TODO(36730): Structs cannot appear in native function signatures.
    DartType returnType =
        convertNativeTypeToDartType(fun.returnType, /*allowStructs=*/ false);
    if (returnType == null) return null;
    List<DartType> argumentTypes = fun.positionalParameters
        .map((t) => convertNativeTypeToDartType(t, /*allowStructs=*/ false))
        .toList();
    if (argumentTypes.contains(null)) return null;
    return FunctionType(argumentTypes, returnType);
  }

  NativeType getType(Class c) {
    int index = nativeTypesClasses.indexOf(c);
    if (index == -1) {
      return null;
    }
    return NativeType.values[index];
  }
}

/// Contains replaced members, of which all the call sites need to be replaced.
///
/// [ReplacedMembers] is populated by _FfiDefinitionTransformer and consumed by
/// _FfiUseSiteTransformer.
class ReplacedMembers {
  final Map<Field, Procedure> replacedGetters;
  final Map<Field, Procedure> replacedSetters;
  ReplacedMembers(this.replacedGetters, this.replacedSetters);
}
