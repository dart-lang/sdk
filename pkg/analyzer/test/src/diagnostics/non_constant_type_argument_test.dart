// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantTypeArgumentNoWarningTest);
    defineReflectiveTests(NonConstantTypeArgumentNoWarningTest2);
    defineReflectiveTests(NonConstantTypeArgumentTest);
    defineReflectiveTests(NonConstantTypeArgumentWarningTest);
  });
}

@reflectiveTest
class NonConstantTypeArgumentNoWarningTest extends PubPackageResolutionTest {
  test_asFunction_R() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

class MyStruct extends Struct {
  @Uint8()
  int myField;
}

void main(){
  final pointer = Pointer<MyStruct>.fromAddress(0);
  pointer.ref.myField = 1;
}
''');
  }
}

@reflectiveTest
class NonConstantTypeArgumentNoWarningTest2 extends PubPackageResolutionTest {
  test_asFunction_R() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

class MyStruct extends Struct {
  @Uint8()
  int myField;
}

void main(){
  final pointer = Pointer<MyStruct>.fromAddress(0)
    ..ref.myField = 1;
  print(pointer);
}
''');
  }
}

@reflectiveTest
class NonConstantTypeArgumentTest extends PubPackageResolutionTest {
  test_asFunction_R() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef T = int Function(int);
class C<R extends int Function(int)> {
  void f(Pointer<NativeFunction<T>> p) {
    p.asFunction<R>();
  }
}
''', [
      error(FfiCode.NON_CONSTANT_TYPE_ARGUMENT, 147, 1),
    ]);
  }
}

@reflectiveTest
class NonConstantTypeArgumentWarningTest extends PubPackageResolutionTest {
  test_asFunction_R() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

T genericRef<T extends Struct>(Pointer<T> p) =>
    p.ref;
''', [error(FfiCode.NON_CONSTANT_TYPE_ARGUMENT_WARNING, 72, 5)]);
  }
}
