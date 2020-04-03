// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Verifies that large BigInt can be passed through a message port and
// simple arithmetic operations still work after that.
// This is a regression test for https://github.com/dart-lang/sdk/issues/34752.

import 'dart:io';
import 'dart:isolate';

import "package:expect/expect.dart";

const int kValue = 12345678;
const int kShift = 8192 * 8;

void verify(BigInt x) {
  BigInt y = x >> kShift;
  Expect.equals("$kValue", "$y");
}

void main() {
  BigInt big = BigInt.from(kValue) << kShift;
  verify(big);

  final rp = new ReceivePort();
  rp.listen((dynamic data) {
    BigInt received = data as BigInt;
    verify(received);
    BigInt x = received + BigInt.one - BigInt.one;
    verify(x);
    print("ok");
    exit(0);
  });
  rp.sendPort.send(big);
}
