// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Verifies that large typed data can be passed in a field through message port.
// This is a regression test for
// https://github.com/flutter/flutter/issues/22796.

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import "package:expect/expect.dart";

class A {
  // TFA thinks this field has type _Int32List but sending an object across
  // a message port creates an instance that has _ExternalInt32List inside.
  final _int32Array = new Int32List(5 * 1024);
  A() {
    _int32Array.setRange(
        0, _int32Array.length, Iterable.generate(_int32Array.length));
    verify();
  }

  void verify() {
    for (var i = 0; i < _int32Array.length; i++) {
      if (_int32Array[i] != i) {
        print('_int32Array[$i]: ${_int32Array[i]} != ${i}');
      }
      Expect.equals(i, _int32Array[i]);
    }
  }
}

void main() {
  final rp = new ReceivePort();
  rp.listen((dynamic data) {
    (data as A).verify();
    print("ok");
    exit(0);
  });
  rp.sendPort.send(A());
}
