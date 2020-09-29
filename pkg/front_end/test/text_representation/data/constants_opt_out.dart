// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/
library test;

T id<T>(T /*T**/ t) => t;

class Class1<T> {
  const Class1();
}

class Class2<T> {
  final T field1;

  const Class2(
      this. /*normal|limited.Class2.T**/ /*verbose.test::Class2.T**/ field1);
}

class Class3<T, S> extends Class2<T> {
  final S field2;

  const Class3(
      T /*normal|limited.Class3.T**/ /*verbose.test::Class3.T**/ field1,
      this. /*normal|limited.Class3.S**/ /*verbose.test::Class3.S**/ field2)
      : super(field1);
}

class Class4<T, S> extends Class3<T, S> {
  final S field2;

  const Class4(
      T /*normal|limited.Class4.T**/ /*verbose.test::Class4.T**/ field1,
      S /*normal|limited.Class4.S**/ /*verbose.test::Class4.S**/ shadowedField2,
      this. /*normal|limited.Class4.S**/ /*verbose.test::Class4.S**/ field2)
      : super(field1, shadowedField2);
}

const nullConstant = /*null*/ null;
const trueConstant = /*true*/ true;
const falseConstant = /*false*/ false;
const intConstant = /*42*/ 42;
const doubleConstant = /*3.14*/ 3.14;
const stringConstant = /*"foo"*/ "foo";
const symbolConstant = /*#name*/ #name;
const privateSymbolConstant =
/*normal|limited.#_privateName*/
    /*verbose.#test::_privateName*/
    #_privateName;
const listConstant1 = /*const <dynamic>[]*/ [];
const listConstant2 = <
    int> /*normal|limited.const <int*>[]*/ /*verbose.const <dart.core::int*>[]*/ [];
const listConstant3 = <
    int> /*normal|limited.const <int*>[0]*/ /*verbose.const <dart.core::int*>[0]*/ [
  0
];
const listConstant4 = <
    int> /*normal|limited.const <int*>[0, 1]*/ /*verbose.const <dart.core::int*>[0, 1]*/ [
  0,
  1
];
const setConstant1 = <
    int> /*normal|limited.const <int*>{}*/ /*verbose.const <dart.core::int*>{}*/ {};
const setConstant2 = <
    int> /*normal|limited.const <int*>{0}*/ /*verbose.const <dart.core::int*>{0}*/ {
  0
};
const setConstant3 = <
    int> /*normal|limited.const <int*>{0, 1}*/ /*verbose.const <dart.core::int*>{0, 1}*/ {
  0,
  1
};
const mapConstant1 = /*const <dynamic, dynamic>{}*/ {};
const mapConstant2 = <int, String>
    /*normal|limited.const <int*, String*>{}*/
    /*verbose.const <dart.core::int*, dart.core::String*>{}*/
    {};
const mapConstant3 = <int, String>
    /*normal|limited.const <int*, String*>{0: "foo"}*/
    /*verbose.const <dart.core::int*, dart.core::String*>{0: "foo"}*/
    {0: "foo"};
const mapConstant4 = <int, String>
    /*normal|limited.const <int*, String*>{0: "foo", 1: "bar"}*/
    /*verbose.const <dart.core::int*, dart.core::String*>{0: "foo", 1: "bar"}*/
    {0: "foo", 1: "bar"};
const tearOffConstant = /*normal|limited.id*/ /*verbose.test::id*/ id;
const int Function(int) partialInitializationConstant =
    /*normal|limited.id<int*>*/
    /*verbose.test::id<dart.core::int*>*/
    id;
const boolHasEnvironmentConstant = const
    /*normal|limited.unevaluated{bool.hasEnvironment("foo")}*/
    /*verbose.unevaluated{{org-dartlang-test:///a/b/c/main.dart}dart.core::bool.hasEnvironment("foo")}*/
    bool.hasEnvironment("foo");
const boolFromEnvironmentConstant = const
    /*normal|limited.unevaluated{bool.fromEnvironment("foo", defaultValue: true)}*/
    /*verbose.unevaluated{{org-dartlang-test:///a/b/c/main.dart}dart.core::bool.fromEnvironment("foo", defaultValue: true)}*/
    bool.fromEnvironment("foo", defaultValue: true);
const intFromEnvironmentConstant = const
    /*normal|limited.unevaluated{int.fromEnvironment("foo", defaultValue: 87)}*/
    /*verbose.unevaluated{{org-dartlang-test:///a/b/c/main.dart}dart.core::int.fromEnvironment("foo", defaultValue: 87)}*/
    int.fromEnvironment("foo", defaultValue: 87);
const stringFromEnvironmentConstant = const
    /*normal|limited.unevaluated{String.fromEnvironment("foo", defaultValue: "bar")}*/
    /*verbose.unevaluated{{org-dartlang-test:///a/b/c/main.dart}dart.core::String.fromEnvironment("foo", defaultValue: "bar")}*/
    String.fromEnvironment("foo", defaultValue: "bar");
const instanceConstant1 = const
    /*normal|limited.const Class1<dynamic>{}*/
    /*verbose.const test::Class1<dynamic>{}*/
    Class1();
const instanceConstant2 = const
    /*normal|limited.const Class1<int*>{}*/
    /*verbose.const test::Class1<dart.core::int*>{}*/
    Class1<int>();
const instanceConstant3 = const
    /*normal|limited.const Class1<int*>{}*/
    /*verbose.const test::Class1<dart.core::int*>{}*/
    Class1<int>();
const instanceConstant4 = const
    /*normal|limited.const Class2<int*>{Class2.field1: 0}*/
    /*verbose.const test::Class2<dart.core::int*>{test::Class2.field1: 0}*/
    Class2(0);
const instanceConstant5 = const
    /*normal|limited.const Class2<num*>{Class2.field1: 42}*/
    /*verbose.const test::Class2<dart.core::num*>{test::Class2.field1: 42}*/
    Class2<num>(42);
const instanceConstant6 = const
    /*normal|limited.const Class3<int*, String*>{Class3.field2: "foo", Class2.field1: 42}*/
    /*verbose.const test::Class3<dart.core::int*, dart.core::String*>{test::Class3.field2: "foo", test::Class2.field1: 42}*/
    Class3<int, String>(42, "foo");
const instanceConstant7 = const
    /*normal|limited.const Class4<int*, String*>{Class4.field2: "baz", Class3.field2: "foo", Class2.field1: 42}*/
    /*verbose.const test::Class4<dart.core::int*, dart.core::String*>{test::Class4.field2: "baz", test::Class3.field2: "foo", test::Class2.field1: 42}*/
    Class4<int, String>(42, "foo", "baz");
