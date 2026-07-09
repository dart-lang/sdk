// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See: https://dartbug.com/49502

import 'package:expect/expect.dart';

import '49502_libA.dart' deferred as libA;
import '49502_libB.dart' deferred as libB;

void main() async {
  await libA.loadLibrary();
  await libB.loadLibrary();
  test();
}

void write(dynamic x, List<int> v) => x.bar = v;

@pragma('dart2js:never-inline')
void test() {
  final a = libA.FooA();
  write(a, [41]);
  Expect.equals('A: [41]', '$a');

  final b = libB.FooB();
  write(b, [42]);
  Expect.equals('B: [42]', '$b');
}
