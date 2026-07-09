// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef R6 = (int, int, int, int, int, int);
typedef R6as3of2 = ((int, int), (int, int), (int, int));

R6 shuffle6a(R6 r) {
  var (a, b, c, d, e, f) = r;
  (b, d, f, a, c, e) = (a, b, c, d, e, f);
  (b, d, f, a, c, e) = (a, b, c, d, e, f);
  (b, d, f, a, c, e) = (a, b, c, d, e, f);
  return (a, b, c, d, e, f);
}

R6as3of2 shuffle6b(R6as3of2 r) {
  var ((a, b), (c, d), (e, f)) = r;
  ((b, d), (f, a), (c, e)) = ((a, b), (c, d), (e, f));
  ((b, d), (f, a), (c, e)) = ((a, b), (c, d), (e, f));
  ((b, d), (f, a), (c, e)) = ((a, b), (c, d), (e, f));
  return ((a, b), (c, d), (e, f));
}

main() {
  print((shuffle6a)((1, 2, 3, 4, 5, 6)));
  print((shuffle6b)(((1, 2), (3, 4), (5, 6))));
  print((sort4)(1, 2, 3, 4));
  print((sort4)(4, 3, 2, 1));
}

sort4(int a0, int a1, int a2, int a3) {
  if (a2 < a0) (a0, a2) = (a2, a0);
  if (a3 < a1) (a1, a3) = (a3, a1);

  if (a1 < a0) (a0, a1) = (a1, a0);
  if (a3 < a2) (a2, a3) = (a3, a2);

  if (a2 < a1) (a1, a2) = (a2, a1);

  return [a0, a1, a2, a3];
}
