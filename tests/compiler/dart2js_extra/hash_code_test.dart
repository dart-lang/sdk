// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// dart2js specific test to make sure hashCode on intercepted types behaves as
// intended.

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

class Hasher {
  hash(x) => confuse(x).hashCode;
}

// Hashing via [hash] should be forced to use the general interceptor, but the
// local x.hashCode calls might be optimized.
var hash = new Hasher().hash;

check(value1, value2, {identityHashCode}) {
  var h1 = hash(value1);
  var h2 = hash(value2);
  Expect.isTrue(h1 is int);
  Expect.isTrue(h2 is int);

  // Quality check - the values should be SMIs for efficient arithmetic.
  Expect.equals((h1 & 0x3fffffff), h1);
  Expect.equals((h2 & 0x3fffffff), h2);

  // If we're checking the (randomized) identity hash code function,
  // we cannot guarantee anything about the actual hash code values.
  if (identityHashCode) return;

  // We expect that the hash function is reasonable quality - there
  // are some difference in the low bits.
  Expect.isFalse(h1 == h2);
  Expect.isFalse((h1 & 0xf) == (h2 & 0xf));
}

bools() {
  check(true, false, identityHashCode: false);

  Expect.equals(true.hashCode, hash(true)); // First can be optimized.
  Expect.equals(false.hashCode, hash(false));
}

ints() {
  var i1 = 100;
  var i2 = 101;
  check(i1, i2, identityHashCode: false);
  Expect.equals(i1.hashCode, hash(i1));
  Expect.equals(i2.hashCode, hash(i2));
}

lists() {
  var list1 = [];
  var list2 = [];
  check(list1, list2, identityHashCode: true);

  Expect.equals(list1.hashCode, hash(list1));
  Expect.equals(list2.hashCode, hash(list2));
}

strings() {
  var str1 = 'a';
  var str2 = 'b';
  var str3 = 'c';
  check(str1, str2, identityHashCode: false);
  check(str1, str3, identityHashCode: false);
  check(str2, str3, identityHashCode: false);

  Expect.equals(str1.hashCode, hash(str1));
  Expect.equals(str2.hashCode, hash(str2));
  Expect.equals(str3.hashCode, hash(str3));

  Expect.equals(0xA2E9442, 'a'.hashCode);
  Expect.equals(0x0DB819B, 'b'.hashCode);
  Expect.equals(0xEBA5D59, 'c'.hashCode);
}

main() {
  bools();
  ints();
  lists();
  strings();
}
