// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

foo1(a) async {
  int k = 0;
  switch (a) {
    case 1:
      await 3;
      k += 1;
      break;
    case 2:
      k += a;
      return k + 2;
    default: k = 2; //# withDefault: ok
  }
  return k;
}

foo2(a) async {
  int k = 0;
  switch (await a) {
    case 1:
      await 3;
      k += 1;
      break;
    case 2:
      k += await a;
      return k + 2;
    default: k = 2; //# withDefault: ok
  }
  return k;
}

foo3(a) async {
  int k = 0;
  switch (a) {
    case 1:
      k += 1;
      break;
    case 2:
      k += a;
      return k + 2;
    default: k = 2; //# withDefault: ok
  }
  return k;
}

foo4(value) async {
  int k = 0;
  switch (await value) {
    case 1:
      k += 1;
      break;
    case 2:
      k += 2;
      return 2 + k;
    default: k = 2; //# withDefault: ok
  }
  return k;
}

futureOf(a) async => await a;

test() async {
  Expect.equals(1, await foo1(1));
  Expect.equals(4, await foo1(2));
  Expect.equals(2, await foo1(3)); //# withDefault: ok
  Expect.equals(0, await foo1(3)); //# none: ok
  Expect.equals(1, await foo2(futureOf(1)));
  Expect.equals(4, await foo2(futureOf(2)));
  Expect.equals(2, await foo2(futureOf(3))); //# withDefault: ok
  Expect.equals(0, await foo2(futureOf(3))); //# none: ok
  Expect.equals(1, await foo3(1));
  Expect.equals(4, await foo3(2));
  Expect.equals(2, await foo3(3)); //# withDefault: ok
  Expect.equals(0, await foo3(3)); //# none: ok
  Expect.equals(1, await foo4(futureOf(1)));
  Expect.equals(4, await foo4(futureOf(2)));
  Expect.equals(2, await foo4(futureOf(3))); //# withDefault: ok
  Expect.equals(0, await foo4(futureOf(3))); //# none: ok
}

void main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
