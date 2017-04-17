// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_tests;

import 'package:expect/expect.dart';
import 'dart:convert';

class A {
  final x;
  A(this.x);
}

toEncodable(A a) => {"A": a.x};
reviver(key, value) {
  if (value is Map && value.length == 1 && value["A"] != null) {
    return new A(value["A"]);
  }
  return value;
}

const extendedJson =
    const JsonCodec(toEncodable: toEncodable, reviver: reviver);

main() {
  var encoded = extendedJson.encode([
    new A(0),
    {"2": new A(1)}
  ]);
  Expect.equals('[{"A":0},{"2":{"A":1}}]', encoded);
  var decoded = extendedJson.decode(encoded);
  Expect.isTrue(decoded is List);
  Expect.equals(2, decoded.length);
  Expect.isTrue(decoded[0] is A);
  Expect.equals(0, decoded[0].x);
  Expect.isTrue(decoded[1] is Map);
  Expect.isNotNull(decoded[1]["2"]);
  Expect.isTrue(decoded[1]["2"] is A);
  Expect.equals(1, decoded[1]["2"].x);

  var a = extendedJson.decode(extendedJson.encode(new A(499)));
  Expect.isTrue(a is A);
  Expect.equals(499, a.x);

  testInvalidMap();
}

void testInvalidMap() {
  var map = {"a": 42, "b": 42, 37: 42}; // Non-string key.
  var enc = new JsonEncoder((_) => "fixed");
  var res = enc.convert(map);
  Expect.equals('"fixed"', res);

  enc = new JsonEncoder.withIndent(" ", (_) => "fixed");
  res = enc.convert(map);
  Expect.equals('"fixed"', res);
}
