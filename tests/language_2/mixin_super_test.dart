// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--supermixin

import "package:expect/expect.dart";

class MS<T> {
  foo() {
    return "MS<$T>.foo\n";
  }
}

class M<T> extends MS<List<T>> {
  foo() {
    return super.foo() + "M<$T>.foo\n";
  }
}

class NS<T> {
  foo() {
    return "NS<$T>.foo\n";
  }
}

class N<T> extends NS<List<T>> {
  foo() {
    return super.foo() + "N<$T>.foo\n";
  }
}

class S<T> {
  foo() {
    return "S<$T>.foo\n";
  }
}

class SM<U, V> = S<List<U>> with M<Map<U, V>>;

class MNA1<U, V, W> extends S<List<U>> with M<Map<U, V>>, N<W> {
  foo() {
    return super.foo() + "MNA1<$U, $V, $W>.foo\n";
  }
}

class MNA2<U, V, W> extends SM<U, V> with N<W> {
  foo() {
    return super.foo() + "MNA2<$U, $V, $W>.foo\n";
  }
}

class MNA3<U, V, W> extends S<List<U>> with SM<U, V>, N<W> {
  foo() {
    return super.foo() + "MNA3<$U, $V, $W>.foo\n";
  }
}

main() {
  Expect.equals(
      "MS<List<double>>.foo\n"
      "M<double>.foo\n",
      new M<double>().foo());
  Expect.equals(
      "S<List<int>>.foo\n"
      "M<Map<int, String>>.foo\n",
      new SM<int, String>().foo());
  Expect.equals(
      "S<List<int>>.foo\n"
      "M<Map<int, String>>.foo\n"
      "N<bool>.foo\n"
      "MNA1<int, String, bool>.foo\n",
      new MNA1<int, String, bool>().foo());
  Expect.equals(
      "S<List<int>>.foo\n"
      "M<Map<int, String>>.foo\n"
      "N<bool>.foo\n"
      "MNA2<int, String, bool>.foo\n",
      new MNA2<int, String, bool>().foo());
  Expect.equals(
      "S<List<int>>.foo\n"
      "M<Map<int, String>>.foo\n"
      "N<bool>.foo\n"
      "MNA3<int, String, bool>.foo\n",
      new MNA3<int, String, bool>().foo());
}
