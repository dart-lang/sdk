// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Const<T> {
  final T value;

  const Const(this.value);
}

main() {
  test(42, false);

  test([42], false);
  test(<num>[42], false);
  test({42: 'foo'}, false);
  test(<num, Object>{42: 'foo'}, false);
  test(Const(42), false);
  test(Const<num>(42), false);

  test(const [42], true);
  test(const <num>[42], true);
  test(const {42}, true);
  test(const <num>{42}, true);
  test(const {42: 'foo'}, true);
  test(const <num, Object>{42: 'foo'}, true);
  test(const Const(42), true);
  test(const Const<num>(42), true);
}

void test(dynamic value, bool expected) {
  bool matched;
  switch (value) {
    case const [42]:
      matched = true;
      break;
    case const <num>[42]:
      matched = true;
      break;
    case const {42}:
      matched = true;
      break;
    case const <num>{42}:
      matched = true;
      break;
    case const {42: 'foo'}:
      matched = true;
      break;
    case const <num, Object>{42: 'foo'}:
      matched = true;
      break;
    case const Const(42):
      matched = true;
      break;
    case const Const<num>(42):
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
