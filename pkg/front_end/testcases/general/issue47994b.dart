// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Const {
  const Const();
}

class Class {
  const Class(Object? message) : assert(false, message);
}

main() {
  expect(null, test(() {
    assert(false);
  }));
  expect(null, test(() {
    assert(false, null);
  }));
  expect('foo', test(() {
    assert(false, 'foo');
  }));
  expect(0, test(() {
    assert(false, 0);
  }));
  expect(const {}, test(() {
    assert(false, const {});
  }));
  expect(#_symbol, test(() {
    assert(false, #_symbol);
  }));
  expect(const Const(), test(() {
    assert(false, const Const());
  }));

  expect(null, test(() {
    Class(null);
  }));
  expect('foo', test(() {
    Class('foo');
  }));
  expect(0, test(() {
    Class(0);
  }));
  expect(const {}, test(() {
    Class(const {});
  }));
  expect(#_symbol, test(() {
    Class(#_symbol);
  }));
  expect(const Const(), test(() {
    Class(const Const());
  }));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

Object? test(void Function() f) {
  try {
    f();
  } on AssertionError catch (e) {
    print(e);
    return e.message;
  } catch (e) {
    throw 'Unexpected exception $e (${e.runtimeType}';
  }
  throw 'Missing exception';
}
