// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains logic which is shared between the ffi_definition and
// ffi_use_site transformers.

library vm.transformations.ffi;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:kernel/type_environment.dart' show TypeEnvironment;

/// Represents the (instantiated) ffi.NativeType.
enum NativeType {
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
  kVoid
}

const NativeType kNativeTypeIntStart = NativeType.kInt8;
const NativeType kNativeTypeIntEnd = NativeType.kIntptr;

/// The [NativeType] class names, indexed by [NativeType].
const List<String> nativeTypeClassNames = [
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
  'Void'
];

const int UNKNOWN = 0;
const int WORD_SIZE = -1;

/// The [NativeType] sizes in bytes, indexed by [NativeType].
const List<int> nativeTypeSizes = [
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
];

/// [FfiTransformer] contains logic which is shared between
/// _FfiUseSiteTransformer and _FfiDefinitionTransformer.
class FfiTransformer extends Transformer {
  final TypeEnvironment env;
  final ClassHierarchy hierarchy;
  final DiagnosticReporter diagnosticReporter;

  final Class intClass;
  final Class doubleClass;
  final Constructor pragmaConstructor;

  final Library ffiLibrary;
  final Class nativeFunctionClass;
  final Class pointerClass;
  final Procedure castMethod;
  final Procedure loadMethod;
  final Procedure storeMethod;
  final Procedure offsetByMethod;
  final Procedure asFunctionMethod;
  final Procedure lookupFunctionMethod;
  final Procedure fromFunctionMethod;
  final Field structField;

  /// Classes corresponding to [NativeType], indexed by [NativeType].
  final List<Class> nativeTypesClasses;

  FfiTransformer(this.hierarchy, CoreTypes coreTypes, this.diagnosticReporter)
      : env = new TypeEnvironment(coreTypes, hierarchy),
        intClass = coreTypes.intClass,
        doubleClass = coreTypes.doubleClass,
        ffiLibrary = coreTypes.ffiLibrary,
        nativeFunctionClass = coreTypes.ffiNativeFunctionClass,
        pointerClass = coreTypes.ffiPointerClass,
        castMethod = coreTypes.ffiPointerCastProcedure,
        loadMethod = coreTypes.ffiPointerLoadProcedure,
        storeMethod = coreTypes.ffiPointerStoreProcedure,
        offsetByMethod = coreTypes.ffiPointerOffsetByProcedure,
        asFunctionMethod = coreTypes.ffiPointerAsFunctionProcedure,
        lookupFunctionMethod =
            coreTypes.ffiDynamicLibraryLookupFunctionProcedure,
        fromFunctionMethod = coreTypes.ffiFromFunctionProcedure,
        structField = coreTypes.ffiStructField,
        pragmaConstructor = coreTypes.pragmaConstructor,
        nativeTypesClasses =
            nativeTypeClassNames.map(coreTypes.ffiNativeTypeClass).toList() {}

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
  /// [Pointer]<T>                         -> [Pointer]<T>
  /// T extends [Pointer]                  -> T
  /// [NativeFunction]<T1 Function(T2, T3) -> S1 Function(S2, S3)
  ///    where DartRepresentationOf(Tn) -> Sn
  DartType convertNativeTypeToDartType(DartType nativeType) {
    if (nativeType is! InterfaceType) {
      return null;
    }
    Class nativeClass = (nativeType as InterfaceType).classNode;
    if (env.isSubtypeOf(
        InterfaceType(nativeClass), InterfaceType(pointerClass))) {
      return nativeType;
    }
    NativeType nativeType_ = getType(nativeClass);
    if (nativeType_ == null) {
      return null;
    }
    if (kNativeTypeIntStart.index <= nativeType_.index &&
        nativeType_.index <= kNativeTypeIntEnd.index) {
      return InterfaceType(intClass);
    }
    if (nativeType_ == NativeType.kFloat || nativeType_ == NativeType.kDouble) {
      return InterfaceType(doubleClass);
    }
    if (nativeType_ == NativeType.kNativeFunction) {
      DartType fun = (nativeType as InterfaceType).typeArguments[0];
      if (fun is FunctionType) {
        if (fun.namedParameters.isNotEmpty) return null;
        if (fun.positionalParameters.length != fun.requiredParameterCount)
          return null;
        if (fun.typeParameters.length != 0) return null;
        DartType returnType = convertNativeTypeToDartType(fun.returnType);
        if (returnType == null) return null;
        List<DartType> argumentTypes = fun.positionalParameters
            .map(this.convertNativeTypeToDartType)
            .toList();
        if (argumentTypes.contains(null)) return null;
        return FunctionType(argumentTypes, returnType);
      }
    }
    return null;
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
