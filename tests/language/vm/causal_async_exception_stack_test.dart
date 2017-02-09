// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
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
  try {
    await foo();
  } catch (e, st) {
    expect(st.toString(), stringContainsInOrder([
        'thrower.<thrower_async_body>',
        '<asynchronous suspension>',
        'thrower',
        'generator.<generator_async_gen_body>',
        '<asynchronous suspension>',
        'generator',
        'foo.<foo_async_body>',
        '<asynchronous suspension>',
        ]));
  }
}