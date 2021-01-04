// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:meta/meta.dart';

// It is hard to visually separate each code's _doc comment_ from its published
// _documentation comment_ when each is written as an end-of-line comment.
// ignore_for_file: slash_for_doc_comments

/// The diagnostic codes associated with `dart:ffi`.
class FfiCode extends AnalyzerErrorCode {
  /**
   * No parameters.
   */
  static const FfiCode ANNOTATION_ON_POINTER_FIELD = FfiCode(
      name: 'ANNOTATION_ON_POINTER_FIELD',
      message:
          "Fields in a struct class whose type is 'Pointer' should not have "
          "any annotations.",
      correction: "Try removing the annotation.");

  /**
   * Parameters:
   * 0: the name of the struct class
   */
  static const FfiCode EMPTY_STRUCT = FfiCode(
      name: 'EMPTY_STRUCT',
      message: "Struct '{0}' is empty. Empty structs are undefined behavior.",
      correction: "Try adding a field to '{0}' or use a different Struct.");

  /**
   * No parameters.
   */
  static const FfiCode EXTRA_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
      name: 'EXTRA_ANNOTATION_ON_STRUCT_FIELD',
      message: "Fields in a struct class must have exactly one annotation "
          "indicating the native type.",
      correction: "Try removing the extra annotation.");

  /**
   * No parameters.
   */
  static const FfiCode FIELD_IN_STRUCT_WITH_INITIALIZER = FfiCode(
      name: 'FIELD_IN_STRUCT_WITH_INITIALIZER',
      message: "Fields in subclasses of 'Struct' can't have initializers.",
      correction: "Try removing the initializer.");

  /**
   * No parameters.
   */
  static const FfiCode FIELD_INITIALIZER_IN_STRUCT = FfiCode(
      name: 'FIELD_INITIALIZER_IN_STRUCT',
      message: "Constructors in subclasses of 'Struct' can't have field "
          "initializers.",
      correction: "Try removing the field initializer.");

  /**
   * Parameters:
   * 0: the name of the struct class
   */
  static const FfiCode GENERIC_STRUCT_SUBCLASS = FfiCode(
      name: 'GENERIC_STRUCT_SUBCLASS',
      message: "The class '{0}' can't extend 'Struct' because it is generic.",
      correction: "Try removing the type parameters from '{0}'.");

  /**
   * No parameters.
   */
  static const FfiCode INVALID_EXCEPTION_VALUE = FfiCode(
      name: 'INVALID_EXCEPTION_VALUE',
      message:
          "The method 'Pointer.fromFunction' must not have an exceptional return "
          "value (the second argument) when the return type of the function is "
          "either 'void', 'Handle' or 'Pointer'.",
      correction: "Try removing the exceptional return value.");

  /**
   * Parameters:
   * 0: the type of the field
   */
  static const FfiCode INVALID_FIELD_TYPE_IN_STRUCT = FfiCode(
      name: 'INVALID_FIELD_TYPE_IN_STRUCT',
      message:
          "Fields in struct classes can't have the type '{0}'. They can only "
          "be declared as 'int', 'double', 'Pointer', or subtype of 'Struct'.",
      correction:
          "Try using 'int', 'double', 'Pointer', or subtype of 'Struct'.");

  /**
   * No parameters.
   */
  static const FfiCode MISMATCHED_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
      name: 'MISMATCHED_ANNOTATION_ON_STRUCT_FIELD',
      message: "The annotation does not match the declared type of the field.",
      correction: "Try using a different annotation or changing the declared "
          "type to match.");

  /**
   * No parameters.
   */
  static const FfiCode MISSING_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
      name: 'MISSING_ANNOTATION_ON_STRUCT_FIELD',
      message:
          "Fields in a struct class must either have the type 'Pointer' or an "
          "annotation indicating the native type.",
      correction: "Try adding an annotation.");

  /**
   * No parameters.
   */
  static const FfiCode MISSING_EXCEPTION_VALUE = FfiCode(
      name: 'MISSING_EXCEPTION_VALUE',
      message:
          "The method 'Pointer.fromFunction' must have an exceptional return "
          "value (the second argument) when the return type of the function is "
          "neither 'void', 'Handle' or 'Pointer'.",
      correction: "Try adding an exceptional return value.");

  /**
   * Parameters:
   * 0: the type of the field
   */
  static const FfiCode MISSING_FIELD_TYPE_IN_STRUCT = FfiCode(
      name: 'MISSING_FIELD_TYPE_IN_STRUCT',
      message:
          "Fields in struct classes must have an explicitly declared type of "
          "'int', 'double' or 'Pointer'.",
      correction: "Try using 'int', 'double' or 'Pointer'.");

  /**
   * Parameters:
   * 0: the type that should be a valid dart:ffi native type.
   * 1: the name of the function whose invocation depends on this relationship
   */
  static const FfiCode MUST_BE_A_NATIVE_FUNCTION_TYPE = FfiCode(
      name: 'MUST_BE_A_NATIVE_FUNCTION_TYPE',
      message:
          "The type '{0}' given to '{1}' must be a valid 'dart:ffi' native "
          "function type.",
      correction: "Try changing the type to only use members for 'dart:ffi'.");

  /**
   * Parameters:
   * 0: the type that should be a subtype
   * 1: the supertype that the subtype is compared to
   * 2: the name of the function whose invocation depends on this relationship
   */
  static const FfiCode MUST_BE_A_SUBTYPE = FfiCode(
      name: 'MUST_BE_A_SUBTYPE',
      message: "The type '{0}' must be a subtype of '{1}' for '{2}'.",
      correction: "Try changing one or both of the type arguments.");

  /**
   * Parameters:
   * 0: the name of the function, method, or constructor having type arguments
   */
  static const FfiCode NON_CONSTANT_TYPE_ARGUMENT = FfiCode(
      name: 'NON_CONSTANT_TYPE_ARGUMENT',
      message:
          "The type arguments to '{0}' must be compile time constants but type "
          "parameters are not constants.",
      correction: "Try changing the type argument to be a constant type.");

  /**
   * Parameters:
   * 0: the type that should be a valid dart:ffi native type.
   */
  static const FfiCode NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER = FfiCode(
      name: 'NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER',
      message: "The type argument for the pointer '{0}' must be a "
          "'NativeFunction' in order to use 'asFunction'.",
      correction: "Try changing the type argument to be a 'NativeFunction'.");

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_EXTENDS = FfiCode(
    name: 'SUBTYPE_OF_FFI_CLASS',
    message: "The class '{0}' can't extend '{1}'.",
    correction: "Try extending 'Struct'.",
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_EXTENDS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS = FfiCode(
    name: 'SUBTYPE_OF_FFI_CLASS',
    message: "The class '{0}' can't implement '{1}'.",
    correction: "Try extending 'Struct'.",
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_WITH = FfiCode(
    name: 'SUBTYPE_OF_FFI_CLASS',
    message: "The class '{0}' can't mix in '{1}'.",
    correction: "Try extending 'Struct'.",
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_WITH',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS = FfiCode(
    name: 'SUBTYPE_OF_STRUCT_CLASS',
    message: "The class '{0}' can't extend '{1}' because '{1}' is a subtype of "
        "'Struct'.",
    correction: "Try extending 'Struct' directly.",
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS = FfiCode(
    name: 'SUBTYPE_OF_STRUCT_CLASS',
    message:
        "The class '{0}' can't implement '{1}' because '{1}' is a subtype of "
        "'Struct'.",
    correction: "Try extending 'Struct' directly.",
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_WITH = FfiCode(
    name: 'SUBTYPE_OF_STRUCT_CLASS',
    message: "The class '{0}' can't mix in '{1}' because '{1}' is a subtype of "
        "'Struct'.",
    correction: "Try extending 'Struct' directly.",
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_WITH',
  );

  /// Initialize a newly created error code to have the given [name]. If
  /// [uniqueName] is provided, then it will be used to construct the unique
  /// name for the code, otherwise the name will be used to construct the unique
  /// name.
  ///
  /// The message associated with the error will be created from the given
  /// [message] template. The correction associated with the error will be
  /// created from the given [correction] template.
  ///
  /// If [hasPublishedDocs] is `true` then a URL for the docs will be generated.
  const FfiCode({
    String correction,
    bool hasPublishedDocs = false,
    @required String message,
    @required String name,
    String uniqueName,
  }) : super(
          correction: correction,
          hasPublishedDocs: hasPublishedDocs,
          message: message,
          name: name,
          uniqueName: uniqueName ?? 'FfiCode.$name',
        );

  @override
  ErrorSeverity get errorSeverity => type.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}
