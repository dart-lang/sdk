// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

@Native<Void Function(Pointer<Void>)>()
external void myNonLeafNative(Pointer<Void> buff);

@Native<Void Function(Pointer<Void>, Pointer<Int8>)>(isLeaf: true)
external void myNativeWith2Param(Pointer<Void> buffer, Pointer<Int8> buffer2);

@Native<Void Function(Pointer<Void>, Pointer<Int8>, Pointer<Void>)>(
  isLeaf: true,
)
external void myNativeWith3Param(
  Pointer<Void> buffer,
  Pointer<Int8> buffer2,
  Pointer<Void> buffer3,
);

void testDefinedLeaf() {
  final buffer = Int8List.fromList([1]);
  myNativeWith2Param(buffer.address, buffer.address);
  //                        ^^^^^^^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
  //                 ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE

  myNativeWith2Param(buffer.address.cast(), buffer.address.cast<Void>());
  //                                                       ^^^^^^^^^^^^
  // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.
  //                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE

  myNativeWith3Param(buffer.address, buffer.address, buffer.address.cast());
  //                        ^^^^^^^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
  //                 ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE

  // dart format off
  myNativeWith3Param(
      buffer.address.cast(),
      /* */ buffer.address.cast<Void>(),
      //                   ^^^^^^^^^^^^
      // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.
      //    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      buffer.address.cast());

  myNativeWith3Param(buffer.address.cast(), buffer.address, buffer.address);
  //                                                               ^^^^^^^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
  //                                                        ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE

  myNativeWith3Param(
      /**/ buffer.address,
      //          ^^^^^^^
      // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
      //   ^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      /**/ buffer.address.cast<Void>(),
      //                  ^^^^^^^^^^^^
      // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.
      //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      buffer.address.cast());

  myNativeWith3Param(
      buffer.address.cast(),
      /**/ buffer.address.cast<Void>(),
      //                  ^^^^^^^^^^^^
      // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.
      //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      buffer.address);
  //         ^^^^^^^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
  //  ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  myNativeWith3Param(
      /**/ buffer.address
      //          ^^^^^^^
      // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
      //   ^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      ,
      buffer.address,
      buffer.address);
  //         ^^^^^^^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
  //  ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE

  myNativeWith3Param(
      /**/ buffer.address,
      //          ^^^^^^^
      // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
      //   ^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      /**/ buffer.address.cast<Void>(),
      //                  ^^^^^^^^^^^^
      // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.
      //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      buffer.address);
  //         ^^^^^^^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
  //  ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
}
// dart format on

void testUndefinedLeaf() {
  final buffer = Int8List.fromList([1]);
  myNativeWith2Param(buffer.address.cast(), buffer.address.doesntExist);
  //                                                       ^^^^^^^^^^^
  // [cfe] The getter 'doesntExist' isn't defined for the class 'Pointer<Int8>'.
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  //                                               ^^^^^^^
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION

  myNativeWith2Param(buffer.address.cast<Int8>().doesntExist, buffer.address);
  //                                             ^^^^^^^^^^^
  // [cfe] The getter 'doesntExist' isn't defined for the class 'Pointer<Int8>'.
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  //                        ^^^^^^^
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
}

void testUndefinedNonLeaf() {
  final buffer = Int8List.fromList([1]);

  myNonLeafNative(buffer.address.cast().doesntExist);
  //                                    ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'doesntExist' isn't defined for the class 'Pointer<NativeType>'.
  //                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  myNonLeafNative(buffer.address.doesntExist);
  //                             ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'doesntExist' isn't defined for the class 'Pointer<Int8>'.
  //                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
}

void testDefinedNonLeaf() {
  final buffer = Int8List.fromList([1]);
  myNonLeafNative(buffer.address.cast().address);
  //              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                                    ^^^^^^^
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'Pointer<Void>'.
  //                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.

  myNonLeafNative(buffer.address.address);
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                             ^^^^^^^
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'Pointer<Void>'.
  //                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
}

void main() {
  testDefinedLeaf();
  testDefinedNonLeaf();

  testUndefinedLeaf();
  testUndefinedNonLeaf();
}
