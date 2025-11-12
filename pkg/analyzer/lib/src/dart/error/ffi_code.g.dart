// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/dart/error/ffi_code.dart";

class FfiCode {
  /// No parameters.
  static const DiagnosticWithoutArguments abiSpecificIntegerInvalid =
      diag.abiSpecificIntegerInvalid;

  /// No parameters.
  static const DiagnosticWithoutArguments abiSpecificIntegerMappingExtra =
      diag.abiSpecificIntegerMappingExtra;

  /// No parameters.
  static const DiagnosticWithoutArguments abiSpecificIntegerMappingMissing =
      diag.abiSpecificIntegerMappingMissing;

  /// Parameters:
  /// String p0: the value of the invalid mapping
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  abiSpecificIntegerMappingUnsupported =
      diag.abiSpecificIntegerMappingUnsupported;

  /// No parameters.
  static const DiagnosticWithoutArguments addressPosition =
      diag.addressPosition;

  /// No parameters.
  static const DiagnosticWithoutArguments addressReceiver =
      diag.addressReceiver;

  /// No parameters.
  static const DiagnosticWithoutArguments annotationOnPointerField =
      diag.annotationOnPointerField;

  /// Parameters:
  /// String p0: the name of the argument
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  argumentMustBeAConstant = diag.argumentMustBeAConstant;

  /// No parameters.
  static const DiagnosticWithoutArguments argumentMustBeNative =
      diag.argumentMustBeNative;

  /// Parameters:
  /// String p0: the name of the struct or union class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  compoundImplementsFinalizable = diag.compoundImplementsFinalizable;

  /// No parameters.
  static const DiagnosticWithoutArguments creationOfStructOrUnion =
      diag.creationOfStructOrUnion;

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the superclass
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  emptyStruct = diag.emptyStruct;

  /// No parameters.
  static const DiagnosticWithoutArguments extraAnnotationOnStructField =
      diag.extraAnnotationOnStructField;

  /// No parameters.
  static const DiagnosticWithoutArguments extraSizeAnnotationCarray =
      diag.extraSizeAnnotationCarray;

  /// No parameters.
  static const DiagnosticWithoutArguments
  ffiNativeInvalidDuplicateDefaultAsset =
      diag.ffiNativeInvalidDuplicateDefaultAsset;

  /// No parameters.
  static const DiagnosticWithoutArguments ffiNativeInvalidMultipleAnnotations =
      diag.ffiNativeInvalidMultipleAnnotations;

  /// No parameters.
  static const DiagnosticWithoutArguments ffiNativeMustBeExternal =
      diag.ffiNativeMustBeExternal;

  /// No parameters.
  static const DiagnosticWithoutArguments
  ffiNativeOnlyClassesExtendingNativefieldwrapperclass1CanBePointer =
      diag.ffiNativeOnlyClassesExtendingNativefieldwrapperclass1CanBePointer;

  /// Parameters:
  /// int p0: the expected number of parameters
  /// int p1: the actual number of parameters
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  ffiNativeUnexpectedNumberOfParameters =
      diag.ffiNativeUnexpectedNumberOfParameters;

  /// Parameters:
  /// int p0: the expected number of parameters
  /// int p1: the actual number of parameters
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  ffiNativeUnexpectedNumberOfParametersWithReceiver =
      diag.ffiNativeUnexpectedNumberOfParametersWithReceiver;

  /// No parameters.
  static const DiagnosticWithoutArguments fieldMustBeExternalInStruct =
      diag.fieldMustBeExternalInStruct;

  /// Parameters:
  /// String p0: the name of the struct class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  genericStructSubclass = diag.genericStructSubclass;

  /// Parameters:
  /// String p0: the name of the method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidExceptionValue = diag.invalidExceptionValue;

  /// Parameters:
  /// String p0: the type of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidFieldTypeInStruct = diag.invalidFieldTypeInStruct;

  /// No parameters.
  static const DiagnosticWithoutArguments leafCallMustNotReturnHandle =
      diag.leafCallMustNotReturnHandle;

