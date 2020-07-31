// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class M<T> {
  bool matches(o) {
    bool isChecked = checkUsingIs(o);
    if (checkedMode) {
      Expect.equals(isChecked, checkUsingCheckedMode(o));
    }
    return isChecked;
  }

  bool checkUsingIs(o) {
    return o is T;
  }

  bool checkUsingCheckedMode(o) {
    try {
      T x = o;
    } on Error {
      return false;
    }
    return true;
  }

  static final bool checkedMode = computeCheckedMode();
  static bool computeCheckedMode() {
    try {
      int x = "foo" as dynamic;
    } on Error {
      return true;
    }
    return false;
  }
}

class S {}

class C0<T> = S with M;
class C1<T> = S with M<T>;
class C2<T> = S with M<int>;
class C3 = S with M<String>;

main() {
  var c0 = new C0();
  Expect.isTrue(c0 is M);
  Expect.isFalse(c0 is M<int>);
  Expect.isFalse(c0 is M<String>);
  Expect.isTrue(c0.matches(c0));
  Expect.isTrue(c0.matches(42));
  Expect.isTrue(c0.matches("hello"));

  var c0_int = new C0<int>();
  Expect.isTrue(c0_int is M);
  Expect.isFalse(c0_int is M<int>);
  Expect.isFalse(c0_int is M<String>);
  Expect.isTrue(c0_int.matches(c0));
  Expect.isTrue(c0_int.matches(42));
  Expect.isTrue(c0_int.matches("hello"));

  var c0_String = new C0<String>();
  Expect.isTrue(c0_String is M);
  Expect.isFalse(c0_String is M<int>);
  Expect.isFalse(c0_String is M<String>);
  Expect.isTrue(c0_String.matches(c0));
  Expect.isTrue(c0_String.matches(42));
  Expect.isTrue(c0_String.matches("hello"));

  var c1 = new C1();
  Expect.isTrue(c1 is M);
  Expect.isFalse(c1 is M<int>);
  Expect.isFalse(c1 is M<String>);
  Expect.isTrue(c1.matches(c1));
  Expect.isTrue(c1.matches(42));
  Expect.isTrue(c1.matches("hello"));

  var c1_int = new C1<int>();
  Expect.isTrue(c1_int is M);
  Expect.isTrue(c1_int is M<int>);
  Expect.isFalse(c1_int is M<String>);
  Expect.isFalse(c1_int.matches(c1));
  Expect.isTrue(c1_int.matches(42));
  Expect.isFalse(c1_int.matches("hello"));

  var c1_String = new C1<String>();
  Expect.isTrue(c1_String is M);
  Expect.isFalse(c1_String is M<int>);
  Expect.isTrue(c1_String is M<String>);
  Expect.isFalse(c1_String.matches(c1));
  Expect.isFalse(c1_String.matches(42));
  Expect.isTrue(c1_String.matches("hello"));

  var c2 = new C2();
  Expect.isTrue(c2 is M);
  Expect.isTrue(c2 is M<int>);
  Expect.isFalse(c2 is M<String>);
  Expect.isFalse(c2.matches(c2));
  Expect.isTrue(c2.matches(42));
  Expect.isFalse(c2.matches("hello"));

  var c2_int = new C2<int>();
  Expect.isTrue(c2_int is M);
  Expect.isTrue(c2_int is M<int>);
  Expect.isFalse(c2_int is M<String>);
  Expect.isFalse(c2_int.matches(c2));
  Expect.isTrue(c2_int.matches(42));
  Expect.isFalse(c2_int.matches("hello"));

  var c2_String = new C2<String>();
  Expect.isTrue(c2_String is M);
  Expect.isTrue(c2_String is M<int>);
  Expect.isFalse(c2_String is M<String>);
  Expect.isFalse(c2_String.matches(c2));
  Expect.isTrue(c2_String.matches(42));
  Expect.isFalse(c2_String.matches("hello"));

  var c3 = new C3();
  Expect.isTrue(c3 is M);
  Expect.isFalse(c3 is M<int>);
  Expect.isTrue(c3 is M<String>);
  Expect.isFalse(c3.matches(c2));
  Expect.isFalse(c3.matches(42));
  Expect.isTrue(c3.matches("hello"));
}
