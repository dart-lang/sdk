// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Const<T> {
  final T value;

  const Const(this.value);
}

main() {
  test(42, false);

  test([42], true);
  test(<num>[42], true);
  test({42: 'foo'}, true);
  test(<num, Object>{42: 'foo'}, true);
  test(Const(42), true);
  test(Const<num>(42), true);

  test(const [42], true);
  test(const <num>[42], true);
  test(const {42: 'foo'}, true);
  test(const <num, Object>{42: 'foo'}, true);
  test(const Const(42), true);
  test(const Const<num>(42), true);
}

void test(dynamic value, bool expected) {
  bool matched;
  switch (value) {
    case [42]:
      matched = true;
      break;
    case <num>[42]:
      matched = true;
      break;
    case {42: 'foo'}:
      matched = true;
      break;
    case <num, Object>{42: 'foo'}:
      matched = true;
      break;
    case Const(42):
      matched = true;
      break;
    case Const<num>(42):
      matched = true;
      break;
    default:
      matched = false;
      break;
  }
  if (matched != expected) {
    print('FAIL: $value ${matched ? "matched" : "didn't match"}');
  }
}
