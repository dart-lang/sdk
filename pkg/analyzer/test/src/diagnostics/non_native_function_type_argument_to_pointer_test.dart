// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNativeFunctionTypeArgumentToPointerTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
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
// [diag.undefinedMethod] The method 'asFunction' isn't defined for the type 'Pointer'.
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
