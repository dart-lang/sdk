// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// In strong mode, `FutureOr` should be a valid type in most locations.

import 'dart:async';
import 'package:expect/expect.dart';

typedef void FunTakes<T>(T x);
typedef T FunReturns<T>();

main() {
  // Some useful values.
  dynamic n = null;
  dynamic i = 0;
  dynamic d = 1.5;
  dynamic fni = new Future<num>.value(i);
  dynamic fnd = new Future<num>.value(d);
  dynamic fi = new Future<int>.value(i);
  dynamic fd = new Future<double>.value(d);
  dynamic fn = new Future<Null>.value(null);

  dynamic o = new Object();
  dynamic fo = new Future<Object>.value(o);
  dynamic foi = new Future<Object>.value(i);

  if (typeAssertionsEnabled) {
    // Type annotation allows correct values.
    FutureOr<num> v;
    v = n;
    v = i;
    v = d;
    v = fni;
    v = fnd;
    v = fi;
    v = fd;
    v = fn;
    // Disallows invalid values.
    // These are all valid down-casts that fail at runtime.
    Expect.throws(() => v = o);
    Expect.throws(() => v = fo);
    Expect.throws(() => v = foi);

    void fun(FutureOr<num> v) {}
    fun(n);
    fun(i);
    fun(d);
    fun(fni);
    fun(fnd);
    fun(fi);
    fun(fd);
    fun(fn);
    // Disallows invalid values.
    // These are all valid down-casts that fail at runtime.
    Expect.throws(() => fun(o));
    Expect.throws(() => fun(fo));
    Expect.throws(() => fun(foi));

    FutureOr<num> fun2(Object o) => o; // implicit down-cast to return type.
    fun2(n);
    fun2(i);
    fun2(d);
    fun2(fni);
    fun2(fnd);
    fun2(fi);
    fun2(fd);
    fun2(fn);
    // Disallows invalid values.
    Expect.throws(() => fun2(o));
    Expect.throws(() => fun2(fo));
    Expect.throws(() => fun2(foi));

    List<Object> list = new List<FutureOr<num>>();
    list.add(n);
    list.add(i);
    list.add(d);
    list.add(fni);
    list.add(fnd);
    list.add(fi);
    list.add(fd);
    list.add(fn);
    Expect.throws(() => list.add(o));
    Expect.throws(() => list.add(fo));
    Expect.throws(() => list.add(foi));
  }

  {
    // Casts.
    FutureOr<num> v;
    v = n as FutureOr<num>;
    v = i as FutureOr<num>;
    v = d as FutureOr<num>;
    v = fni as FutureOr<num>;
    v = fnd as FutureOr<num>;
    v = fi as FutureOr<num>;
    v = fd as FutureOr<num>;
    v = fn as FutureOr<num>;
    // Disallows invalid values.
    // These are all valid down-casts that fail at runtime.
    Expect.throws(() => v = o as FutureOr<num>);
    Expect.throws(() => v = fo as FutureOr<num>);
    Expect.throws(() => v = foi as FutureOr<num>);
  }

  {
    // on-catch
    String check(Object o) {
      try {
        throw o;
      } on FutureOr<num> {
        return "caught";
      } on Object {
        return "uncaught";
      }
    }

    // Can't throw null, so no `n` case here.
    Expect.equals("caught", check(i));
    Expect.equals("caught", check(d));
    Expect.equals("caught", check(fni));
    Expect.equals("caught", check(fnd));
    Expect.equals("caught", check(fi));
    Expect.equals("caught", check(fd));
    Expect.equals("caught", check(fn));

    Expect.equals("uncaught", check(o));
    Expect.equals("uncaught", check(fo));
    Expect.equals("uncaught", check(foi));
  }

  {
    // Type variable bound.
    var valids = <C<FutureOr<num>>>[
      new C<Null>(),
      new C<int>(),
      new C<double>(),
      new C<num>(),
      new C<Future<Null>>(),
      new C<Future<int>>(),
      new C<Future<double>>(),
      new C<Future<num>>(),
      new C<FutureOr<Null>>(),
      new C<FutureOr<int>>(),
      new C<FutureOr<double>>(),
      new C<FutureOr<num>>(),
    ];
    Expect.equals(12, valids.length);
  }

  {
    // Dynamic checks.
    Expect.isFalse(new C<FutureOr<num>>().isCheck(n));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(i));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(d));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(fni));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(fnd));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(fi));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(fd));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(fn));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(o));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(fo));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(foi));

    Expect.isFalse(new C<FutureOr<int>>().isCheck(n));
    Expect.isTrue(new C<FutureOr<int>>().isCheck(i));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(d));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(fni));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(fnd));
    Expect.isTrue(new C<FutureOr<int>>().isCheck(fi));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(fd));
    Expect.isTrue(new C<FutureOr<int>>().isCheck(fn));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(o));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(fo));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(foi));

    Expect.isTrue(new C<FutureOr<Null>>().isCheck(n));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(i));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(d));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(fni));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(fnd));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(fi));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(fd));
    Expect.isTrue(new C<FutureOr<Null>>().isCheck(fn));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(o));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(fo));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(foi));

    Expect.isFalse(new C<Future<num>>().isCheck(n));
    Expect.isFalse(new C<Future<num>>().isCheck(i));
    Expect.isFalse(new C<Future<num>>().isCheck(d));
    Expect.isTrue(new C<Future<num>>().isCheck(fni));
    Expect.isTrue(new C<Future<num>>().isCheck(fnd));
    Expect.isTrue(new C<Future<num>>().isCheck(fi));
    Expect.isTrue(new C<Future<num>>().isCheck(fd));
    Expect.isTrue(new C<Future<num>>().isCheck(fn));
    Expect.isFalse(new C<Future<num>>().isCheck(o));
    Expect.isFalse(new C<Future<num>>().isCheck(fo));
    Expect.isFalse(new C<Future<num>>().isCheck(foi));

    Expect.isFalse(new C<Future<int>>().isCheck(n));
    Expect.isFalse(new C<Future<int>>().isCheck(i));
    Expect.isFalse(new C<Future<int>>().isCheck(d));
    Expect.isFalse(new C<Future<int>>().isCheck(fni));
    Expect.isFalse(new C<Future<int>>().isCheck(fnd));
    Expect.isTrue(new C<Future<int>>().isCheck(fi));
    Expect.isFalse(new C<Future<int>>().isCheck(fd));
    Expect.isTrue(new C<Future<int>>().isCheck(fn));
    Expect.isFalse(new C<Future<int>>().isCheck(o));
    Expect.isFalse(new C<Future<int>>().isCheck(fo));
    Expect.isFalse(new C<Future<int>>().isCheck(foi));

    Expect.isFalse(new C<num>().isCheck(n));
    Expect.isTrue(new C<num>().isCheck(i));
    Expect.isTrue(new C<num>().isCheck(d));
    Expect.isFalse(new C<num>().isCheck(fni));
    Expect.isFalse(new C<num>().isCheck(fnd));
    Expect.isFalse(new C<num>().isCheck(fi));
    Expect.isFalse(new C<num>().isCheck(fd));
    Expect.isFalse(new C<num>().isCheck(fn));
    Expect.isFalse(new C<num>().isCheck(o));
    Expect.isFalse(new C<num>().isCheck(fo));
    Expect.isFalse(new C<num>().isCheck(foi));

    Expect.isFalse(new C<int>().isCheck(n));
    Expect.isTrue(new C<int>().isCheck(i));
    Expect.isFalse(new C<int>().isCheck(d));
    Expect.isFalse(new C<int>().isCheck(fni));
    Expect.isFalse(new C<int>().isCheck(fnd));
    Expect.isFalse(new C<int>().isCheck(fi));
    Expect.isFalse(new C<int>().isCheck(fd));
    Expect.isFalse(new C<int>().isCheck(fn));
    Expect.isFalse(new C<int>().isCheck(o));
    Expect.isFalse(new C<int>().isCheck(fo));
    Expect.isFalse(new C<int>().isCheck(foi));

    Expect.isTrue(new C<Null>().isCheck(n));
    Expect.isFalse(new C<Null>().isCheck(i));
    Expect.isFalse(new C<Null>().isCheck(d));
    Expect.isFalse(new C<Null>().isCheck(fni));
    Expect.isFalse(new C<Null>().isCheck(fnd));
    Expect.isFalse(new C<Null>().isCheck(fi));
    Expect.isFalse(new C<Null>().isCheck(fd));
    Expect.isFalse(new C<Null>().isCheck(fn));
    Expect.isFalse(new C<Null>().isCheck(o));
    Expect.isFalse(new C<Null>().isCheck(fo));
    Expect.isFalse(new C<Null>().isCheck(foi));
  }
}

// FutureOr used as type parameter bound.
class C<T extends FutureOr<num>> {
  bool isCheck(Object o) => o is T;
}
