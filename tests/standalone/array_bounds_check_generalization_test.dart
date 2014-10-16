// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--optimization_counter_threshold=10 --no-use-osr

import "package:expect/expect.dart";

test1(a, start, step, N) {
  var e;
  for (var i = 0; i < N; i++) {
    e = a[start + i * step];
  }
  return e;
}

test2(a, b) {
  var e;
  for (var i = 0, j = 0, k = 0; i < a.length; i++, j++, k++) {
    e = b[k] = a[j];
  }
  return e;
}

test3(a, b) {
  var e;
  for (var i = 0, j = 1, k = 0; i < a.length - 1; i++, j++, k++) {
    e = b[k] = a[j - 1];
  }
  return e;
}

test4(a, b) {
  var e;
  if (a.length < 2) {
    return null;
  }

  for (var i = 0, j = 1, k = 0; i < a.length - 1; i++, j++, k++) {
    e = b[k] = a[j - 1];
  }
  return e;
}

test5(a, b, k0) {
  var e;
  if (a.length < 2) {
    return null;
  }

  if (k0 > 1) {
    return null;
  }

  for (var i = 0, j = 1, k = 0; i < a.length - 1; i++, j++, k++) {
    e = b[k - k0] = a[j - 1];
  }
  return e;
}

test6(a, M, N) {
  var e = 0;
  for (var i = 0; i < N; i++) {
    for (var j = 0; j < M; j++) {
      e += a[i * M + j];
    }
  }
  return e;
}

main() {
  var a = const [0, 1, 2, 3, 4, 5, 6, 7];
  var b = new List(a.length);
  for (var i = 0; i < 10000; i++) {
    Expect.equals(a.last, test1(a, 0, 1, a.length));
    Expect.equals(a.last, test2(a, b));
    Expect.equals(a[a.length - 2], test3(a, b));
    Expect.equals(a[a.length - 2], test4(a, b));
    Expect.equals(a[a.length - 2], test5(a, b, 0));
    Expect.equals(6 , test6(a, 2, 2));
  }

  test1(a, 0, 2, a.length ~/ 2);
  Expect.throws(() => test1(a, 1, 1, a.length));
  Expect.throws(() => test2(a, new List(a.length - 1)));
  Expect.throws(() => test6(a, 4, 3));
}
