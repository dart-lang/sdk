// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing native typed arrays, int64 and uint64 only.

// Library tag to be able to run in html test framework.
library TypedArray;
import "package:expect/expect.dart";
import 'dart:isolate';
import 'dart:typed_data';

void main() {
  int64_receiver();
  uint64_receiver();
}

// Int64 array.
Int64List initInt64() {
  var int64 = new Int64List(2);
  int64[0] = 10000000;
  int64[1] = 100000000;
  return int64;
}
Int64List int64 = initInt64();

void int64_receiver() {
  var sp = spawnFunction(int64_sender);
  sp.call(int64.length).then((a) {
    Expect.equals(int64.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(int64[i], a[i]);
    }
    print("int64_receiver");
  });
}

int64_sender() {
  port.receive((len, r) {
    Expect.equals(int64.length, len);
    var a = new Int64List(len);
    for (int i = 0; i < len; i++) {
      a[i] = int64[i];
    }
    r.send(a);
  });
}


// Uint64 array.
Uint64List initUint64() {
  var uint64 = new Uint64List(2);
  uint64[0] = 0xffffffffffffffff;
  uint64[1] = 0x7fffffffffffffff;
  return uint64;
}
Uint64List uint64 = initUint64();

void uint64_receiver() {
  var sp = spawnFunction(uint64_sender);
  sp.call(uint64.length).then((a) {
    Expect.equals(uint64.length, a.length);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(uint64[i], a[i]);
    }
    print("uint64_receiver");
  });
}

uint64_sender() {
  port.receive((len, r) {
    Expect.equals(uint64.length, len);
    var a = new Uint64List(len);
    for (int i = 0; i < len; i++) {
      a[i] = uint64[i];
    }
    r.send(a);
  });
}
