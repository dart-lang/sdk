// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiAsFunctionInvalidCodeTest);
    defineReflectiveTests(NonNativeFunctionTypeArgumentToPointerTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Exercises `_validateAsFunction` with invalid types and unresolved references
/// at each input position, pinning diagnostics and guarding against crashes.
/// The `extensionOverride` and `extensionName` tests cover receivers that are
/// not expressions, which have no static type to validate.
///
/// https://github.com/dart-lang/sdk/issues/44773
@reflectiveTest
class FfiAsFunctionInvalidCodeTest extends PubPackageResolutionTest {
  test_asFunction_extensionName_staticAccess() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f() {
  NativeFunctionPointer.asFunction<void Function()>();
//                      ^^^^^^^^^^
// [diag.staticAccessToInstanceMember] Instance member 'asFunction' can't be accessed using static access.
}
''');
  }

  test_asFunction_extensionOverride_argument_invalidType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f() {
  NativeFunctionPointer(42).asFunction<void Function()>();
//                      ^^
// [diag.extensionOverrideArgumentNotAssignable] The type of the argument to the extension override 'int' isn't assignable to the extended type 'Pointer<NativeFunction<Function>>'.
}
''');
  }

  test_asFunction_extensionOverride_argument_prefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
import 'dart:math' as prefix;
void f() {
  NativeFunctionPointer(prefix).asFunction<void Function()>();
//                      ^^^^^^
// [diag.prefixIdentifierNotFollowedByDot] The name 'prefix' refers to an import prefix, so it must be followed by '.'.
}
''');
  }

  test_asFunction_extensionOverride_argument_unresolvedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f() {
  NativeFunctionPointer(undefinedPointer).asFunction<void Function()>();
//                      ^^^^^^^^^^^^^^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'undefinedPointer'.
}
''');
  }

  test_asFunction_extensionOverride_isLeaf_nonConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<Void Function()>> p, bool leaf) {
  NativeFunctionPointer(p).asFunction<void Function()>(isLeaf: leaf);
//                                                             ^^^^
// [diag.argumentMustBeAConstant] Argument 'isLeaf' must be a constant.
}
''');
  }

  test_asFunction_extensionOverride_ok() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<Void Function()>> p) {
  NativeFunctionPointer(p).asFunction<void Function()>();
}
''');
  }

  test_asFunction_extensionOverride_pointerTypeArgument_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<int> p) {
//     ^^^^^^^^^^^^
// [context 1] The inverted type 'Pointer<int>' is also not regular-bounded, so the type is not well-bounded.
//             ^^^
// [diag.typeArgumentNotMatchingBounds][context 1] 'int' doesn't conform to the bound 'NativeType' of the type parameter 'T'.
  NativeFunctionPointer(p).asFunction<void Function()>();
//                      ^
// [diag.extensionOverrideArgumentNotAssignable] The type of the argument to the extension override 'Pointer<int>' isn't assignable to the extended type 'Pointer<NativeFunction<Function>>'.
}
''');
  }

  test_asFunction_extensionOverride_pointerTypeArgument_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<Unresolved> p) {
//             ^^^^^^^^^^
// [diag.nonTypeAsTypeArgument] The name 'Unresolved' isn't a type, so it can't be used as a type argument.
  NativeFunctionPointer(p).asFunction<void Function()>();
}
''');
  }

  test_asFunction_isLeaf_invalidType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<Void Function()>> p) {
  p.asFunction<void Function()>(isLeaf: 42);
//                                      ^^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'bool'.
}
''');
  }

  test_asFunction_isLeaf_unresolvedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<Void Function()>> p) {
  p.asFunction<void Function()>(isLeaf: undefinedLeaf);
//                                      ^^^^^^^^^^^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'undefinedLeaf'.
// [diag.argumentMustBeAConstant] Argument 'isLeaf' must be a constant.
}
''');
  }

  test_asFunction_nativeFunctionTypeArgument_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<int Function()>> p) {
  p.asFunction<int Function()>();
//             ^^^^^^^^^^^^^^
// [diag.nonNativeFunctionTypeArgumentToPointer] Can't invoke 'asFunction' because the function signature 'NativeFunction<int Function()>' for the pointer isn't a valid C function signature.
}
''');
  }

  test_asFunction_nativeFunctionTypeArgument_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<Unresolved>> p) {
//                            ^^^^^^^^^^
// [diag.nonTypeAsTypeArgument] The name 'Unresolved' isn't a type, so it can't be used as a type argument.
  p.asFunction<void Function()>();
//             ^^^^^^^^^^^^^^^
// [diag.nonNativeFunctionTypeArgumentToPointer] Can't invoke 'asFunction' because the function signature 'NativeFunction<InvalidType>' for the pointer isn't a valid C function signature.
}
''');
  }

  test_asFunction_nativeFunctionTypeArgument_wrongCount() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<Void Function(), Int32>> p) {
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'NativeFunction' is declared with 1 type parameters, but 2 type arguments were given.
  p.asFunction<void Function()>();
//             ^^^^^^^^^^^^^^^
// [diag.nonNativeFunctionTypeArgumentToPointer] Can't invoke 'asFunction' because the function signature 'NativeFunction<InvalidType>' for the pointer isn't a valid C function signature.
}
''');
  }

  test_asFunction_typeArgument_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<Void Function()>> p) {
  p.asFunction<int>();
//^^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Void Function()' must be a subtype of 'int' for 'asFunction'.
//             ^^^
// [diag.typeArgumentNotMatchingBounds] 'int' doesn't conform to the bound 'Function' of the type parameter 'DF'.
}
''');
  }

  test_asFunction_typeArgument_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<Void Function()>> p) {
  p.asFunction<Unresolved>();
//^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Void Function()' must be a subtype of 'InvalidType' for 'asFunction'.
//             ^^^^^^^^^^
// [diag.nonTypeAsTypeArgument] The name 'Unresolved' isn't a type, so it can't be used as a type argument.
}
''');
  }

  test_asFunction_typeArgument_wrongCount() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(Pointer<NativeFunction<Void Function()>> p) {
  p.asFunction<void Function(), int>();
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Void Function()' must be a subtype of 'dynamic' for 'asFunction'.
//            ^^^^^^^^^^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'asFunction' is declared with 1 type parameters, but 2 type arguments are given.
}
''');
  }
}

