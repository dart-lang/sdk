// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiFromFunctionInvalidCodeTest);
  });
}

/// Exercises `_validateFromFunction` on invalid and unresolved code at each
/// argument position, so that resolution failures keep producing diagnostics
/// instead of crashing the verifier.
///
/// https://github.com/dart-lang/sdk/issues/44773
@reflectiveTest
class FfiFromFunctionInvalidCodeTest extends PubPackageResolutionTest {
  test_fromFunction_exceptionalReturn_prefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
import 'dart:math' as prefix;
int f(int x) => x;
void main() {
  Pointer.fromFunction<Int32 Function(Int32)>(f, prefix);
//                                               ^^^^^^
// [diag.prefixIdentifierNotFollowedByDot] The name 'prefix' refers to an import prefix, so it must be followed by '.'.
// [diag.mustBeASubtype] The type 'InvalidType' must be a subtype of 'Int32' for 'fromFunction'.
// [diag.argumentMustBeAConstant] Argument 'exceptionalReturn' must be a constant.
}
''');
  }

  test_fromFunction_exceptionalReturn_undefinedNamedParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int x) => x;
void main() {
  Pointer.fromFunction<Int32 Function(Int32)>(f, exceptional: 1);
//                                               ^^^^^^^^^^^
// [diag.undefinedNamedParameter] The named parameter 'exceptional' isn't defined.
}
''');
  }

  test_fromFunction_exceptionalReturn_unresolvedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int x) => x;
void main() {
  Pointer.fromFunction<Int32 Function(Int32)>(f, undefinedConst);
//                                               ^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'undefinedConst'.
// [diag.mustBeASubtype] The type 'InvalidType' must be a subtype of 'Int32' for 'fromFunction'.
// [diag.argumentMustBeAConstant] Argument 'exceptionalReturn' must be a constant.
}
''');
  }

  test_fromFunction_function_prefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
import 'dart:math' as prefix;
void main() {
  Pointer.fromFunction<Void Function()>(prefix);
//                                      ^^^^^^
// [diag.prefixIdentifierNotFollowedByDot] The name 'prefix' refers to an import prefix, so it must be followed by '.'.
// [diag.mustBeASubtype] The type 'InvalidType' must be a subtype of 'Void Function()' for 'fromFunction'.
}
''');
  }

  test_fromFunction_function_unresolvedIdentifier() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void main() {
  Pointer.fromFunction<Void Function()>(undefinedFn);
//                                      ^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'undefinedFn'.
// [diag.mustBeASubtype] The type 'InvalidType' must be a subtype of 'Void Function()' for 'fromFunction'.
}
''');
  }

  test_fromFunction_typeArgument_none() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int x) => x;
void main() {
  Pointer.fromFunction(f);
//        ^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'Function' given to 'fromFunction' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_fromFunction_typeArgument_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int x) => x;
void main() {
  Pointer.fromFunction<Unresolved Function()>(f, 0);
//                     ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
//                     ^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'InvalidType Function()' given to 'fromFunction' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_fromFunction_typeArgument_wrongCount() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int x) => x;
void main() {
  Pointer.fromFunction<Int32 Function(Int32), Int8>(f, 0);
//                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.wrongNumberOfTypeArgumentsElement] The method 'fromFunction' is declared with 1 type parameters, but 2 type arguments are given.
//                     ^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'dynamic' given to 'fromFunction' must be a valid 'dart:ffi' native function type.
}
''');
  }
}
