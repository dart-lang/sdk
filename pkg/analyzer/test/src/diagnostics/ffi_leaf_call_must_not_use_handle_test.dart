// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LeafCallMustNotUseHandle);
  });
}

@reflectiveTest
class LeafCallMustNotUseHandle extends PubPackageResolutionTest {
  test_AsFunctionReturnsHandle() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef NativeReturnsHandle = Handle Function();
typedef ReturnsHandle = Object Function();
doThings() {
  Pointer<NativeFunction<NativeReturnsHandle>> p = Pointer.fromAddress(1337);
  ReturnsHandle f = p.asFunction(isLeaf:true);
//                    ^^^^^^^^^^
// [diag.leafCallMustNotReturnHandle] FFI leaf call can't return a 'Handle'.
  f();
}
''');
  }

  test_AsFunctionTakesHandle() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef NativeTakesHandle = Void Function(Handle);
typedef TakesHandle = void Function(Object);
class MyClass {}
doThings() {
  Pointer<NativeFunction<NativeTakesHandle>> p = Pointer.fromAddress(1337);
  TakesHandle f = p.asFunction(isLeaf:true);
//                  ^^^^^^^^^^
// [diag.leafCallMustNotTakeHandle] FFI leaf call can't take arguments of type 'Handle'.
  f(MyClass());
}
''');
  }

  test_class_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

base class NativeFieldWrapperClass1 {}

base class A extends NativeFieldWrapperClass1 {
  @Native<Handle Function(Pointer<Void>)>(symbol: 'foo', isLeaf:true)
  external Object get foo;
//                    ^^^
// [diag.leafCallMustNotReturnHandle] FFI leaf call can't return a 'Handle'.
}
''');
  }

  test_LookupFunctionReturnsHandle() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef NativeReturnsHandle = Handle Function();
typedef ReturnsHandle = Object Function();
doThings() {
  DynamicLibrary l = DynamicLibrary.open("my_lib");
  l.lookupFunction<NativeReturnsHandle, ReturnsHandle>("timesFour", isLeaf:true);
//                 ^^^^^^^^^^^^^^^^^^^
// [diag.leafCallMustNotReturnHandle] FFI leaf call can't return a 'Handle'.
}
''');
  }

  test_LookupFunctionTakesHandle() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef NativeTakesHandle = Void Function(Handle);
typedef TakesHandle = void Function(Object);
class MyClass {}
doThings() {
  DynamicLibrary l = DynamicLibrary.open("my_lib");
  l.lookupFunction<NativeTakesHandle, TakesHandle>("timesFour", isLeaf:true);
//                 ^^^^^^^^^^^^^^^^^
// [diag.leafCallMustNotTakeHandle] FFI leaf call can't take arguments of type 'Handle'.
}
''');
  }

  test_unit_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<Handle Function()>(symbol: 'foo', isLeaf:true)
external Object get foo;
//                  ^^^
// [diag.leafCallMustNotReturnHandle] FFI leaf call can't return a 'Handle'.
''');
  }
}