@reflectiveTest
class NonNativeFunctionTypeArgumentToPointerTest
    extends PubPackageResolutionTest {
  test_asFunction_1() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef R = Int8 Function(Int8);
class C {
  void f(Pointer<Double> p) {
    p.asFunction<R>();
//    ^^^^^^^^^^
// [diag.undefinedInstanceMemberReadNotFound] The member 'asFunction' isn't defined for the type 'Pointer<Double>'.
  }
}
''');
  }

  test_asFunction_2() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef TPrime = int Function(int);
typedef F = String Function(String);
class C {
  void f(Pointer<NativeFunction<TPrime>> p) {
    p.asFunction<F>();
//               ^
// [diag.nonNativeFunctionTypeArgumentToPointer] Can't invoke 'asFunction' because the function signature 'NativeFunction<TPrime>' for the pointer isn't a valid C function signature.
  }
}
''');
  }

  test_asFunction_F() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef R = int Function(int);
class C<T extends Function> {
  void f(Pointer<NativeFunction<T>> p) {
    p.asFunction<R>();
//  ^
// [diag.nonConstantTypeArgument] The type arguments to 'asFunction' must be known at compile time, so they can't be type parameters.
  }
}
''');
  }

  test_asFunction_Pointer_Opaque() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
main() {
  DynamicLibrary.open('dontcare')
      .lookup<NativeFunction<Void Function(Pointer<Opaque>)>>('dontcare')
      .asFunction<void Function(Pointer<Opaque>)>(isLeaf: true);
}
''');
  }
}
