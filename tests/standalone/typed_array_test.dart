// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native float and int arrays.  64-bit int arrays
// are in a separate test.

// Library tag to be able to run in html test framework.
library TypedArray;

import "package:expect/expect.dart";
import 'package:async_helper/async_helper.dart';
import 'dart:isolate';
import 'dart:typed_data';

void main() {
  test(int8_receiver);
  test(uint8_receiver);
  test(int16_receiver);
  test(uint16_receiver);
  test(int32_receiver);
  test(uint32_receiver);
  // int64 and uint64 in separate test.
  test(float32_receiver);
  test(float64_receiver);
}

test(f) {
  asyncStart();
  return f().whenComplete(asyncEnd);
}

// Int8 array.
Int8List initInt8() {
  var int8 = new Int8List(2);
  int8[0] = 10;
  int8[1] = 100;
  return int8;
}

Int8List int8 = initInt8();

int8_receiver() {
  var response = new ReceivePort();
  var remote = Isolate.spawn(int8_sender, [int8.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(int8.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(int8[i], a[i]);
    }
    print("int8_receiver");
    asyncEnd();
  });
}

int8_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(int8.length, len);
  var a = new Int8List(len);
  for (int i = 0; i < len; i++) {
    a[i] = int8[i];
  }
  r.send(a);
}

// Uint8 array.
Uint8List initUint8() {
  var uint8 = new Uint8List(2);
  uint8[0] = 0xff;
  uint8[1] = 0x7f;
  return uint8;
}

Uint8List uint8 = initUint8();

uint8_receiver() {
  var response = new ReceivePort();
  var remote = Isolate.spawn(uint8_sender, [uint8.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(uint8.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(uint8[i], a[i]);
    }
    print("uint8_receiver");
    asyncEnd();
  });
}

uint8_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(uint8.length, len);
  var a = new Uint8List(len);
  for (int i = 0; i < len; i++) {
    a[i] = uint8[i];
  }
  r.send(a);
}

// Int16 array.
Int16List initInt16() {
  var int16 = new Int16List(2);
  int16[0] = 1000;
  int16[1] = 10000;
  return int16;
}

Int16List int16 = initInt16();

int16_receiver() {
  var response = new ReceivePort();
  var remote = Isolate.spawn(int16_sender, [int16.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(int16.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(int16[i], a[i]);
    }
    print("int16_receiver");
    asyncEnd();
  });
}

int16_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(int16.length, len);
  var a = new Int16List(len);
  for (int i = 0; i < len; i++) {
    a[i] = int16[i];
  }
  r.send(a);
}

// Uint16 array.
Uint16List initUint16() {
  var uint16 = new Uint16List(2);
  uint16[0] = 0xffff;
  uint16[1] = 0x7fff;
  return uint16;
}

Uint16List uint16 = initUint16();

uint16_receiver() {
  var response = new ReceivePort();
  var remote = Isolate.spawn(uint16_sender, [uint16.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(uint16.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(uint16[i], a[i]);
    }
    print("uint16_receiver");
    asyncEnd();
  });
}

uint16_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(uint16.length, len);
  var a = new Uint16List(len);
  for (int i = 0; i < len; i++) {
    a[i] = uint16[i];
  }
  r.send(a);
}

// Int32 array.
Int32List initInt32() {
  var int32 = new Int32List(2);
  int32[0] = 100000;
  int32[1] = 1000000;
  return int32;
}

Int32List int32 = initInt32();

int32_receiver() {
  var response = new ReceivePort();
  var remote = Isolate.spawn(int32_sender, [int32.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(int32.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(int32[i], a[i]);
    }
    print("int32_receiver");
    asyncEnd();
  });
}

int32_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(int32.length, len);
  var a = new Int32List(len);
  for (int i = 0; i < len; i++) {
    a[i] = int32[i];
  }
  r.send(a);
}

// Uint32 array.
Uint32List initUint32() {
  var uint32 = new Uint32List(2);
  uint32[0] = 0xffffffff;
  uint32[1] = 0x7fffffff;
  return uint32;
}

Uint32List uint32 = initUint32();

uint32_receiver() {
  var response = new ReceivePort();
  var remote = Isolate.spawn(uint32_sender, [uint32.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(uint32.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(uint32[i], a[i]);
    }
    print("uint32_receiver");
    asyncEnd();
  });
}

uint32_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(uint32.length, len);
  var a = new Uint32List(len);
  for (int i = 0; i < len; i++) {
    a[i] = uint32[i];
  }
  r.send(a);
}

// Float32 Array.
Float32List initFloat32() {
  var float32 = new Float32List(2);
  float32[0] = 1.0;
  float32[1] = 2.0;
  return float32;
}

Float32List float32 = initFloat32();

float32_receiver() {
  var response = new ReceivePort();
  var remote =
      Isolate.spawn(float32_sender, [float32.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(float32.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(float32[i], a[i]);
    }
    print("float32_receiver");
    asyncEnd();
  });
}

float32_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(float32.length, len);
  var a = new Float32List(len);
  for (int i = 0; i < len; i++) {
    a[i] = float32[i];
  }
  r.send(a);
}

// Float64 Array.
Float64List initFloat64() {
  var float64 = new Float64List(2);
  float64[0] = 101.234;
  float64[1] = 201.765;
  return float64;
}

Float64List float64 = initFloat64();

float64_receiver() {
  var response = new ReceivePort();
  var remote =
      Isolate.spawn(float64_sender, [float64.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(float64.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(float64[i], a[i]);
    }
    print("float64_receiver");
    asyncEnd();
  });
}

float64_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(float64.length, len);
  var a = new Float64List(len);
  for (int i = 0; i < len; i++) {
    a[i] = float64[i];
  }
  r.send(a);
}
