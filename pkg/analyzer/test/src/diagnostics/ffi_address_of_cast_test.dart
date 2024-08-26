// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiAddressOfCast);
  });
}

@reflectiveTest
class FfiAddressOfCast extends PubPackageResolutionTest {
  test_struct_error_1() async {
    await assertErrorsInCode('''
import 'dart:ffi';

@Native<Void Function(Pointer<Void>)>(isLeaf: true)
external void myNative(Pointer<Void> buffer);

@Native<Void Function(Pointer<Void>)>()
external void myNonLeafNative(Pointer<Void> buffer);

main() {
  final myStruct = Struct.create<MyStruct>();
  myNative(myStruct.arr.address.cast<Int8>());
  myNonLeafNative(myStruct.arr.address.cast());
}

final class MyStruct extends Struct {
  @Int8()
  external int value;
  @Array(2)
  external Array<Int8> arr;
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 279, 33),
      error(FfiCode.ADDRESS_POSITION, 346, 7)
    ]);
  }

  test_struct_error_2() async {
    await assertErrorsInCode('''
import 'dart:ffi';

@Native<Void Function(Pointer<Void>)>(isLeaf: true)
external void myNative(Pointer<Void> buffer);

@Native<Void Function(Pointer<Void>)>()
external void myNonLeafNative(Pointer<Void> buffer);

main() {
  final myStruct = Struct.create<MyStruct>();
  myNative(myStruct.value.address.cast<Int8>());
  myNonLeafNative(myStruct.value.address.cast());
}

final class MyStruct extends Struct {
  @Int8()
  external int value;
  @Array(2)
  external Array<Int8> arr;
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 279, 35),
      error(FfiCode.ADDRESS_POSITION, 350, 7)
    ]);
  }

  test_struct_no_error() async {
    await assertNoErrorsInCode('''
import 'dart:ffi';

@Native<Void Function(Pointer<Void>)>(isLeaf: true)
external void myNative(Pointer<Void> buffer);

main() {
  final myStruct = Struct.create<MyStruct>();
  myNative(myStruct.arr.address.cast());
  myNative(myStruct.arr.address.cast<Void>());
}

final class MyStruct extends Struct {
  @Int8()
  external int value;
  @Array(2)
  external Array<Int8> arr;
}
''');
  }

  test_union_error_1() async {
    await assertErrorsInCode('''
import 'dart:ffi';

@Native<Void Function(Pointer<Void>)>(isLeaf: true)
external void myNative(Pointer<Void> buffer);

@Native<Void Function(Pointer<Void>)>()
external void myNonLeafNative(Pointer<Void> buffer);

main() {
  final myUnion = Union.create<MyUnion>();
  myNative(myUnion.arr.address.cast<Int8>());
  myNonLeafNative(myUnion.arr.address.cast());
}

final class MyUnion extends Union {
  @Int8()
  external int value;
  @Array(2)
  external Array<Int8> arr;
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 276, 32),
      error(FfiCode.ADDRESS_POSITION, 341, 7)
    ]);
  }

  test_union_error_2() async {
    await assertErrorsInCode('''
import 'dart:ffi';

@Native<Void Function(Pointer<Void>)>(isLeaf: true)
external void myNative(Pointer<Void> buffer);

@Native<Void Function(Pointer<Void>)>()
external void myNonLeafNative(Pointer<Void> buffer);

main() {
  final myUnion = Union.create<MyUnion>();
  myNative(myUnion.value.address.cast<Int8>());
  myNonLeafNative(myUnion.value.address.cast());
}
final class MyUnion extends Union {
  @Int8()
  external int value;
  @Array(2)
  external Array<Int8> arr;
      }
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 276, 34),
      error(FfiCode.ADDRESS_POSITION, 345, 7)
    ]);
  }

  test_union_no_error() async {
    await assertNoErrorsInCode('''
import 'dart:ffi';

@Native<Void Function(Pointer<Void>)>(isLeaf: true)
external void myNative(Pointer<Void> buffer);

main() {
  final myUnion = Union.create<MyUnion>();
  myNative(myUnion.arr.address.cast());
  myNative(myUnion.arr.address.cast<Void>());
}
final class MyUnion extends Union {
  @Int8()
  external int value;
  @Array(2)
  external Array<Int8> arr;
}
''');
  }

  test_typed_data_error() async {
    await assertErrorsInCode('''
import 'dart:ffi';
import 'dart:typed_data';

@Native<Void Function(Pointer<Void>)>(isLeaf: true)
external void myNative(Pointer<Void> buffer);

@Native<Void Function(Pointer<Void>)>()
external void myNonLeafNative(Pointer<Void> buffer);

main() {
  final buffer = Int8List(2);
  myNative(buffer.address.cast<Int8>());
  myNonLeafNative(buffer.address.cast());
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 289, 27),
      error(FfiCode.ADDRESS_POSITION, 344, 7)
    ]);
  }

  test_typed_data_no_error() async {
    await assertNoErrorsInCode('''
import 'dart:ffi';
import 'dart:typed_data';

@Native<Void Function(Pointer<Void>)>(isLeaf: true)
external void myNative(Pointer<Void> buffer);

main() {
  final buffer = Int8List(2);
  myNative(buffer.address.cast());
}
''');
  }
}
