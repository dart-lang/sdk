// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

// Introduce an aliased type.

typedef T = Function;

// Use the aliased type.

T? v1;
List<T> v2 = [];
final T v3 = throw "Anything";
const List<T> v4 = [];
const v5 = <Type, Type>{T: T};

abstract class C {
  static T? v6;
  static List<T> v7 = [];
  static final T v8 = throw "Anything";
  static const List<T> v9 = [];

  T? v10;
  List<T> v11 = [];
  final T v12;

  C(): v12 = (() {});
  C.name1(this.v10, this.v12);
  factory C.name2(T arg1, T arg2) = C1.name1;

  T operator +(T other);
  T get g;
  set g(T value);
  Map<T, T> m1(covariant T arg1, [Set<Set<T>> arg2]);
  void m2({T arg1, T arg2(T arg21, T arg22)});
}

class C1 implements C {
  C1.name1(T arg1, T arg2);
  noSuchMethod(Invocation invocation) => throw 0;
}

// Awaiting updates in front end to handle crash caused by null from
// `ClassHierarchyBuilder.getKernelTypeAsInstanceOf`. So for now the
// following are multi-test cases, so that the rest can be tested.
class D1 extends T {} //# 01: ok
abstract class D2 extends C with T {} //# 02: ok
abstract class D3 implements T {} //# 03: ok
abstract class D4 = C with T; //# 04: ok

extension E on T {
  T foo(T t) => t;
}

X foo<X>(X x) => x;

T Function(T) id = (x) => x;

main() {
  var v13 = <T>[];
  var v14 = <Set<T>, Set<T>>{{}: {}};
  v14[{}] = {};
  var v15 = {v13};
  Set<List<T>> v16 = v15;
  v15 = v16;
  T v17 = foo<T>(() {});
  id(v17);
  T.apply(() {}, []);
}
