// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentMustBeAConstantTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ArgumentMustBeAConstantTest extends PubPackageResolutionTest {
  test_AsFunctionIsLeafGlobal() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef Int8UnOp = Int8 Function(Int8);
typedef IntUnOp = int Function(int);
bool isLeaf = false;
doThings() {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = p.asFunction(isLeaf:isLeaf);
//                                ^^^^^^
// [diag.argumentMustBeAConstant] Argument 'isLeaf' must be a constant.
  f(8);
}
''');
  }

  test_AsFunctionIsLeafLocal() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef Int8UnOp = Int8 Function(Int8);
typedef IntUnOp = int Function(int);
doThings() {
  bool isLeaf = false;
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = p.asFunction(isLeaf:isLeaf);
//                                ^^^^^^
// [diag.argumentMustBeAConstant] Argument 'isLeaf' must be a constant.
  f(8);
}
''');
  }

  test_AsFunctionIsLeafParam() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef Int8UnOp = Int8 Function(Int8);
typedef IntUnOp = int Function(int);
doThings(bool isLeaf) {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = p.asFunction(isLeaf:isLeaf);
//                                ^^^^^^
// [diag.argumentMustBeAConstant] Argument 'isLeaf' must be a constant.
  f(8);
}
''');
  }

  test_FromFunctionExceptionReturn() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef NativeDoubleUnOp = Double Function(Double);
double myTimesThree(double d) => d * 3;
void testFromFunctionFunctionExceptionValueMustBeConst() {
  final notAConst = 1.1;
  Pointer.fromFunction<NativeDoubleUnOp>(myTimesThree, notAConst);
//                                                     ^^^^^^^^^
// [diag.argumentMustBeAConstant] Argument 'exceptionalReturn' must be a constant.
}
''');
  }

  test_LookupFunctionIsLeaf() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef Int8UnOp = Int8 Function(Int8);
typedef IntUnOp = int Function(int);
doThings(bool isLeaf) {
  DynamicLibrary l = DynamicLibrary.open("my_lib");
  l.lookupFunction<Int8UnOp, IntUnOp>("timesFour", isLeaf:isLeaf);
//                                                        ^^^^^^
// [diag.argumentMustBeAConstant] Argument 'isLeaf' must be a constant.
}
''');
  }
}
