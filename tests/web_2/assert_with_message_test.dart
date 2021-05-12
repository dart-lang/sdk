// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
confuse(x) => x;

testFalse(name, fault) {
  try {
    fault();
  } catch (e) {
    Expect.isTrue(e is AssertionError, '$name: is AssertionError');
    Expect.isTrue('$e'.contains('Mumble'), '$name: <<$e>> contains "Mumble"');
    return;
  }
  Expect.fail('Expected assert to throw');
}

test1() {
  testFalse('constant false', () {
    assert(false, 'Mumble');
  });
}

test2() {
  testFalse('variable false', () {
    assert(confuse(false), 'Mumble');
  });
}

testTypeErrors() {
  check(name, fault) {
    try {
      fault();
    } catch (e) {
      Expect.isTrue(
          e is TypeError, 'name: <<$e>> (${e.runtimeType}) is TypeError');
      return;
    }
    Expect.fail('Expected assert to throw');
  }

  check('constant type error', () {
    assert(null, 'Mumble');
  });
  check('variable type error', () {
    assert(confuse(null), 'Mumble');
  });
  check('function type error', () {
    assert(confuse(() => null), 'Mumble');
  });
}

testMessageEffect1() {
  var v = 1;
  // Message is not evaluated on succeeding assert.
  assert(confuse(true), '${v = 123}');
  Expect.equals(1, v);
}

testMessageEffect2() {
  var v = 1;
  try {
    // Message is evaluated to produce AssertionError argument on failing
    // assert.
    assert(confuse(false), '${v = 123}');
  } catch (e) {
    Expect.equals(123, v);
    Expect.isTrue('$e'.contains('123'), '<<$e>> contains "123"');
    return;
  }
  Expect.fail('Expected assert to throw');
}

testMessageEffect3() {
  var v = 1;
  try {
    // Message is evaluated to produce AssertionError argument on failing
    // assert.
    assert(confuse(() => ++v > 100), '${++v}');
  } catch (e) {
    Expect.equals(3, v);
    Expect.isTrue('$e'.contains('3'), '<<$e>> contains "3"');
    return;
  }
  Expect.fail('Expected assert to throw');
}

bool get assertionsEnabled {
  bool b = false;
  assert((b = true));
  return b;
}

main() {
  if (!assertionsEnabled) return;

  test1();
  test2();
  testTypeErrors();
  testMessageEffect1();
  testMessageEffect2();
  testMessageEffect3();
}
