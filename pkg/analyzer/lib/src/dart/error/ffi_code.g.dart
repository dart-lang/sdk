// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart pkg/analyzer/tool/messages/generate.dart' to update.

import "package:analyzer/error/error.dart";
import "package:analyzer/src/error/analyzer_error_code.dart";

// It is hard to visually separate each code's _doc comment_ from its published
// _documentation comment_ when each is written as an end-of-line comment.
// ignore_for_file: slash_for_doc_comments

class FfiCode extends AnalyzerErrorCode {
  /**
   * No parameters.
   */
  static const FfiCode ABI_SPECIFIC_INTEGER_INVALID = FfiCode(
    'ABI_SPECIFIC_INTEGER_INVALID',
    "Classes extending 'AbiSpecificInteger' must have exactly one const "
        "constructor, no other members, and no type arguments.",
    correctionMessage:
        "Try removing all type arguments, removing all members, and adding one "
        "const constructor.",
  );

  /**
   * No parameters.
   */
  static const FfiCode ABI_SPECIFIC_INTEGER_MAPPING_EXTRA = FfiCode(
    'ABI_SPECIFIC_INTEGER_MAPPING_EXTRA',
    "Classes extending 'AbiSpecificInteger' must have exactly one "
        "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
        "ABI to a 'NativeType' integer with a fixed size.",
    correctionMessage: "Try removing the extra annotation.",
  );

  /**
   * No parameters.
   */
  static const FfiCode ABI_SPECIFIC_INTEGER_MAPPING_MISSING = FfiCode(
    'ABI_SPECIFIC_INTEGER_MAPPING_MISSING',
    "Classes extending 'AbiSpecificInteger' must have exactly one "
        "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
        "ABI to a 'NativeType' integer with a fixed size.",
    correctionMessage: "Try adding an annotation.",
  );

