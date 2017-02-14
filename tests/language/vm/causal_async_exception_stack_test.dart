// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

thrower() async {
  throw 'oops';
}

number() async {
  return 4;
}

generator() async* {
  yield await number();
  yield await thrower();
}

foo() async {
  await for (var i in generator()) {
    print(i);
  }
}

main() async {
  // Test async and async*.
  try {
    await foo();
  } catch (e, st) {
    expect(st.toString(), stringContainsInOrder([
        'thrower',
        '<asynchronous suspension>',
        'generator',
        '<asynchronous suspension>',
        'foo',
        '<asynchronous suspension>',
        'main',
        ]));
  }

  inner() async {
    deep() async {
      await thrower();
    }
    await deep();
  }

  // Test inner functions.
  try {
    await inner();
  } catch (e, st) {
    expect(st.toString(), stringContainsInOrder([
          'thrower',
          '<asynchronous suspension>',
          'main.inner.deep',
          '<asynchronous suspension>',
          'main.inner',
          '<asynchronous suspension>',
          'main',
          '<asynchronous suspension>',
          ]));
  }

  // Test for correct linkage.
  try {
    await thrower();
  } catch(e, st) {
    expect(st.toString(), stringContainsInOrder([
           'thrower',
           '<asynchronous suspension>',
           'main',
           ]));
  }
}