  /// No parameters.
  static const DiagnosticWithoutArguments leafCallMustNotTakeHandle =
      diag.leafCallMustNotTakeHandle;

  /// No parameters.
  static const DiagnosticWithoutArguments mismatchedAnnotationOnStructField =
      diag.mismatchedAnnotationOnStructField;

  /// Parameters:
  /// Type p0: the type that is missing a native type annotation
  /// String p1: the superclass which is extended by this field's class
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0, required String p1})
  >
  missingAnnotationOnStructField = diag.missingAnnotationOnStructField;

  /// Parameters:
  /// String p0: the name of the method
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingExceptionValue = diag.missingExceptionValue;

  /// No parameters.
  static const DiagnosticWithoutArguments missingFieldTypeInStruct =
      diag.missingFieldTypeInStruct;

  /// No parameters.
  static const DiagnosticWithoutArguments missingSizeAnnotationCarray =
      diag.missingSizeAnnotationCarray;

  /// Parameters:
  /// Object p0: the type that should be a valid dart:ffi native type.
  /// String p1: the name of the function whose invocation depends on this
  ///            relationship
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required String p1})
  >
  mustBeANativeFunctionType = diag.mustBeANativeFunctionType;

  /// Parameters:
  /// Type p0: the type that should be a subtype
  /// Type p1: the supertype that the subtype is compared to
  /// String p2: the name of the function whose invocation depends on this
  ///            relationship
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  mustBeASubtype = diag.mustBeASubtype;

  /// Parameters:
  /// Type p0: the return type that should be 'void'.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  mustReturnVoid = diag.mustReturnVoid;

  /// Parameters:
  /// Type p0: The invalid type.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  nativeFieldInvalidType = diag.nativeFieldInvalidType;

  /// No parameters.
  static const DiagnosticWithoutArguments nativeFieldMissingType =
      diag.nativeFieldMissingType;

  /// No parameters.
  static const DiagnosticWithoutArguments nativeFieldNotStatic =
      diag.nativeFieldNotStatic;

  /// No parameters.
  static const DiagnosticWithoutArguments nativeFunctionMissingType =
      diag.nativeFunctionMissingType;

  /// No parameters.
  static const DiagnosticWithoutArguments negativeVariableDimension =
      diag.negativeVariableDimension;

  /// Parameters:
  /// String p0: the name of the function, method, or constructor having type
  ///            arguments
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  nonConstantTypeArgument = diag.nonConstantTypeArgument;

  /// Parameters:
  /// Type p0: the type that should be a valid dart:ffi native type.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required DartType p0})
  >
  nonNativeFunctionTypeArgumentToPointer =
      diag.nonNativeFunctionTypeArgumentToPointer;

  /// No parameters.
  static const DiagnosticWithoutArguments nonPositiveArrayDimension =
      diag.nonPositiveArrayDimension;

  /// Parameters:
  /// String p0: the name of the field
  /// Type p1: the type of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  nonSizedTypeArgument = diag.nonSizedTypeArgument;

  /// No parameters.
  static const DiagnosticWithoutArguments packedAnnotation =
      diag.packedAnnotation;

  /// No parameters.
  static const DiagnosticWithoutArguments packedAnnotationAlignment =
      diag.packedAnnotationAlignment;

  /// No parameters.
  static const DiagnosticWithoutArguments sizeAnnotationDimensions =
      diag.sizeAnnotationDimensions;

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the class being extended, implemented, or mixed in
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfStructClassInExtends = diag.subtypeOfStructClassInExtends;

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the class being extended, implemented, or mixed in
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfStructClassInImplements = diag.subtypeOfStructClassInImplements;

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the class being extended, implemented, or mixed in
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfStructClassInWith = diag.subtypeOfStructClassInWith;

  /// No parameters.
  static const DiagnosticWithoutArguments variableLengthArrayNotLast =
      diag.variableLengthArrayNotLast;

  /// Do not construct instances of this class.
  FfiCode._() : assert(false);
}
