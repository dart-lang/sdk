// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases

import 'dart:async';

// Introduce an aliased type.

typedef T<X> = FutureOr<X>;

// Use the aliased type.

T<int> v1;
List<T<void>> v2 = [];
final T<String> v3 = throw "Anything";
const List<T<C>> v4 = [];
const v5 = <Type, Type>{T: T};

abstract class C {
  static T<C> v1;
  static List<T<T>> v2 = [];
  static final T<Null> v3 = throw "Anything";
  static const List<T<List>> v4 = [];

  T<C> v5;
  List<T<T>> v6 = [];
  final T<Null> v7;

  C(): v7 = null;
  C.name1(this.v5, this.v7);
  factory C.name2(T<C> arg1, T<Null> arg2) = C1.name1;

  T<double> operator +(T<double> other);
  T<FutureOr<FutureOr<void>>> get g;
  set g(T<FutureOr<FutureOr<void>>> value);
  Map<T<C>, T<C>> m1(covariant T<C> arg1, [Set<Set<T<C>>> arg2]);
  void m2({T arg1, Map<T, T> arg2(T Function(T) arg21, T arg22)});
}

class C1 implements C {
  C1.name1(T<C> arg1, T<Null> arg2);
  noSuchMethod(Invocation invocation) => throw 0;
}

extension E on T<dynamic> {
  T<dynamic> foo(T<dynamic> t) => t;
}

T<Object> Function(T<Object>) id = (x) => x;

main() {
  var v8 = <T<C>>[];
  var v9 = <Set<T<T>>, Set<T<T>>>{{}: {}};
  var v10 = {v8};
  v9[{}] = {};
  Set<List<T<C>>> v11 = v10;
  v10 = v11;
}
