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
  //                 ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                        ^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.

  myNativeWith2Param(buffer.address.cast(), buffer.address.cast<Void>());
  //                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                                                       ^
  // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.

  myNativeWith3Param(buffer.address, buffer.address, buffer.address.cast());
  //                 ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                        ^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.

  // dart format off
  myNativeWith3Param(
      buffer.address.cast(),
      /* */ buffer.address.cast<Void>(),
      //    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      //                   ^
      // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.
      buffer.address.cast());

  myNativeWith3Param(buffer.address.cast(), buffer.address, buffer.address);
  //                                                        ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                                                               ^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.

  myNativeWith3Param(
      /**/ buffer.address,
      //   ^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      //          ^
      // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
      /**/ buffer.address.cast<Void>(),
      //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      //                  ^
      // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.
      buffer.address.cast());

  myNativeWith3Param(
      buffer.address.cast(),
      /**/ buffer.address.cast<Void>(),
      //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      //                  ^
      // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.
      buffer.address);
  //  ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //         ^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
  myNativeWith3Param(
      /**/ buffer.address
      //   ^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      //          ^
      // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
      ,
      buffer.address,
      buffer.address);
  //  ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //         ^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.

  myNativeWith3Param(
      /**/ buffer.address,
      //   ^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      //          ^
      // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
      /**/ buffer.address.cast<Void>(),
      //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      //                  ^
      // [cfe] The argument type 'Pointer<Void>' can't be assigned to the parameter type 'Pointer<Int8>'.
      buffer.address);
  //  ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //         ^
  // [cfe] The argument type 'Pointer<Int8>' can't be assigned to the parameter type 'Pointer<Void>'.
}
// dart format on

void testUndefinedLeaf() {
  final buffer = Int8List.fromList([1]);
  myNativeWith2Param(buffer.address.cast(), buffer.address.doesntExist);
  //                                               ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  //                                                       ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'doesntExist' isn't defined for the type 'Pointer<Int8>'.

  myNativeWith2Param(buffer.address.cast<Int8>().doesntExist, buffer.address);
  //                        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  //                                             ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'doesntExist' isn't defined for the type 'Pointer<Int8>'.
}

void testUndefinedNonLeaf() {
  final buffer = Int8List.fromList([1]);

  myNonLeafNative(buffer.address.cast().doesntExist);
  //                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  //                                    ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'doesntExist' isn't defined for the type 'Pointer<NativeType>'.
  myNonLeafNative(buffer.address.doesntExist);
  //                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  //                             ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'doesntExist' isn't defined for the type 'Pointer<Int8>'.
}

void testDefinedNonLeaf() {
  final buffer = Int8List.fromList([1]);
  myNonLeafNative(buffer.address.cast().address);
  //              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  //                                    ^
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'Pointer<Void>'.

  myNonLeafNative(buffer.address.address);
  //              ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ADDRESS_POSITION
  // [cfe] The '.address' expression can only be used as argument to a leaf native external call.
  //                             ^
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'Pointer<Void>'.
}

void main() {
  testDefinedLeaf();
  testDefinedNonLeaf();

  testUndefinedLeaf();
  testUndefinedNonLeaf();
}
