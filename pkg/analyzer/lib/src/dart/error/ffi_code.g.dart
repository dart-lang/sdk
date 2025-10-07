// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// While transitioning `HintCodes` to `WarningCodes`, we refer to deprecated
// codes here.
// ignore_for_file: deprecated_member_use_from_same_package
//
// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/dart/error/ffi_code.dart";

class FfiCode extends DiagnosticCodeWithExpectedTypes {
  /// No parameters.
  static const FfiWithoutArguments
  abiSpecificIntegerInvalid = FfiWithoutArguments(
    'ABI_SPECIFIC_INTEGER_INVALID',
    "Classes extending 'AbiSpecificInteger' must have exactly one const "
        "constructor, no other members, and no type parameters.",
    correctionMessage:
        "Try removing all type parameters, removing all members, and adding "
        "one const constructor.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments
  abiSpecificIntegerMappingExtra = FfiWithoutArguments(
    'ABI_SPECIFIC_INTEGER_MAPPING_EXTRA',
    "Classes extending 'AbiSpecificInteger' must have exactly one "
        "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
        "ABI to a 'NativeType' integer with a fixed size.",
    correctionMessage: "Try removing the extra annotation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments
  abiSpecificIntegerMappingMissing = FfiWithoutArguments(
    'ABI_SPECIFIC_INTEGER_MAPPING_MISSING',
    "Classes extending 'AbiSpecificInteger' must have exactly one "
        "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
        "ABI to a 'NativeType' integer with a fixed size.",
    correctionMessage: "Try adding an annotation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the value of the invalid mapping
  static const FfiTemplate<LocatableDiagnostic Function({required String p0})>
  abiSpecificIntegerMappingUnsupported = FfiTemplate(
    'ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED',
    "Invalid mapping to '{0}'; only mappings to 'Int8', 'Int16', 'Int32', "
        "'Int64', 'Uint8', 'Uint16', 'UInt32', and 'Uint64' are supported.",
    correctionMessage:
        "Try changing the value to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', "
        "'Uint16', 'UInt32', or 'Uint64'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAbiSpecificIntegerMappingUnsupported,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const FfiWithoutArguments addressPosition = FfiWithoutArguments(
    'ADDRESS_POSITION',
    "The '.address' expression can only be used as argument to a leaf native "
        "external call.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments addressReceiver = FfiWithoutArguments(
    'ADDRESS_RECEIVER',
    "The receiver of '.address' must be a concrete 'TypedData', a concrete "
        "'TypedData' '[]', an 'Array', an 'Array' '[]', a Struct field, or a "
        "Union field.",
    correctionMessage:
        "Change the receiver of '.address' to one of the allowed kinds.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments annotationOnPointerField =
      FfiWithoutArguments(
        'ANNOTATION_ON_POINTER_FIELD',
        "Fields in a struct class whose type is 'Pointer' shouldn't have any "
            "annotations.",
        correctionMessage: "Try removing the annotation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the argument
  static const FfiTemplate<LocatableDiagnostic Function({required String p0})>
  argumentMustBeAConstant = FfiTemplate(
    'ARGUMENT_MUST_BE_A_CONSTANT',
    "Argument '{0}' must be a constant.",
    correctionMessage: "Try replacing the value with a literal or const.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsArgumentMustBeAConstant,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const FfiWithoutArguments argumentMustBeNative = FfiWithoutArguments(
    'ARGUMENT_MUST_BE_NATIVE',
    "Argument to 'Native.addressOf' must be annotated with @Native",
    correctionMessage:
        "Try passing a static function or field annotated with '@Native'",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the struct or union class
  static const FfiTemplate<LocatableDiagnostic Function({required String p0})>
  compoundImplementsFinalizable = FfiTemplate(
    'COMPOUND_IMPLEMENTS_FINALIZABLE',
    "The class '{0}' can't implement Finalizable.",
    correctionMessage: "Try removing the implements clause from '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsCompoundImplementsFinalizable,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const FfiWithoutArguments
  creationOfStructOrUnion = FfiWithoutArguments(
    'CREATION_OF_STRUCT_OR_UNION',
    "Subclasses of 'Struct' and 'Union' are backed by native memory, and can't "
        "be instantiated by a generative constructor.",
    correctionMessage:
        "Try allocating it via allocation, or load from a 'Pointer'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the superclass
  static const FfiTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  emptyStruct = FfiTemplate(
    'EMPTY_STRUCT',
    "The class '{0}' can't be empty because it's a subclass of '{1}'.",
    correctionMessage:
        "Try adding a field to '{0}' or use a different superclass.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsEmptyStruct,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const FfiWithoutArguments
  extraAnnotationOnStructField = FfiWithoutArguments(
    'EXTRA_ANNOTATION_ON_STRUCT_FIELD',
    "Fields in a struct class must have exactly one annotation indicating the "
        "native type.",
    correctionMessage: "Try removing the extra annotation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments extraSizeAnnotationCarray =
      FfiWithoutArguments(
        'EXTRA_SIZE_ANNOTATION_CARRAY',
        "'Array's must have exactly one 'Array' annotation.",
        correctionMessage: "Try removing the extra annotation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const FfiWithoutArguments ffiNativeInvalidDuplicateDefaultAsset =
      FfiWithoutArguments(
        'FFI_NATIVE_INVALID_DUPLICATE_DEFAULT_ASSET',
        "There may be at most one @DefaultAsset annotation on a library.",
        correctionMessage: "Try removing the extra annotation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const FfiWithoutArguments
  ffiNativeInvalidMultipleAnnotations = FfiWithoutArguments(
    'FFI_NATIVE_INVALID_MULTIPLE_ANNOTATIONS',
    "Native functions and fields must have exactly one `@Native` annotation.",
    correctionMessage: "Try removing the extra annotation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments ffiNativeMustBeExternal =
      FfiWithoutArguments(
        'FFI_NATIVE_MUST_BE_EXTERNAL',
        "Native functions must be declared external.",
        correctionMessage: "Add the `external` keyword to the function.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const FfiWithoutArguments
  ffiNativeOnlyClassesExtendingNativefieldwrapperclass1CanBePointer =
      FfiWithoutArguments(
        'FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER',
        "Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.",
        correctionMessage: "Pass as Handle instead.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// int p0: the expected number of parameters
  /// int p1: the actual number of parameters
  static const FfiTemplate<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  ffiNativeUnexpectedNumberOfParameters = FfiTemplate(
    'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS',
    "Unexpected number of Native annotation parameters. Expected {0} but has "
        "{1}.",
    correctionMessage: "Make sure parameters match the function annotated.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsFfiNativeUnexpectedNumberOfParameters,
    expectedTypes: [ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the expected number of parameters
  /// int p1: the actual number of parameters
  static const FfiTemplate<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  ffiNativeUnexpectedNumberOfParametersWithReceiver = FfiTemplate(
    'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER',
    "Unexpected number of Native annotation parameters. Expected {0} but has "
        "{1}. Native instance method annotation must have receiver as first "
        "argument.",
    correctionMessage:
        "Make sure parameters match the function annotated, including an extra "
        "first parameter for the receiver.",
    hasPublishedDocs: true,
    withArguments:
        _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver,
    expectedTypes: [ExpectedType.int, ExpectedType.int],
  );

  /// No parameters.
  static const FfiWithoutArguments fieldMustBeExternalInStruct =
      FfiWithoutArguments(
        'FIELD_MUST_BE_EXTERNAL_IN_STRUCT',
        "Fields of 'Struct' and 'Union' subclasses must be marked external.",
        correctionMessage: "Try adding the 'external' modifier.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the struct class
  static const FfiTemplate<LocatableDiagnostic Function({required String p0})>
  genericStructSubclass = FfiTemplate(
    'GENERIC_STRUCT_SUBCLASS',
    "The class '{0}' can't extend 'Struct' or 'Union' because '{0}' is "
        "generic.",
    correctionMessage: "Try removing the type parameters from '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsGenericStructSubclass,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the method
  static const FfiTemplate<LocatableDiagnostic Function({required String p0})>
  invalidExceptionValue = FfiTemplate(
    'INVALID_EXCEPTION_VALUE',
    "The method {0} can't have an exceptional return value (the second "
        "argument) when the return type of the function is either 'void', "
        "'Handle' or 'Pointer'.",
    correctionMessage: "Try removing the exceptional return value.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidExceptionValue,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the type of the field
  static const FfiTemplate<LocatableDiagnostic Function({required String p0})>
  invalidFieldTypeInStruct = FfiTemplate(
    'INVALID_FIELD_TYPE_IN_STRUCT',
    "Fields in struct classes can't have the type '{0}'. They can only be "
        "declared as 'int', 'double', 'Array', 'Pointer', or subtype of "
        "'Struct' or 'Union'.",
    correctionMessage:
        "Try using 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' "
        "or 'Union'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidFieldTypeInStruct,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const FfiWithoutArguments leafCallMustNotReturnHandle =
      FfiWithoutArguments(
        'LEAF_CALL_MUST_NOT_RETURN_HANDLE',
        "FFI leaf call can't return a 'Handle'.",
        correctionMessage:
            "Try changing the return type to primitive or struct.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const FfiWithoutArguments leafCallMustNotTakeHandle =
      FfiWithoutArguments(
        'LEAF_CALL_MUST_NOT_TAKE_HANDLE',
        "FFI leaf call can't take arguments of type 'Handle'.",
        correctionMessage:
            "Try changing the argument type to primitive or struct.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const FfiWithoutArguments mismatchedAnnotationOnStructField =
      FfiWithoutArguments(
        'MISMATCHED_ANNOTATION_ON_STRUCT_FIELD',
        "The annotation doesn't match the declared type of the field.",
        correctionMessage:
            "Try using a different annotation or changing the declared type to "
            "match.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the type that is missing a native type annotation
  /// String p1: the superclass which is extended by this field's class
  static const FfiTemplate<
    LocatableDiagnostic Function({required DartType p0, required String p1})
  >
  missingAnnotationOnStructField = FfiTemplate(
    'MISSING_ANNOTATION_ON_STRUCT_FIELD',
    "Fields of type '{0}' in a subclass of '{1}' must have an annotation "
        "indicating the native type.",
    correctionMessage: "Try adding an annotation.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMissingAnnotationOnStructField,
    expectedTypes: [ExpectedType.type, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the method
  static const FfiTemplate<LocatableDiagnostic Function({required String p0})>
  missingExceptionValue = FfiTemplate(
    'MISSING_EXCEPTION_VALUE',
    "The method {0} must have an exceptional return value (the second "
        "argument) when the return type of the function is neither 'void', "
        "'Handle', nor 'Pointer'.",
    correctionMessage: "Try adding an exceptional return value.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMissingExceptionValue,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const FfiWithoutArguments
  missingFieldTypeInStruct = FfiWithoutArguments(
    'MISSING_FIELD_TYPE_IN_STRUCT',
    "Fields in struct classes must have an explicitly declared type of 'int', "
        "'double' or 'Pointer'.",
    correctionMessage: "Try using 'int', 'double' or 'Pointer'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments missingSizeAnnotationCarray =
      FfiWithoutArguments(
        'MISSING_SIZE_ANNOTATION_CARRAY',
        "Fields of type 'Array' must have exactly one 'Array' annotation.",
        correctionMessage:
            "Try adding an 'Array' annotation, or removing all but one of the "
            "annotations.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the type that should be a valid dart:ffi native type.
  /// String p1: the name of the function whose invocation depends on this
  ///            relationship
  static const FfiTemplate<
    LocatableDiagnostic Function({required Object p0, required String p1})
  >
  mustBeANativeFunctionType = FfiTemplate(
    'MUST_BE_A_NATIVE_FUNCTION_TYPE',
    "The type '{0}' given to '{1}' must be a valid 'dart:ffi' native function "
        "type.",
    correctionMessage:
        "Try changing the type to only use members for 'dart:ffi'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMustBeANativeFunctionType,
    expectedTypes: [ExpectedType.object, ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the type that should be a subtype
  /// Type p1: the supertype that the subtype is compared to
  /// String p2: the name of the function whose invocation depends on this
  ///            relationship
  static const FfiTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  mustBeASubtype = FfiTemplate(
    'MUST_BE_A_SUBTYPE',
    "The type '{0}' must be a subtype of '{1}' for '{2}'.",
    correctionMessage: "Try changing one or both of the type arguments.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMustBeASubtype,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the return type that should be 'void'.
  static const FfiTemplate<LocatableDiagnostic Function({required DartType p0})>
  mustReturnVoid = FfiTemplate(
    'MUST_RETURN_VOID',
    "The return type of the function passed to 'NativeCallable.listener' must "
        "be 'void' rather than '{0}'.",
    correctionMessage: "Try changing the return type to 'void'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMustReturnVoid,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: The invalid type.
  static const FfiTemplate<LocatableDiagnostic Function({required DartType p0})>
  nativeFieldInvalidType = FfiTemplate(
    'NATIVE_FIELD_INVALID_TYPE',
    "'{0}' is an unsupported type for native fields. Native fields only "
        "support pointers, arrays or numeric and compound types.",
    correctionMessage:
        "Try changing the type in the `@Native` annotation to a numeric FFI "
        "type, a pointer, array, or a compound class.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNativeFieldInvalidType,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const FfiWithoutArguments nativeFieldMissingType = FfiWithoutArguments(
    'NATIVE_FIELD_MISSING_TYPE',
    "The native type of this field could not be inferred and must be specified "
        "in the annotation.",
    correctionMessage:
        "Try adding a type parameter extending `NativeType` to the `@Native` "
        "annotation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments nativeFieldNotStatic = FfiWithoutArguments(
    'NATIVE_FIELD_NOT_STATIC',
    "Native fields must be static.",
    correctionMessage: "Try adding the modifier 'static' to this field.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments
  nativeFunctionMissingType = FfiWithoutArguments(
    'NATIVE_FUNCTION_MISSING_TYPE',
    "The native type of this function couldn't be inferred so it must be "
        "specified in the annotation.",
    correctionMessage:
        "Try adding a type parameter extending `NativeType` to the `@Native` "
        "annotation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments
  negativeVariableDimension = FfiWithoutArguments(
    'NEGATIVE_VARIABLE_DIMENSION',
    "The variable dimension of a variable-length array must be non-negative.",
    correctionMessage: "Try using a value that is zero or greater.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the function, method, or constructor having type
  ///            arguments
  static const FfiTemplate<LocatableDiagnostic Function({required String p0})>
  nonConstantTypeArgument = FfiTemplate(
    'NON_CONSTANT_TYPE_ARGUMENT',
    "The type arguments to '{0}' must be known at compile time, so they can't "
        "be type parameters.",
    correctionMessage: "Try changing the type argument to be a constant type.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNonConstantTypeArgument,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the type that should be a valid dart:ffi native type.
  static const FfiTemplate<LocatableDiagnostic Function({required DartType p0})>
  nonNativeFunctionTypeArgumentToPointer = FfiTemplate(
    'NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER',
    "Can't invoke 'asFunction' because the function signature '{0}' for the "
        "pointer isn't a valid C function signature.",
    correctionMessage:
        "Try changing the function argument in 'NativeFunction' to only use "
        "NativeTypes.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNonNativeFunctionTypeArgumentToPointer,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const FfiWithoutArguments nonPositiveArrayDimension =
      FfiWithoutArguments(
        'NON_POSITIVE_ARRAY_DIMENSION',
        "Array dimensions must be positive numbers.",
        correctionMessage: "Try changing the input to a positive number.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the field
  /// Type p1: the type of the field
  static const FfiTemplate<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  nonSizedTypeArgument = FfiTemplate(
    'NON_SIZED_TYPE_ARGUMENT',
    "The type '{1}' isn't a valid type argument for '{0}'. The type argument "
        "must be a native integer, 'Float', 'Double', 'Pointer', or subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try using a native integer, 'Float', 'Double', 'Pointer', or subtype "
        "of 'Struct', 'Union', or 'AbiSpecificInteger'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNonSizedTypeArgument,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// No parameters.
  static const FfiWithoutArguments packedAnnotation = FfiWithoutArguments(
    'PACKED_ANNOTATION',
    "Structs must have at most one 'Packed' annotation.",
    correctionMessage: "Try removing extra 'Packed' annotations.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments
  packedAnnotationAlignment = FfiWithoutArguments(
    'PACKED_ANNOTATION_ALIGNMENT',
    "Only packing to 1, 2, 4, 8, and 16 bytes is supported.",
    correctionMessage:
        "Try changing the 'Packed' annotation alignment to 1, 2, 4, 8, or 16.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const FfiWithoutArguments sizeAnnotationDimensions =
      FfiWithoutArguments(
        'SIZE_ANNOTATION_DIMENSIONS',
        "'Array's must have an 'Array' annotation that matches the dimensions.",
        correctionMessage:
            "Try adjusting the arguments in the 'Array' annotation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the class being extended, implemented, or mixed in
  static const FfiTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfStructClassInExtends = FfiTemplate(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't extend '{1}' because '{1}' is a subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS',
    withArguments: _withArgumentsSubtypeOfStructClassInExtends,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the class being extended, implemented, or mixed in
  static const FfiTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfStructClassInImplements = FfiTemplate(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't implement '{1}' because '{1}' is a subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS',
    withArguments: _withArgumentsSubtypeOfStructClassInImplements,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the class being extended, implemented, or mixed in
  static const FfiTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfStructClassInWith = FfiTemplate(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't mix in '{1}' because '{1}' is a subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_WITH',
    withArguments: _withArgumentsSubtypeOfStructClassInWith,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const FfiWithoutArguments
  variableLengthArrayNotLast = FfiWithoutArguments(
    'VARIABLE_LENGTH_ARRAY_NOT_LAST',
    "Variable length 'Array's must only occur as the last field of Structs.",
    correctionMessage: "Try adjusting the arguments in the 'Array' annotation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Initialize a newly created error code to have the given [name].
  const FfiCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required super.expectedTypes,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'FfiCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticType.COMPILE_TIME_ERROR.severity;

  @override
  DiagnosticType get type => DiagnosticType.COMPILE_TIME_ERROR;

  static LocatableDiagnostic
  _withArgumentsAbiSpecificIntegerMappingUnsupported({required String p0}) {
    return LocatableDiagnosticImpl(abiSpecificIntegerMappingUnsupported, [p0]);
  }

  static LocatableDiagnostic _withArgumentsArgumentMustBeAConstant({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(argumentMustBeAConstant, [p0]);
  }

  static LocatableDiagnostic _withArgumentsCompoundImplementsFinalizable({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(compoundImplementsFinalizable, [p0]);
  }

  static LocatableDiagnostic _withArgumentsEmptyStruct({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(emptyStruct, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsFfiNativeUnexpectedNumberOfParameters({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(ffiNativeUnexpectedNumberOfParameters, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(
      ffiNativeUnexpectedNumberOfParametersWithReceiver,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsGenericStructSubclass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(genericStructSubclass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidExceptionValue({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidExceptionValue, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidFieldTypeInStruct({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidFieldTypeInStruct, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMissingAnnotationOnStructField({
    required DartType p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(missingAnnotationOnStructField, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsMissingExceptionValue({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(missingExceptionValue, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMustBeANativeFunctionType({
    required Object p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(mustBeANativeFunctionType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsMustBeASubtype({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(mustBeASubtype, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsMustReturnVoid({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(mustReturnVoid, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNativeFieldInvalidType({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(nativeFieldInvalidType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNonConstantTypeArgument({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(nonConstantTypeArgument, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsNonNativeFunctionTypeArgumentToPointer({required DartType p0}) {
    return LocatableDiagnosticImpl(nonNativeFunctionTypeArgumentToPointer, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsNonSizedTypeArgument({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(nonSizedTypeArgument, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsSubtypeOfStructClassInExtends({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(subtypeOfStructClassInExtends, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsSubtypeOfStructClassInImplements({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(subtypeOfStructClassInImplements, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsSubtypeOfStructClassInWith({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(subtypeOfStructClassInWith, [p0, p1]);
  }
}

final class FfiTemplate<T extends Function> extends FfiCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const FfiTemplate(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class FfiWithoutArguments extends FfiCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const FfiWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
