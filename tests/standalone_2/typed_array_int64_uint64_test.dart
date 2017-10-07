// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native typed arrays, int64 and uint64 only.

// Library tag to be able to run in html test framework.
library TypedArray;

import "package:expect/expect.dart";
import 'package:async_helper/async_helper.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

main() {
  test(int64_receiver);
  test(uint64_receiver);
}

test(f) {
  asyncStart();
  return f().whenComplete(asyncEnd);
}

// Int64 array.
Int64List initInt64() {
  var int64 = new Int64List(2);
  int64[0] = 10000000;
  int64[1] = 100000000;
  return int64;
}

Int64List int64 = initInt64();

int64_receiver() {
  var response = new ReceivePort();
  var remote = Isolate.spawn(int64_sender, [int64.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(int64.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(int64[i], a[i]);
    }
    print("int64_receiver");
    asyncEnd();
  });
}

int64_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(int64.length, len);
  var a = new Int64List(len);
  for (int i = 0; i < len; i++) {
    a[i] = int64[i];
  }
  r.send(a);
}

// Uint64 array.
Uint64List initUint64() {
  var uint64 = new Uint64List(2);
  uint64[0] = 0xffffffffffffffff;
  uint64[1] = 0x7fffffffffffffff;
  return uint64;
}

Uint64List uint64 = initUint64();

uint64_receiver() {
  var response = new ReceivePort();
  var remote = Isolate.spawn(uint64_sender, [uint64.length, response.sendPort]);
  asyncStart();
  return response.first.then((a) {
    Expect.equals(uint64.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(uint64[i], a[i]);
    }
    print("uint64_receiver");
    asyncEnd();
  });
}

uint64_sender(message) {
  var len = message[0];
  var r = message[1];
  Expect.equals(uint64.length, len);
  var a = new Uint64List(len);
  for (int i = 0; i < len; i++) {
    a[i] = uint64[i];
  }
  r.send(a);
}
