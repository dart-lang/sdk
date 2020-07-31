// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--deterministic --optimization-counter-threshold=10 --unbox-numeric-fields

import 'package:expect/expect.dart';

const magicDouble = 42.0;

class C {
  double d = magicDouble;
}

class NoopSink {
  void leak(C c) {}
}

class RealSink {
  static late C o;
  void leak(C c) {
    o = c;
  }
}

void foo(sink) {
  sink.leak(C());
}

void main(List<String> args) {
  var c = C();
  for (var i = 0; i < 100; i++) c.d = 2.0;

  for (var i = 0; i < 100; i++) {
    foo(NoopSink());
  }

  foo(RealSink());
  RealSink.o.d += 1234.0;
  final TWO = args.length > 1024 ? "~" : 2;
  Expect.equals(double.parse("4${TWO}.0"), magicDouble);
}
