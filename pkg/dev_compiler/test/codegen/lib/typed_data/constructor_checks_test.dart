// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

checkLengthConstructors() {
  check(creator) {
    Expect.throws(() => creator(null));
    Expect.throws(() => creator(8.5));
    Expect.throws(() => creator('10'));
    var a = creator(10);
    Expect.equals(10, a.length);
  }

  check((a) => new Float32List(a));
  check((a) => new Float64List(a));
  check((a) => new Int8List(a));
  check((a) => new Int8List(a));
  check((a) => new Int16List(a));
  check((a) => new Int32List(a));
  check((a) => new Uint8List(a));
  check((a) => new Uint16List(a));
  check((a) => new Uint32List(a));
}

checkViewConstructors() {
  var buffer = new Int8List(256).buffer;

  check1(creator) {
    Expect.throws(() => creator(10));
    Expect.throws(() => creator(null));
    var a = creator(buffer);
    Expect.equals(buffer, a.buffer);
  }

  check2(creator) {
    Expect.throws(() => creator(10, 0));
    Expect.throws(() => creator(null, 0));
    Expect.throws(() => creator(buffer, null));
    Expect.throws(() => creator(buffer, '8'));
    var a = creator(buffer, 8);
    Expect.equals(buffer, a.buffer);
  }

  check1((a) => new Float32List.view(a));
  check1((a) => new Float64List.view(a));
  check1((a) => new Int8List.view(a));
  check1((a) => new Int8List.view(a));
  check1((a) => new Int16List.view(a));
  check1((a) => new Int32List.view(a));
  check1((a) => new Uint8List.view(a));
  check1((a) => new Uint16List.view(a));
  check1((a) => new Uint32List.view(a));

  check2((a, b) => new Float32List.view(a, b));
  check2((a, b) => new Float64List.view(a, b));
  check2((a, b) => new Int8List.view(a, b));
  check2((a, b) => new Int8List.view(a, b));
  check2((a, b) => new Int16List.view(a, b));
  check2((a, b) => new Int32List.view(a, b));
  check2((a, b) => new Uint8List.view(a, b));
  check2((a, b) => new Uint16List.view(a, b));
  check2((a, b) => new Uint32List.view(a, b));
}

main() {
  checkLengthConstructors();
  checkViewConstructors();
}
