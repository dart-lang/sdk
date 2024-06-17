// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const r3 = (1, 2, 3);
const r9 = (1, 2, 3, 4, 5, 6, 7, 8, 9);

@pragma('dart2js:never-inline')
/*member: r3a:function() {
  return 123;
}*/
r3a() {
  int a, b, c;
  (a, b, c) = r3;
  return a * 100 + b * 10 + c;
}

@pragma('dart2js:never-inline')
/*member: r3b:function() {
  return 123;
}*/
r3b() {
  int a, b, c;
  (Z: a, A: b, P: c) = (A: 2, P: 3, Z: 1);
  return a * 100 + b * 10 + c;
}

@pragma('dart2js:never-inline')
/*member: r9a:function() {
  return 123456789;
}*/
r9a() {
  int a, b, c, d, e, f, g, h, i;
  (a, b, c, d, e, f, g, h, i) = r9;
  return a * 100000000 +
      b * 10000000 +
      c * 1000000 +
      d * 100000 +
      e * 10000 +
      f * 1000 +
      g * 100 +
      h * 10 +
      i;
}

/*member: main:ignore*/
main() {
  r3a();
  r3b();
  r9a();
}
