// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class K implements L {
  final field1;
  final field2;
  const K({this.field1: 42, this.field2: true});
}

class L {
  const factory L() = K;
  const factory L.named1({field1, field2}) = K;
  const factory L.named2({field2, field1}) = K;
}

const K l1 = const L() as K;

const K l2a = const L.named1() as K;
const K l2b = const L.named1(field1: 87) as K;
const K l2c = const L.named1(field2: false) as K;
const K l2d = const L.named1(field1: 87, field2: false) as K;
const K l2e = const L.named1(field2: false, field1: 87) as K;

const K l3a = const L.named2() as K;
const K l3b = const L.named2(field1: 87) as K;
const K l3c = const L.named2(field2: false) as K;
const K l3d = const L.named2(field1: 87, field2: false) as K;
const K l3e = const L.named2(field2: false, field1: 87) as K;

main() {
  Expect.equals(42, l1.field1);
  Expect.equals(true, l1.field2);

  Expect.equals(42, l2a.field1);
  Expect.equals(true, l2a.field2);
  Expect.equals(87, l2b.field1);
  Expect.equals(true, l2b.field2);
  Expect.equals(42, l2c.field1);
  Expect.equals(false, l2c.field2);
  Expect.equals(87, l2d.field1);
  Expect.equals(false, l2d.field2);
  Expect.equals(87, l2e.field1);
  Expect.equals(false, l2e.field2);

  Expect.equals(42, l3a.field1);
  Expect.equals(true, l3a.field2);
  Expect.equals(87, l3b.field1);
  Expect.equals(true, l3b.field2);
  Expect.equals(42, l3c.field1);
  Expect.equals(false, l3c.field2);
  Expect.equals(87, l3d.field1);
  Expect.equals(false, l3d.field2);
  Expect.equals(87, l3e.field1);
  Expect.equals(false, l3e.field2);
}
