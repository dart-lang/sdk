// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test instantiation of object with malbounded types.

class A<T
          extends num /// 01: static type warning
                     > {}
class B<T> implements A<T> {}
class C<T
          extends num /// 01: continued
                     > implements B<T> {}

class Class<T> {
  newA() {
    new A<T>(); /// 01: continued
  }
  newB() {
    new B<T>(); /// 01: continued
  }
  newC() {
    new C<T>(); /// 01: continued
  }
}

bool inCheckedMode() {
  try {
    var i = 42;
    String s = i;
  } on TypeError catch (e) {
    return true;
  }
  return false;
}

void test(bool expectTypeError, f()) {
  try {
    var v = f();
    if (expectTypeError && inCheckedMode()) {
      throw 'Missing type error instantiating ${v.runtimeType}';
    }
  } on TypeError catch (e) {
    if (!expectTypeError || !inCheckedMode()) {
      throw 'Unexpected type error: $e';
    }
  }
}


void main() {
  test(false, () => new A<int>());
  test(false, () => new B<int>());
  test(false, () => new C<int>());

  test(true, () => new A<String>()); /// 01: continued
  test(true, () => new B<String>()); /// 01: continued
  test(true, () => new C<String>()); /// 01: continued

  var c = new Class<int>();
  test(false, () => c.newA());
  test(false, () => c.newB());
  test(false, () => c.newC());

  c = new Class<String>();
  test(true, () => c.newA()); /// 01: continued
  test(true, () => c.newB()); /// 01: continued
  test(true, () => c.newC()); /// 01: continued
}