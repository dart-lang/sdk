// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

typedef F1 = void Function<T>(T);
typedef void F2<T>(T v);

dynamic defaultFLatest;

void defaultF<T>(T v) {
  defaultFLatest = v;
}

class X1 {
  final F1 f;
  const X1({this.f: defaultF});
}

class X2 {
  final F2 f;
  const X2({this.f: defaultF});
}

class Y1 {
  F1 f = defaultF;
}

class Y2 {
  F2 f = defaultF;
}

dynamic foo() {
  if (defaultFLatest == -1) return -1;
  return "not -1";
}

void main() {
  {
    var x = const X1();

    // OK with implicit dynamic type argument.
    x.f("hello1");
    Expect.equals("hello1", defaultFLatest);

    // OK with explicit dynamic type argument.
    x.f<dynamic>("hello2");
    Expect.equals("hello2", defaultFLatest);

    // OK with correctly given argument type.
    x.f<String>("hello3");
    Expect.equals("hello3", defaultFLatest);

    // OK with correctly given argument type.
    x.f<int>(42);
    Expect.equals(42, defaultFLatest);

    // Not OK with incorrectly given argument type.
    x.f<int>("hello"); //# 01: compile-time error

    // Not OK with incorrectly given argument type.
    x.f<int>(foo()); //# 02: runtime error

    var y = new Y1();
    y.f = defaultF;

    // OK with implicit dynamic type argument.
    y.f("hello4");
    Expect.equals("hello4", defaultFLatest);

    // OK with explicit dynamic type argument.
    y.f<dynamic>("hello5");
    Expect.equals("hello5", defaultFLatest);

    // OK with correctly given argument type.
    y.f<String>("hello6");
    Expect.equals("hello6", defaultFLatest);

    // OK with correctly given argument type.
    y.f<int>(43);
    Expect.equals(43, defaultFLatest);

    // Not OK with incorrectly given argument type.
    y.f<int>("hello"); //# 03: compile-time error

    // Not OK with incorrectly given argument type.
    y.f<int>(foo()); //# 04: runtime error
  }
  {
    var x = const X2();

    // OK with no type arguments.
    x.f("hello1");
    Expect.equals("hello1", defaultFLatest);

    // Not OK with a type argument.
    x.f<dynamic>("hello2"); //# 05: compile-time error

    // Not OK with a type argument.
    x.f<String>("hello3"); //# 06: compile-time error

    var y = new Y2();
    y.f = defaultF;

    // OK with no type argument.
    y.f("hello4");
    Expect.equals("hello4", defaultFLatest);

    // Not OK with a type argument.
    y.f<dynamic>("hello5"); //# 07: compile-time error

    // Not OK with a type argument.
    y.f<String>("hello6"); //# 08: compile-time error

    // Correct runtime type of x.f.
    void instantiatedFType(dynamic _) {}
    Expect.equals(x.f.runtimeType.toString(),
        instantiatedFType.runtimeType.toString()); // #09: ok
  }
}
