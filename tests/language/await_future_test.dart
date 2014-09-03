// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable_async --optimization-counter-threshold=5

import 'package:expect/expect.dart';

import 'dart:async';

// It does not matter where a future is generated.
bar(p) async => p;
baz(p) => new Future(() => p);

foo() async {
  var b = 0;
  for(int i = 0; i < 10; i++) {
    b += (await bar(1)) + (await baz(2));
  }
  return b;
}

quaz(p) async {
  var x = 0;
  try {
    for (var j = 0; j < 10; j++) {
      x += await baz(j);
    }
    return x;
  } finally {
    Expect.equals(x, 45);
    return p;
  }
}

quazz() async {
  var x = 0;
  try {
    try {
      x = await bar(1);
      throw x;
    } catch (e1) {
      var y = await baz(e1 + 1);
      throw y;
    }
  } catch (e2) {
    return e2;
  }
}

nesting() async {
  try {
    try {
      var x = 1;
      var y = () async {
        try {
          var z = (await bar(3)) + x;
          throw z;
        }  catch (e1) {
          return e1;
        }
      };
      var a = await y();
      throw a;
    } catch (e2) {
      throw e2 + 1;
    }
  } catch (e3) {
    return e3;
  }
}

main() async {
  var result;
  for (int i = 0; i < 10; i++) {
    result = await foo();
    Expect.equals(result, 30);
    result = await quaz(17);
    Expect.equals(result, 17);
    result = await quazz();
    Expect.equals(result, 2);
    result = await nesting();
    Expect.equals(result, 5);
  }
}
