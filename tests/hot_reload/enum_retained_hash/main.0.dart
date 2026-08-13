// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2464

enum A {
  A1(B.B1, 1),
  A2(null, 2),
  A3(B.B3, 3);

  const A(this.a, this.x);
  final a;
  final x;
}

enum B {
  B1(C.C1),
  B2(C.C2),
  B3(null);

  const B(this.b);
  final b;
}

enum C {
  C1(null),
  C2(A.A2),
  C3(A.A3);

  const C(this.c);
  final c;
}

var a1;
var a1_hash;
var a2;
var a2_hash;
var a3;
var a3_hash;
var b1;
var b1_hash;
var b2;
var b2_hash;
var b3;
var b3_hash;
var c1;
var c1_hash;
var c2;
var c2_hash;
var c3;
var c3_hash;

Future<void> main() async {
  a1 = A.A1;
  a1_hash = a1.hashCode;
  a2 = A.A2;
  a2_hash = a2.hashCode;
  a3 = A.A3;
  a3_hash = a3.hashCode;
  b1 = B.B1;
  b1_hash = b1.hashCode;
  b2 = B.B2;
  b2_hash = b2.hashCode;
  b3 = B.B3;
  b3_hash = b3.hashCode;
  c1 = C.C1;
  c1_hash = c1.hashCode;
  c2 = C.C2;
  c2_hash = c2.hashCode;
  c3 = C.C3;
  c3_hash = c3.hashCode;
  await hotReload();

  Expect.identical(a1, A.A1, 'i-a1');
  Expect.equals(a1.hashCode, A.A1.hashCode, 'h-a1');
  Expect.identical(a2, A.A2, 'i-a2');
  Expect.equals(a2.hashCode, A.A2.hashCode, 'h-a2');
  Expect.identical(a3, A.A3, 'i-a3');
  Expect.equals(a3.hashCode, A.A3.hashCode, 'h-a3');

  Expect.identical(b1, B.B1, 'i-b1');
  Expect.equals(b1.hashCode, B.B1.hashCode, 'h-b1');
  Expect.identical(b2, B.B2, 'i-b2');
  Expect.equals(b2.hashCode, B.B2.hashCode, 'h-b2');
  Expect.identical(b3, B.B3, 'i-b3');
  Expect.equals(b3.hashCode, B.B3.hashCode, 'h-b3');

  Expect.identical(c1, C.C1, 'i-c1');
  Expect.equals(c1.hashCode, C.C1.hashCode, 'h-c1');
  Expect.identical(c2, C.C2, 'i-c2');
  Expect.equals(c2.hashCode, C.C2.hashCode, 'h-c2');
  Expect.identical(c3, C.C3, 'i-c3');
  Expect.equals(c3.hashCode, C.C3.hashCode, 'h-c3');
}
