// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:expect/expect.dart';

/// Check that normal dynamic invariant enforcement applies for arguments,
/// also with these constructors of built-in types.
checkLengthConstructors() {
  check(creator) {
    Expect.throws(() => creator(null));
    Expect.throws(() => creator(8.5));
    Expect.throws(() => creator('10'));
    var a = creator(10);
    Expect.equals(10, a.length);
  }

  check((a) => Float32List(a));
  check((a) => Float64List(a));
  check((a) => Int8List(a));
  check((a) => Int8List(a));
  check((a) => Int16List(a));
  check((a) => Int32List(a));
  check((a) => Uint8List(a));
  check((a) => Uint16List(a));
  check((a) => Uint32List(a));
}

checkViewConstructors() {
  var buffer = Int8List(256).buffer;

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

  check1((a) => Float32List.view(a));
  check1((a) => Float64List.view(a));
  check1((a) => Int8List.view(a));
  check1((a) => Int8List.view(a));
  check1((a) => Int16List.view(a));
  check1((a) => Int32List.view(a));
  check1((a) => Uint8List.view(a));
  check1((a) => Uint16List.view(a));
  check1((a) => Uint32List.view(a));

  check2((a, b) => Float32List.view(a, b));
  check2((a, b) => Float64List.view(a, b));
  check2((a, b) => Int8List.view(a, b));
  check2((a, b) => Int8List.view(a, b));
  check2((a, b) => Int16List.view(a, b));
  check2((a, b) => Int32List.view(a, b));
  check2((a, b) => Uint8List.view(a, b));
  check2((a, b) => Uint16List.view(a, b));
  check2((a, b) => Uint32List.view(a, b));
}

main() {
  checkLengthConstructors();
  checkViewConstructors();
}
