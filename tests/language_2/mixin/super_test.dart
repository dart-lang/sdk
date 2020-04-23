// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class MS<T> {
  foo() {
    return "MS<$T>.foo\n";
  }
}

mixin M<T> on MS<List<T>> {
  foo() {
    return super.foo() + "M<$T>.foo\n";
  }
}

class NS<T> {
  foo() {
    return "NS<$T>.foo\n";
  }
}

mixin N<T> on NS<List<T>> {
  foo() {
    return super.foo() + "N<$T>.foo\n";
  }
}

class S<T, V, W> implements MS<List<V>>, NS<List<W>> {
  foo() {
    return "S<$T,$V,$W>.foo\n";
  }
}

class SM<U, V, W> = S<U, V, W> with M<V>;

class MNA1<U, V, W> extends S<U, V, W> with M<V>, N<W> {
  foo() {
    return super.foo() + "MNA1<$U, $V, $W>.foo\n";
  }
}

class MNA2<U, V, W> extends SM<U, V, W> with N<W> {
  foo() {
    return super.foo() + "MNA2<$U, $V, $W>.foo\n";
  }
}

class MNA3<U, V, W> extends S<U, V, W> with M<V>, N<W> {
  foo() {
    return super.foo() + "MNA3<$U, $V, $W>.foo\n";
  }
}

abstract class Base {
  static String log = '';
  Base() {
    log += 'Base()\n';
  }
}

mixin Foo on Base {
  var x = Base.log += 'Foo.x\n';
}

mixin Bar on Base {
  var y = Base.log += 'Bar.y\n';
}

class Derived extends Base with Foo, Bar {
  String get log => Base.log;
}

main() {
  Expect.equals(
      "S<int,String,bool>.foo\n"
      "M<String>.foo\n",
      SM<int, String, bool>().foo());
  Expect.equals(
      "S<int,String,bool>.foo\n"
      "M<String>.foo\n"
      "N<bool>.foo\n"
      "MNA1<int, String, bool>.foo\n",
      MNA1<int, String, bool>().foo());
  Expect.equals(
      "S<int,String,bool>.foo\n"
      "M<String>.foo\n"
      "N<bool>.foo\n"
      "MNA2<int, String, bool>.foo\n",
      MNA2<int, String, bool>().foo());
  Expect.equals(
      "S<int,String,bool>.foo\n"
      "M<String>.foo\n"
      "N<bool>.foo\n"
      "MNA3<int, String, bool>.foo\n",
      MNA3<int, String, bool>().foo());
  Expect.equals(
      "Bar.y\n"
      "Foo.x\n"
      "Base()\n",
      Derived().log);
}
