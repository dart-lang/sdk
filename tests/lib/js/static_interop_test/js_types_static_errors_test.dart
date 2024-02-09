// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that JS types are not typedefs and are actual separate types. This
// makes sure that users can't assign unrelated types to the JS type without a
// conversion.

import 'dart:js_interop';
import 'dart:typed_data';

class DartObject {}

void main() {
  // [JSAny] != [Object]
  ((JSAny jsAny) {})(DartObject() as Object);
  //                 ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                              ^
  // [web] The argument type 'Object' can't be assigned to the parameter type 'JSAny'.

  // [JSObject] != [Object]
  ((JSObject jsObj) {})(DartObject() as Object);
  //                    ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                                 ^
  // [web] The argument type 'Object' can't be assigned to the parameter type 'JSObject'.

  // [JSFunction] != [Function]
  ((JSFunction jsFun) {})(() {} as Function);
  //                      ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                            ^
  // [web] The argument type 'Function' can't be assigned to the parameter type 'JSFunction'.

  // [JSExportedDartFunction] != [Function]
  ((JSExportedDartFunction jsFun) {})(() {} as Function);
  //                                  ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                                        ^
  // [web] The argument type 'Function' can't be assigned to the parameter type 'JSExportedDartFunction'.

  // [JSBoxedDartObject] != [Object]
  ((JSBoxedDartObject jsObj) {})(DartObject());
  //                             ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'DartObject' can't be assigned to the parameter type 'JSBoxedDartObject'.

  // [JSArray] != [List<JSAny?>]
  List<JSAny?> dartArr = <JSAny?>[1.0.toJS, 'foo'.toJS];
  ((JSArray jsArr) {})(dartArr);
  //                   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'List<JSAny?>' can't be assigned to the parameter type 'JSArray<JSAny?>'.

  // [JSArrayBuffer] != [ByteBuffer]
  ByteBuffer dartBuf = Uint8List.fromList([0, 255, 0, 255]).buffer;
  ((JSArrayBuffer jsBuf) {})(dartBuf);
  //                         ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'ByteBuffer' can't be assigned to the parameter type 'JSArrayBuffer'.

  // [JSDataView] != [ByteData]
  ByteData dartDat = Uint8List.fromList([0, 255, 0, 255]).buffer.asByteData();
  ((JSDataView jsDat) {})(dartDat);
  //                      ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'ByteData' can't be assigned to the parameter type 'JSDataView'.

  // [JSTypedArray]s != [TypedData]s
  TypedData typedData = Int8List.fromList([-128, 0, 127]);
  ((JSTypedArray jsTypedArray) {})(typedData);
  //                               ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'TypedData' can't be assigned to the parameter type 'JSTypedArray'.

  // [JSInt8Array]s != [Int8List]s
  Int8List ai8 = Int8List.fromList([-128, 0, 127]);
  ((JSInt8Array jsAi8) {})(ai8);
  //                       ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Int8List' can't be assigned to the parameter type 'JSInt8Array'.

  // [JSUint8Array] != [Uint8List]
  Uint8List au8 = Uint8List.fromList([-1, 0, 255, 256]);
  ((JSUint8Array jsAu8) {})(au8);
  //                        ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Uint8List' can't be assigned to the parameter type 'JSUint8Array'.

  // [JSUint8ClampedArray] != [Uint8ClampedList]
  Uint8ClampedList ac8 = Uint8ClampedList.fromList([-1, 0, 255, 256]);
  ((JSUint8ClampedArray jsAc8) {})(ac8);
  //                               ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Uint8ClampedList' can't be assigned to the parameter type 'JSUint8ClampedArray'.

  // [JSInt16Array] != [Int16List]
  Int16List ai16 = Int16List.fromList([-32769, -32768, 0, 32767, 32768]);
  ((JSInt16Array jsAi16) {})(ai16);
  //                         ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Int16List' can't be assigned to the parameter type 'JSInt16Array'.

  // [JSUint16Array] != [Uint16List]
  Uint16List au16 = Uint16List.fromList([-1, 0, 65535, 65536]);
  ((JSUint16Array jsAu16) {})(au16);
  //                          ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Uint16List' can't be assigned to the parameter type 'JSUint16Array'.

  // [JSInt32Array] != [Int32List]
  Int32List ai32 = Int32List.fromList([-2147483648, 0, 2147483647]);
  ((JSInt32Array jsAi32) {})(ai32);
  //                         ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Int32List' can't be assigned to the parameter type 'JSInt32Array'.

  // [JSUint32Array] != [Uint32List]
  Uint32List au32 = Uint32List.fromList([-1, 0, 4294967295, 4294967296]);
  ((JSUint32Array jsAu32) {})(au32);
  //                          ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Uint32List' can't be assigned to the parameter type 'JSUint32Array'.

  // [JSFloat32Array] != [Float32List]
  Float32List af32 =
      Float32List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]);
  ((JSFloat32Array jsAf32) {})(af32);
  //                           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Float32List' can't be assigned to the parameter type 'JSFloat32Array'.

  // [JSFloat64Array] != [Float64List]
  Float64List af64 =
      Float64List.fromList([-1000.488, -0.00001, 0.0001, 10004.888]);
  ((JSFloat64Array jsAf64) {})(af64);
  //                           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Float64List' can't be assigned to the parameter type 'JSFloat64Array'.

  // [JSNumber] != [double]
  ((JSNumber jsNum) {})(4.5);
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'double' can't be assigned to the parameter type 'JSNumber'.

  // [JSBoolean] != [bool]
  ((JSBoolean jsBool) {})(true);
  //                      ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'bool' can't be assigned to the parameter type 'JSBoolean'.

  // [JSString] != [String]
  ((JSString jsStr) {})('foo');
  //                    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'String' can't be assigned to the parameter type 'JSString'.

  // [JSPromise] != [Future]
  ((JSPromise promise) {})(Future<void>.delayed(Duration.zero));
  //                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [web] The argument type 'Future<void>' can't be assigned to the parameter type 'JSPromise<JSAny?>'.
}
