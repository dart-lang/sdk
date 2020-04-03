// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=5

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'dart:async';

// It does not matter where a future is generated.
bar(p) async => p;
baz(p) => new Future(() => p);

test0_1() async {
  throw 1;
}

test0() async {
  try {
    await test0_1();
  } catch (e) {
    Expect.equals(1, e);
  }
}

test1_1() async {
  throw 1;
}

test1_2() async {
  try {
    await test1_1();
  } catch (e) {
    throw e + 1;
  }
}

test1() async {
  try {
    await test1_2();
  } catch (e) {
    Expect.equals(2, e);
  }
}

test2() async {
  var x;
  var test2_1 = () async {
    try {
      throw 'a';
    } catch (e) {
      throw e + 'b';
    }
  };
  try {
    try {
      await test2_1();
    } catch (e) {
      var y = await bar(e + 'c');
      throw y;
    }
  } catch (e) {
    x = e + 'd';
    return '?';
  } finally {
    return x;
  }
  return '!';
}

test() async {
  var result;
  for (int i = 0; i < 10; i++) {
    await test0();
    await test1();
    result = await test2();
    Expect.equals('abcd', result);
  }
  await 1;
}

foo() {
  throw "Error";
}

awaitFoo() async {
  await foo();
}

main() {
  asyncStart();
  test()
      .then((_) => awaitFoo().then((_) => Expect.fail("Should have thrown"),
          onError: (error) => Expect.equals("Error", error)))
      .whenComplete(asyncEnd);
}