  /**
   * No parameters.
   */
  static const FfiCode ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED = FfiCode(
    'ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED',
    "Only mappings to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', 'Uint16', "
        "'UInt32', and 'Uint64' are supported.",
    correctionMessage:
        "Try changing the value to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', "
        "'Uint16', 'UInt32', or 'Uint64'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field that's declared in a
  // subclass of `Struct` and has the type `Pointer` also has an annotation
  // associated with it.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `p`, which
  // has the type `Pointer` and is declared in a subclass of `Struct`, has the
  // annotation `@Double()`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   [!@Double()!]
  //   external Pointer<Int8> p;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the annotations from the field:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   external Pointer<Int8> p;
  // }
  // ```
  static const FfiCode ANNOTATION_ON_POINTER_FIELD = FfiCode(
    'ANNOTATION_ON_POINTER_FIELD',
    "Fields in a struct class whose type is 'Pointer' shouldn't have any "
        "annotations.",
    correctionMessage: "Try removing the annotation.",
  );

  /**
   * Parameters:
   * 0: the name of the argument
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an invocation of either
  // `Pointer.asFunction` or `DynamicLibrary.lookupFunction` has an `isLeaf`
  // argument whose value isn't a constant expression.
  //
  // The analyzer also produces this diagnostic when the value of the
  // `exceptionalReturn` argument of `Pointer.fromFunction`.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the value of the
  // `isLeaf` argument is a parameter, and hence isn't a constant:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // int Function(int) fromPointer(
  //     Pointer<NativeFunction<Int8 Function(Int8)>> p, bool isLeaf) {
  //   return p.asFunction(isLeaf: [!isLeaf!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If there's a suitable constant that can be used, then replace the argument
  // with a constant:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // const isLeaf = false;
  //
  // int Function(int) fromPointer(Pointer<NativeFunction<Int8 Function(Int8)>> p) {
  //   return p.asFunction(isLeaf: isLeaf);
  // }
  // ```
  //
  // If there isn't a suitable constant, then replace the argument with a
  // boolean literal:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // int Function(int) fromPointer(Pointer<NativeFunction<Int8 Function(Int8)>> p) {
  //   return p.asFunction(isLeaf: true);
  // }
  // ```
  static const FfiCode ARGUMENT_MUST_BE_A_CONSTANT = FfiCode(
    'ARGUMENT_MUST_BE_A_CONSTANT',
    "Argument '{0}' must be a constant.",
    correctionMessage: "Try replacing the value with a literal or const.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a subclass of either `Struct`
  // or `Union` is instantiated using a generative constructor.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `C` is being
  // instantiated using a generative constructor:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int32()
  //   external int a;
  // }
  //
  // void f() {
  //   [!C!]();
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you need to allocate the structure described by the class, then use the
  // `ffi` package to do so:
  //
  // ```dart
  // import 'dart:ffi';
  // import 'package:ffi/ffi.dart';
  //
  // class C extends Struct {
  //   @Int32()
  //   external int a;
  // }
  //
  // void f() {
  //   final pointer = calloc.allocate<C>(4);
  //   final c = pointer.ref;
  //   print(c);
  //   calloc.free(pointer);
  // }
  // ```
  static const FfiCode CREATION_OF_STRUCT_OR_UNION = FfiCode(
    'CREATION_OF_STRUCT_OR_UNION',
    "Subclasses of 'Struct' and 'Union' are backed by native memory, and can't "
        "be instantiated by a generative constructor.",
    correctionMessage:
        "Try allocating it via allocation, or load from a 'Pointer'.",
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the superclass
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a subclass of `Struct` or
  // `Union` doesn't have any fields. Having an empty `Struct` or `Union`
  // isn't supported.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `C`, which
  // extends `Struct`, doesn't declare any fields:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class [!C!] extends Struct {}
  // ```
  //
  // #### Common fixes
  //
  // If the class is intended to be a struct, then declare one or more fields:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int32()
  //   external int x;
  // }
  // ```
  //
  // If the class is intended to be used as a type argument to `Pointer`, then
  // make it a subclass of `Opaque`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Opaque {}
  // ```
  //
  // If the class isn't intended to be a struct, then remove or change the
  // extends clause:
  //
  // ```dart
  // class C {}
  // ```
  static const FfiCode EMPTY_STRUCT = FfiCode(
    'EMPTY_STRUCT',
    "The class '{0}' can't be empty because it's a subclass of '{1}'.",
    correctionMessage:
        "Try adding a field to '{0}' or use a different superclass.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field in a subclass of
  // `Struct` has more than one annotation describing the native type of the
  // field.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `x` has two
  // annotations describing the native type of the field:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int32()
  //   [!@Int16()!]
  //   external int x;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove all but one of the annotations:
  //
  // ```dart
  // import 'dart:ffi';
  // class C extends Struct {
  //   @Int32()
  //   external int x;
  // }
  // ```
  static const FfiCode EXTRA_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
    'EXTRA_ANNOTATION_ON_STRUCT_FIELD',
    "Fields in a struct class must have exactly one annotation indicating the "
        "native type.",
    correctionMessage: "Try removing the extra annotation.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field in a subclass of
  // `Struct` has more than one annotation describing the size of the native
  // array.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `a0` has two
  // annotations that specify the size of the native array:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Array(4)
  //   [!@Array(8)!]
  //   external Array<Uint8> a0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove all but one of the annotations:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Array(8)
  //   external Array<Uint8> a0;
  // }
  // ```
  static const FfiCode EXTRA_SIZE_ANNOTATION_CARRAY = FfiCode(
    'EXTRA_SIZE_ANNOTATION_CARRAY',
    "'Array's must have exactly one 'Array' annotation.",
    correctionMessage: "Try removing the extra annotation.",
  );

  /**
   * No parameters.
   */
  static const FfiCode FFI_NATIVE_MUST_BE_EXTERNAL = FfiCode(
    'FFI_NATIVE_MUST_BE_EXTERNAL',
    "FfiNative functions must be declared external.",
    correctionMessage: "Add the `external` keyword to the function.",
  );

  /**
   * No parameters.
   */
  static const FfiCode
      FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER =
      FfiCode(
    'FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER',
    "Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.",
    correctionMessage: "Pass as Handle instead.",
  );

  /**
   * Parameters:
   * 0: the expected number of parameters
   * 1: the actual number of parameters
   */
  static const FfiCode FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS = FfiCode(
    'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS',
    "Unexpected number of FfiNative annotation parameters. Expected {0} but "
        "has {1}.",
    correctionMessage: "Make sure parameters match the function annotated.",
  );

  /**
   * Parameters:
   * 0: the expected number of parameters
   * 1: the actual number of parameters
   */
  static const FfiCode
      FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER = FfiCode(
    'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER',
    "Unexpected number of FfiNative annotation parameters. Expected {0} but "
        "has {1}. FfiNative instance method annotation must have receiver as "
        "first argument.",
    correctionMessage:
        "Make sure parameters match the function annotated, including an extra "
        "first parameter for the receiver.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a constructor in a subclass of
  // either `Struct` or `Union` has one or more field initializers.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `C` has a
  // constructor with an initializer for the field `f`:
  //
  // ```dart
  // // @dart = 2.9
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int32()
  //   int f;
  //
  //   C() : [!f = 0!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the field initializer:
  //
  // ```dart
  // // @dart = 2.9
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int32()
  //   int f;
  //
  //   C();
  // }
  // ```
  static const FfiCode FIELD_INITIALIZER_IN_STRUCT = FfiCode(
    'FIELD_INITIALIZER_IN_STRUCT',
    "Constructors in subclasses of 'Struct' and 'Union' can't have field "
        "initializers.",
    correctionMessage:
        "Try removing the field initializer and marking the field as external.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field in a subclass of
  // `Struct` has an initializer.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `p` has an
  // initializer:
  //
  // ```dart
  // // @dart = 2.9
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   Pointer [!p!] = nullptr;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the initializer:
  //
  // ```dart
  // // @dart = 2.9
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   Pointer p;
  // }
  // ```
  static const FfiCode FIELD_IN_STRUCT_WITH_INITIALIZER = FfiCode(
    'FIELD_IN_STRUCT_WITH_INITIALIZER',
    "Fields in subclasses of 'Struct' and 'Union' can't have initializers.",
    correctionMessage:
        "Try removing the initializer and marking the field as external.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field in a subclass of either
  // `Struct` or `Union` isn't marked as being `external`.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `a` isn't
  // marked as being `external`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int16()
  //   int [!a!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add the required `external` modifier:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int16()
  //   external int a;
  // }
  // ```
  static const FfiCode FIELD_MUST_BE_EXTERNAL_IN_STRUCT = FfiCode(
    'FIELD_MUST_BE_EXTERNAL_IN_STRUCT',
    "Fields of 'Struct' and 'Union' subclasses must be marked external.",
    correctionMessage: "Try adding the 'external' modifier.",
  );

  /**
   * Parameters:
   * 0: the name of the struct class
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a subclass of either `Struct`
  // or `Union` has a type parameter.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `S` defines
  // the type parameter `T`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class [!S!]<T> extends Struct {
  //   external Pointer notEmpty;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the type parameters from the class:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class S extends Struct {
  //   external Pointer notEmpty;
  // }
  // ```
  static const FfiCode GENERIC_STRUCT_SUBCLASS = FfiCode(
    'GENERIC_STRUCT_SUBCLASS',
    "The class '{0}' can't extend 'Struct' or 'Union' because '{0}' is "
        "generic.",
    correctionMessage: "Try removing the type parameters from '{0}'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an invocation of the method
  // `Pointer.fromFunction` has a second argument (the exceptional return
  // value) and the type to be returned from the invocation is either `void`,
  // `Handle` or `Pointer`.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because a second argument is
  // provided when the return type of `f` is `void`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // typedef T = Void Function(Int8);
  //
  // void f(int i) {}
  //
  // void g() {
  //   Pointer.fromFunction<T>(f, [!42!]);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove the exception value:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // typedef T = Void Function(Int8);
  //
  // void f(int i) {}
  //
  // void g() {
  //   Pointer.fromFunction<T>(f);
  // }
  // ```
  static const FfiCode INVALID_EXCEPTION_VALUE = FfiCode(
    'INVALID_EXCEPTION_VALUE',
    "The method 'Pointer.fromFunction' can't have an exceptional return value "
        "(the second argument) when the return type of the function is either "
        "'void', 'Handle' or 'Pointer'.",
    correctionMessage: "Try removing the exceptional return value.",
  );

  /**
   * Parameters:
   * 0: the type of the field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field in a subclass of
  // `Struct` has a type other than `int`, `double`, `Array`, `Pointer`, or
  // subtype of `Struct` or `Union`.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `str` has
  // the type `String`, which isn't one of the allowed types for fields in a
  // subclass of `Struct`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   external [!String!] s;
  //
  //   @Int32()
  //   external int i;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Use one of the allowed types for the field:
  //
  // ```dart
  // import 'dart:ffi';
  // import 'package:ffi/ffi.dart';
  //
  // class C extends Struct {
  //   external Pointer<Utf8> s;
  //
  //   @Int32()
  //   external int i;
  // }
  // ```
  static const FfiCode INVALID_FIELD_TYPE_IN_STRUCT = FfiCode(
    'INVALID_FIELD_TYPE_IN_STRUCT',
    "Fields in struct classes can't have the type '{0}'. They can only be "
        "declared as 'int', 'double', 'Array', 'Pointer', or subtype of "
        "'Struct' or 'Union'.",
    correctionMessage:
        "Try using 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' "
        "or 'Union'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the value of the `isLeaf`
  // argument in an invocation of either `Pointer.asFunction` or
  // `DynamicLibrary.lookupFunction` is `true` and the function that would be
  // returned would have a return type of `Handle`.
  //
  // The analyzer also produces this diagnostic when the value of the `isLeaf`
  // argument in an `FfiNative` annotation is `true` and the type argument on
  // the annotation is a function type whose return type is `Handle`.
  //
  // In all of these cases, leaf calls are only supported for the types `bool`,
  // `int`, `float`, `double`, and, as a return type `void`.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the function `p`
  // returns a `Handle`, but the `isLeaf` argument is `true`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // void f(Pointer<NativeFunction<Handle Function()>> p) {
  //   [!p.asFunction<Object Function()>(isLeaf: true)!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the function returns a handle, then remove the `isLeaf` argument:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // void f(Pointer<NativeFunction<Handle Function()>> p) {
  //   p.asFunction<Object Function()>();
  // }
  // ```
  //
  // If the function returns one of the supported types, then correct the type
  // information:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // void f(Pointer<NativeFunction<Int32 Function()>> p) {
  //   p.asFunction<int Function()>(isLeaf: true);
  // }
  // ```
  static const FfiCode LEAF_CALL_MUST_NOT_RETURN_HANDLE = FfiCode(
    'LEAF_CALL_MUST_NOT_RETURN_HANDLE',
    "FFI leaf call can't return a 'Handle'.",
    correctionMessage: "Try changing the return type to primitive or struct.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the value of the `isLeaf`
  // argument in an invocation of either `Pointer.asFunction` or
  // `DynamicLibrary.lookupFunction` is `true` and the function that would be
  // returned would have a parameter of type `Handle`.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the function `p` has a
  // parameter of type `Handle`, but the `isLeaf` argument is `true`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // void f(Pointer<NativeFunction<Void Function(Handle)>> p) {
  //   [!p.asFunction<void Function(Object)>(isLeaf: true)!];
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the function has at least one parameter of type `Handle`, then remove
  // the `isLeaf` argument:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // void f(Pointer<NativeFunction<Void Function(Handle)>> p) {
  //   p.asFunction<void Function(Object)>();
  // }
  // ```
  //
  // If none of the function's parameters are `Handle`s, then correct the type
  // information:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // void f(Pointer<NativeFunction<Void Function(Int8)>> p) {
  //   p.asFunction<void Function(int)>(isLeaf: true);
  // }
  // ```
  static const FfiCode LEAF_CALL_MUST_NOT_TAKE_HANDLE = FfiCode(
    'LEAF_CALL_MUST_NOT_TAKE_HANDLE',
    "FFI leaf call can't take arguments of type 'Handle'.",
    correctionMessage: "Try changing the argument type to primitive or struct.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the annotation on a field in a
  // subclass of `Struct` or `Union` doesn't match the Dart type of the field.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the annotation
  // `Double` doesn't match the Dart type `int`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   [!@Double()!]
  //   external int x;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the type of the field is correct, then change the annotation to match:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int32()
  //   external int x;
  // }
  // ```
  //
  // If the annotation is correct, then change the type of the field to match:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Double()
  //   external double x;
  // }
  // ```
  static const FfiCode MISMATCHED_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
    'MISMATCHED_ANNOTATION_ON_STRUCT_FIELD',
    "The annotation doesn't match the declared type of the field.",
    correctionMessage:
        "Try using a different annotation or changing the declared type to "
        "match.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field in a subclass of
  // `Struct` or `Union` whose type requires an annotation doesn't have one.
  // The Dart types `int`, `double`, and `Array` are used to represent multiple
  // C types, and the annotation specifies which of the compatible C types the
  // field represents.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `x` doesn't
  // have an annotation indicating the underlying width of the integer value:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   external [!int!] x;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add an appropriate annotation to the field:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int64()
  //   external int x;
  // }
  // ```
  static const FfiCode MISSING_ANNOTATION_ON_STRUCT_FIELD = FfiCode(
    'MISSING_ANNOTATION_ON_STRUCT_FIELD',
    "Fields in a struct class must either have the type 'Pointer' or an "
        "annotation indicating the native type.",
    correctionMessage: "Try adding an annotation.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an invocation of the method
  // `Pointer.fromFunction` doesn't have a second argument (the exceptional
  // return value) when the type to be returned from the invocation is neither
  // `void`, `Handle`, nor `Pointer`.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type returned by
  // `f` is expected to be an 8-bit integer but the call to `fromFunction`
  // doesn't include an exceptional return argument:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // int f(int i) => i * 2;
  //
  // void g() {
  //   Pointer.[!fromFunction!]<Int8 Function(Int8)>(f);
  // }
  // ```
  //
  // #### Common fixes
  //
  // Add an exceptional return type:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // int f(int i) => i * 2;
  //
  // void g() {
  //   Pointer.fromFunction<Int8 Function(Int8)>(f, 0);
  // }
  // ```
  static const FfiCode MISSING_EXCEPTION_VALUE = FfiCode(
    'MISSING_EXCEPTION_VALUE',
    "The method 'Pointer.fromFunction' must have an exceptional return value "
        "(the second argument) when the return type of the function is neither "
        "'void', 'Handle', nor 'Pointer'.",
    correctionMessage: "Try adding an exceptional return value.",
  );

  /**
   * Parameters:
   * 0: the type of the field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field in a subclass of
  // `Struct` or `Union` doesn't have a type annotation. Every field must have
  // an explicit type, and the type must either be `int`, `double`, `Pointer`,
  // or a subclass of either `Struct` or `Union`.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `str`
  // doesn't have a type annotation:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   external var [!str!];
  //
  //   @Int32()
  //   external int i;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Explicitly specify the type of the field:
  //
  // ```dart
  // import 'dart:ffi';
  // import 'package:ffi/ffi.dart';
  //
  // class C extends Struct {
  //   external Pointer<Utf8> str;
  //
  //   @Int32()
  //   external int i;
  // }
  // ```
  static const FfiCode MISSING_FIELD_TYPE_IN_STRUCT = FfiCode(
    'MISSING_FIELD_TYPE_IN_STRUCT',
    "Fields in struct classes must have an explicitly declared type of 'int', "
        "'double' or 'Pointer'.",
    correctionMessage: "Try using 'int', 'double' or 'Pointer'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a field in a subclass of either
  // `Struct` or `Union` has a type of `Array` but doesn't have a single
  // `Array` annotation indicating the dimensions of the array.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `a0` doesn't
  // have an `Array` annotation:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   external [!Array<Uint8>!] a0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Ensure that there's exactly one `Array` annotation on the field:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Array(8)
  //   external Array<Uint8> a0;
  // }
  // ```
  static const FfiCode MISSING_SIZE_ANNOTATION_CARRAY = FfiCode(
    'MISSING_SIZE_ANNOTATION_CARRAY',
    "Fields of type 'Array' must have exactly one 'Array' annotation.",
    correctionMessage:
        "Try adding an 'Array' annotation, or removing all but one of the "
        "annotations.",
  );

  /**
   * Parameters:
   * 0: the type that should be a valid dart:ffi native type.
   * 1: the name of the function whose invocation depends on this relationship
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when an invocation of either
  // `Pointer.fromFunction` or `DynamicLibrary.lookupFunction` has a type
  // argument(whether explicit or inferred) that isn't a native function type.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type `T` can be
  // any subclass of `Function` but the type argument for `fromFunction` is
  // required to be a native function type:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // int f(int i) => i * 2;
  //
  // class C<T extends Function> {
  //   void g() {
  //     Pointer.fromFunction<[!T!]>(f, 0);
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Use a native function type as the type argument to the invocation:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // int f(int i) => i * 2;
  //
  // class C<T extends Function> {
  //   void g() {
  //     Pointer.fromFunction<Int32 Function(Int32)>(f, 0);
  //   }
  // }
  // ```
  static const FfiCode MUST_BE_A_NATIVE_FUNCTION_TYPE = FfiCode(
    'MUST_BE_A_NATIVE_FUNCTION_TYPE',
    "The type '{0}' given to '{1}' must be a valid 'dart:ffi' native function "
        "type.",
    correctionMessage:
        "Try changing the type to only use members for 'dart:ffi'.",
  );

  /**
   * Parameters:
   * 0: the type that should be a subtype
   * 1: the supertype that the subtype is compared to
   * 2: the name of the function whose invocation depends on this relationship
   */
  // #### Description
  //
  // The analyzer produces this diagnostic in two cases:
  // - In an invocation of `Pointer.fromFunction` where the type argument
  //   (whether explicit or inferred) isn't a supertype of the type of the
  //   function passed as the first argument to the method.
  // - In an invocation of `DynamicLibrary.lookupFunction` where the first type
  //   argument isn't a supertype of the second type argument.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type of the
  // function `f` (`String Function(int)`) isn't a subtype of the type
  // argument `T` (`Int8 Function(Int8)`):
  //
  // ```dart
  // import 'dart:ffi';
  //
  // typedef T = Int8 Function(Int8);
  //
  // double f(double i) => i;
  //
  // void g() {
  //   Pointer.fromFunction<T>([!f!], 5.0);
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the function is correct, then change the type argument to match:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // typedef T = Float Function(Float);
  //
  // double f(double i) => i;
  //
  // void g() {
  //   Pointer.fromFunction<T>(f, 5.0);
  // }
  // ```
  //
  // If the type argument is correct, then change the function to match:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // typedef T = Int8 Function(Int8);
  //
  // int f(int i) => i;
  //
  // void g() {
  //   Pointer.fromFunction<T>(f, 5);
  // }
  // ```
  static const FfiCode MUST_BE_A_SUBTYPE = FfiCode(
    'MUST_BE_A_SUBTYPE',
    "The type '{0}' must be a subtype of '{1}' for '{2}'.",
    correctionMessage: "Try changing one or both of the type arguments.",
  );

  /**
   * Parameters:
   * 0: the name of the function, method, or constructor having type arguments
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type arguments to a method
  // are required to be known at compile time, but a type parameter, whose
  // value can't be known at compile time, is used as a type argument.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type argument to
  // `Pointer.asFunction` must be known at compile time, but the type parameter
  // `R`, which isn't known at compile time, is being used as the type
  // argument:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // typedef T = int Function(int);
  //
  // class C<R extends T> {
  //   void m(Pointer<NativeFunction<T>> p) {
  //     p.asFunction<[!R!]>();
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove any uses of type parameters:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C {
  //   void m(Pointer<NativeFunction<Int64 Function(Int64)>> p) {
  //     p.asFunction<int Function(int)>();
  //   }
  // }
  // ```
  static const FfiCode NON_CONSTANT_TYPE_ARGUMENT = FfiCode(
    'NON_CONSTANT_TYPE_ARGUMENT',
    "The type arguments to '{0}' must be known at compile time, so they can't "
        "be type parameters.",
    correctionMessage: "Try changing the type argument to be a constant type.",
  );

  /**
   * Parameters:
   * 0: the type that should be a valid dart:ffi native type.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the method `asFunction` is
  // invoked on a pointer to a native function, but the signature of the native
  // function isn't a valid C function signature.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because function signature
  // associated with the pointer `p` (`FNative`) isn't a valid C function
  // signature:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // typedef FNative = int Function(int);
  // typedef F = int Function(int);
  //
  // class C {
  //   void f(Pointer<NativeFunction<FNative>> p) {
  //     p.asFunction<[!F!]>();
  //   }
  // }
  // ```
  //
  // #### Common fixes
  //
  // Make the `NativeFunction` signature a valid C signature:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // typedef FNative = Int8 Function(Int8);
  // typedef F = int Function(int);
  //
  // class C {
  //   void f(Pointer<NativeFunction<FNative>> p) {
  //     p.asFunction<F>();
  //   }
  // }
  // ```
  static const FfiCode NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER = FfiCode(
    'NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER',
    "Can't invoke 'asFunction' because the function signature '{0}' for the "
        "pointer isn't a valid C function signature.",
    correctionMessage:
        "Try changing the function argument in 'NativeFunction' to only use "
        "NativeTypes.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a dimension given in an `Array`
  // annotation is less than or equal to zero (`0`).
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because an array dimension of
  // `-1` was provided:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class MyStruct extends Struct {
  //   @Array([!-8!])
  //   external Array<Uint8> a0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the dimension to be a positive integer:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class MyStruct extends Struct {
  //   @Array(8)
  //   external Array<Uint8> a0;
  // }
  // ```
  static const FfiCode NON_POSITIVE_ARRAY_DIMENSION = FfiCode(
    'NON_POSITIVE_ARRAY_DIMENSION',
    "Array dimensions must be positive numbers.",
    correctionMessage: "Try changing the input to a positive number.",
  );

  /**
   * Parameters:
   * 0: the type of the field
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the type argument for the class
  // `Array` isn't one of the valid types: either a native integer, `Float`,
  // `Double`, `Pointer`, or subtype of `Struct`, `Union`, or
  // `AbiSpecificInteger`.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the type argument to
  // `Array` is `Void`, and `Void` isn't one of the valid types:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Array(8)
  //   external Array<[!Void!]> a0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the type argument to one of the valid types:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Array(8)
  //   external Array<Uint8> a0;
  // }
  // ```
  static const FfiCode NON_SIZED_TYPE_ARGUMENT = FfiCode(
    'NON_SIZED_TYPE_ARGUMENT',
    "The type '{1}' isn't a valid type argument for '{0}'. The type argument "
        "must be a native integer, 'Float', 'Double', 'Pointer', or subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try using a native integer, 'Float', 'Double', 'Pointer', or subtype "
        "of 'Struct', 'Union', or 'AbiSpecificInteger'.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a subclass of `Struct` has more
  // than one `Packed` annotation.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `C`, which
  // is a subclass of `Struct`, has two `Packed` annotations:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // @Packed(1)
  // [!@Packed(1)!]
  // class C extends Struct {
  //   external Pointer<Uint8> notEmpty;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Remove all but one of the annotations:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // @Packed(1)
  // class C extends Struct {
  //   external Pointer<Uint8> notEmpty;
  // }
  // ```
  static const FfiCode PACKED_ANNOTATION = FfiCode(
    'PACKED_ANNOTATION',
    "Structs must have at most one 'Packed' annotation.",
    correctionMessage: "Try removing extra 'Packed' annotations.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the argument to the `Packed`
  // annotation isn't one of the allowed values: 1, 2, 4, 8, or 16.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the argument to the
  // `Packed` annotation (`3`) isn't one of the allowed values:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // @Packed([!3!])
  // class C extends Struct {
  //   external Pointer<Uint8> notEmpty;
  // }
  // ```
  //
  // #### Common fixes
  //
  // Change the alignment to be one of the allowed values:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // @Packed(4)
  // class C extends Struct {
  //   external Pointer<Uint8> notEmpty;
  // }
  // ```
  static const FfiCode PACKED_ANNOTATION_ALIGNMENT = FfiCode(
    'PACKED_ANNOTATION_ALIGNMENT',
    "Only packing to 1, 2, 4, 8, and 16 bytes is supported.",
    correctionMessage:
        "Try changing the 'Packed' annotation alignment to 1, 2, 4, 8, or 16.",
  );

  /**
   * Parameters:
   * 0: the name of the outer struct
   * 1: the name of the struct being nested
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a subclass of `Struct` that is
  // annotated as being `Packed` declares a field whose type is also a subclass
  // of `Struct` and the field's type is either not packed or is packed less
  // tightly.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `Outer`,
  // which is a subclass of `Struct` and is packed on 1-byte boundaries,
  // declared a field whose type (`Inner`) is packed on 8-byte boundaries:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // @Packed(8)
  // class Inner extends Struct {
  //   external Pointer<Uint8> notEmpty;
  // }
  //
  // @Packed(1)
  // class Outer extends Struct {
  //   external Pointer<Uint8> notEmpty;
  //
  //   external [!Inner!] nestedLooselyPacked;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the inner struct should be packed more tightly, then change the
  // argument to the inner struct's `Packed` annotation:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // @Packed(1)
  // class Inner extends Struct {
  //   external Pointer<Uint8> notEmpty;
  // }
  //
  // @Packed(1)
  // class Outer extends Struct {
  //   external Pointer<Uint8> notEmpty;
  //
  //   external Inner nestedLooselyPacked;
  // }
  // ```
  //
  // If the outer struct should be packed less tightly, then change the
  // argument to the outer struct's `Packed` annotation:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // @Packed(8)
  // class Inner extends Struct {
  //   external Pointer<Uint8> notEmpty;
  // }
  //
  // @Packed(8)
  // class Outer extends Struct {
  //   external Pointer<Uint8> notEmpty;
  //
  //   external Inner nestedLooselyPacked;
  // }
  // ```
  //
  // If the inner struct doesn't have an annotation and should be packed, then
  // add an annotation.
  //
  // If the inner struct doesn't have an annotation and the outer struct
  // shouldn't be packed, then remove its annotation.
  static const FfiCode PACKED_NESTING_NON_PACKED = FfiCode(
    'PACKED_NESTING_NON_PACKED',
    "Nesting the non-packed or less tightly packed struct '{0}' in a packed "
        "struct '{1}' isn't supported.",
    correctionMessage:
        "Try packing the nested struct or packing the nested struct more "
        "tightly.",
  );

  /**
   * No parameters.
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when the number of dimensions
  // specified in an `Array` annotation doesn't match the number of nested
  // arrays specified by the type of a field.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the field `a0` has a
  // type with three nested arrays, but only two dimensions are given in the
  // `Array` annotation:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   [!@Array(8, 8)!]
  //   external Array<Array<Array<Uint8>>> a0;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If the type of the field is correct, then fix the annotation to have the
  // required number of dimensions:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Array(8, 8, 4)
  //   external Array<Array<Array<Uint8>>> a0;
  // }
  // ```
  //
  // If the type of the field is wrong, then fix the type of the field:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Array(8, 8)
  //   external Array<Array<Uint8>> a0;
  // }
  // ```
  static const FfiCode SIZE_ANNOTATION_DIMENSIONS = FfiCode(
    'SIZE_ANNOTATION_DIMENSIONS',
    "'Array's must have an 'Array' annotation that matches the dimensions.",
    correctionMessage: "Try adjusting the arguments in the 'Array' annotation.",
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class extends any FFI class
  // other than `Struct` or `Union`, or implements or mixes in any FFI class.
  // `Struct` and `Union` are the only FFI classes that can be subtyped, and
  // then only by extending them.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `C` extends
  // `Double`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends [!Double!] {}
  // ```
  //
  // #### Common fixes
  //
  // If the class should extend either `Struct` or `Union`, then change the
  // declaration of the class:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class C extends Struct {
  //   @Int32()
  //   external int i;
  // }
  // ```
  //
  // If the class shouldn't extend either `Struct` or `Union`, then remove any
  // references to FFI classes:
  //
  // ```dart
  // class C {}
  // ```
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_EXTENDS = FfiCode(
    'SUBTYPE_OF_FFI_CLASS',
    "The class '{0}' can't extend '{1}'.",
    correctionMessage: "Try extending 'Struct' or 'Union'.",
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_EXTENDS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS = FfiCode(
    'SUBTYPE_OF_FFI_CLASS',
    "The class '{0}' can't implement '{1}'.",
    correctionMessage: "Try implementing 'Allocator' or 'Finalizable'.",
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_FFI_CLASS_IN_WITH = FfiCode(
    'SUBTYPE_OF_FFI_CLASS',
    "The class '{0}' can't mix in '{1}'.",
    correctionMessage: "Try extending 'Struct' or 'Union'.",
    uniqueName: 'SUBTYPE_OF_FFI_CLASS_IN_WITH',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  // #### Description
  //
  // The analyzer produces this diagnostic when a class extends, implements, or
  // mixes in a class that extends either `Struct` or `Union`. Classes can only
  // extend either `Struct` or `Union` directly.
  //
  // For more information about FFI, see [C interop using dart:ffi][].
  //
  // #### Example
  //
  // The following code produces this diagnostic because the class `C` extends
  // `S`, and `S` extends `Struct`:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class S extends Struct {
  //   external Pointer f;
  // }
  //
  // class C extends [!S!] {
  //   external Pointer g;
  // }
  // ```
  //
  // #### Common fixes
  //
  // If you're trying to define a struct or union that shares some fields
  // declared by a different struct or union, then extend `Struct` or `Union`
  // directly and copy the shared fields:
  //
  // ```dart
  // import 'dart:ffi';
  //
  // class S extends Struct {
  //   external Pointer f;
  // }
  //
  // class C extends Struct {
  //   external Pointer f;
  //
  //   external Pointer g;
  // }
  // ```
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS = FfiCode(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't extend '{1}' because '{1}' is a subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS = FfiCode(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't implement '{1}' because '{1}' is a subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS',
  );

  /**
   * Parameters:
   * 0: the name of the subclass
   * 1: the name of the class being extended, implemented, or mixed in
   */
  static const FfiCode SUBTYPE_OF_STRUCT_CLASS_IN_WITH = FfiCode(
    'SUBTYPE_OF_STRUCT_CLASS',
    "The class '{0}' can't mix in '{1}' because '{1}' is a subtype of "
        "'Struct', 'Union', or 'AbiSpecificInteger'.",
    correctionMessage:
        "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
    uniqueName: 'SUBTYPE_OF_STRUCT_CLASS_IN_WITH',
  );

  /// Initialize a newly created error code to have the given [name].
  const FfiCode(
    String name,
    String problemMessage, {
    String? correctionMessage,
    bool hasPublishedDocs = false,
    bool isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          correctionMessage: correctionMessage,
          hasPublishedDocs: hasPublishedDocs,
          isUnresolvedIdentifier: isUnresolvedIdentifier,
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'FfiCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}
