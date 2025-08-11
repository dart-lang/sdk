// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:expect/variations.dart";

import "runtime_type_function_helper.dart";

Type typeLiteral<T>() => T;

main() {
  // Top-level tear-offs.
  checkType<dynamic Function()>(main);
  checkType<void Function<X0>(dynamic)>(checkType);

  // Class static member tear-offs.
  checkType<void Function()>(Xyzzy.foo);
  checkType<String Function(String, [String?, dynamic])>(Xyzzy.opt);
  checkType<String Function(String, {String? a, dynamic b})>(Xyzzy.nam);

  // Instance method tear-offs.
  checkType<void Function(Object?)>(new MyList().add); // Instance tear-off.
  checkType<void Function(Object?)>(new MyList<String>().add);
  checkType<void Function(Object?)>(new MyList<int>().add);
  checkType<void Function(int)>(new Xyzzy().intAdd);
  checkType<String Function(Object?)>(new G<String, int>().foo);

  // Instance method with function parameter.
  checkType<String Function(Object?)>(new G<String, int>().moo);
  checkType<String Function(int Function(String))>(
    new G<String, int>().higherOrder,
  );

  // Closures.
  String localFunc(String a, String b, [Map<String, String>? named]) => a + b;
  void localFunc2(int a) => print(a);

  Expect.isTrue(
    localFunc is String Function(String, String, [Map<String, String>]),
  );

  checkType<int Function()>(() => 1); // closure
  checkType<String Function(String, String, [Map<String, String>?])>(localFunc);
  checkType<void Function(int)>(localFunc2);

  // String of function runtime type objects.
  checkFunctionTypeString<int Function(bool, int, [String, Xyzzy])>(
    int,
    [bool],
    [String, Xyzzy],
    {},
  );
  checkFunctionTypeString<int Function(bool, int, {String a, Xyzzy b})>(
    int,
    [],
    [],
    {#a: String, #b: Xyzzy},
  );

  // String of class name.
  if (readableTypeStrings) {
    Expect.equals(
      'Xyzzy',
      Xyzzy().runtimeType.toString(),
      'runtime type of plain class prints as class name',
    );
  }
}

class Xyzzy {
  static void foo() {}
  static String opt(String x, [String? a, b]) => "";
  static String nam(String x, {String? a, b}) => "";
  void intAdd(int x) {}
}

class MyList<E> {
  void add(E value) {}
}

class G<U, V> {
  U foo(V x) => throw "uncalled";
  U moo(V f(U x)) => throw "uncalled";
  U higherOrder(int f(U x)) => throw "uncalled";
}
