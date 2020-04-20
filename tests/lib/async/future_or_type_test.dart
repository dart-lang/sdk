// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// In strong mode, `FutureOr` should be a valid type in most locations.
// Requirements=nnbd-strong

import 'dart:async';
import 'package:expect/expect.dart';

// Some useful values.
dynamic nullValue = null;
dynamic intValue = 0;
dynamic doubleValue = 1.5;
dynamic numFutureInt = new Future<num>.value(intValue);
dynamic numFutureDouble = new Future<num>.value(doubleValue);
dynamic intFuture = new Future<int>.value(intValue);
dynamic doubleFuture = new Future<double>.value(doubleValue);
dynamic nullFuture = new Future<Null>.value(null);

dynamic objectValue = new Object();
dynamic objectFuture = new Future<Object>.value(objectValue);
dynamic objectFutureInt = new Future<Object>.value(intValue);

dynamic nullableNumFutureInt = new Future<num?>.value(intValue);
dynamic nullableNumFutureDouble = new Future<num?>.value(doubleValue);
dynamic nullableIntFuture = new Future<int?>.value(intValue);
dynamic nullableDoubleFuture = new Future<double?>.value(doubleValue);
dynamic nullableObjectFuture = new Future<Object?>.value(objectValue);

main() {
  if (typeAssertionsEnabled) {
    // Type annotation allows correct values.
    FutureOr<num> variable;
    variable = intValue;
    variable = doubleValue;
    variable = numFutureInt;
    variable = numFutureDouble;
    variable = intFuture;
    variable = doubleFuture;

    // Disallows invalid values.
    // These are all valid down-casts that fail at runtime.
    Expect.throws(() => variable = nullValue);
    Expect.throws(() => variable = objectValue);
    Expect.throws(() => variable = nullFuture);
    Expect.throws(() => variable = objectFuture);
    Expect.throws(() => variable = objectFutureInt);
    Expect.throws(() => variable = nullableNumFutureInt);
    Expect.throws(() => variable = nullableNumFutureDouble);
    Expect.throws(() => variable = nullableIntFuture);
    Expect.throws(() => variable = nullableDoubleFuture);
    Expect.throws(() => variable = nullableObjectFuture);

    // Type annotation allows correct values.
    FutureOr<num?> nullableVariable;
    nullableVariable = nullValue;
    nullableVariable = intValue;
    nullableVariable = doubleValue;
    nullableVariable = numFutureInt;
    nullableVariable = numFutureDouble;
    nullableVariable = intFuture;
    nullableVariable = doubleFuture;
    nullableVariable = nullFuture;
    nullableVariable = nullableNumFutureInt;
    nullableVariable = nullableNumFutureDouble;
    nullableVariable = nullableIntFuture;
    nullableVariable = nullableDoubleFuture;

    // Disallows invalid values.
    // These are all valid down-casts that fail at runtime.
    Expect.throws(() => nullableVariable = nullableObjectFuture);
    Expect.throws(() => nullableVariable = objectValue);
    Expect.throws(() => nullableVariable = objectFuture);
    Expect.throws(() => nullableVariable = objectFutureInt);

    void fun(FutureOr<num> parameter) {}
    fun(intValue);
    fun(doubleValue);
    fun(numFutureInt);
    fun(numFutureDouble);
    fun(intFuture);
    fun(doubleFuture);

    // Disallows invalid values.
    // These are all valid down-casts that fail at runtime.
    Expect.throws(() => fun(nullValue));
    Expect.throws(() => fun(objectValue));
    Expect.throws(() => fun(nullFuture));
    Expect.throws(() => fun(objectFuture));
    Expect.throws(() => fun(objectFutureInt));
    Expect.throws(() => fun(nullableNumFutureInt));
    Expect.throws(() => fun(nullableNumFutureDouble));
    Expect.throws(() => fun(nullableIntFuture));
    Expect.throws(() => fun(nullableDoubleFuture));
    Expect.throws(() => fun(nullableObjectFuture));

    // Type annotation allows correct values.
    void nullableFun(FutureOr<num?> parameter) {}
    nullableFun(nullValue);
    nullableFun(intValue);
    nullableFun(doubleValue);
    nullableFun(numFutureInt);
    nullableFun(numFutureDouble);
    nullableFun(intFuture);
    nullableFun(doubleFuture);
    nullableFun(nullFuture);
    nullableFun(nullableNumFutureInt);
    nullableFun(nullableNumFutureDouble);
    nullableFun(nullableIntFuture);
    nullableFun(nullableDoubleFuture);

    // Disallows invalid values.
    // These are all valid down-casts that fail at runtime.
    Expect.throws(() => nullableFun(nullableObjectFuture));
    Expect.throws(() => nullableFun(objectValue));
    Expect.throws(() => nullableFun(objectFuture));
    Expect.throws(() => nullableFun(objectFutureInt));

    // Implicit down-cast to return type.
    FutureOr<num> fun2(dynamic objectValue) => objectValue;
    fun2(intValue);
    fun2(doubleValue);
    fun2(numFutureInt);
    fun2(numFutureDouble);
    fun2(intFuture);
    fun2(doubleFuture);

    // Disallows invalid values.
    Expect.throws(() => fun2(nullValue));
    Expect.throws(() => fun2(objectValue));
    Expect.throws(() => fun2(nullFuture));
    Expect.throws(() => fun2(objectFuture));
    Expect.throws(() => fun2(objectFutureInt));
    Expect.throws(() => fun2(nullableNumFutureInt));
    Expect.throws(() => fun2(nullableNumFutureDouble));
    Expect.throws(() => fun2(nullableIntFuture));
    Expect.throws(() => fun2(nullableDoubleFuture));
    Expect.throws(() => fun2(nullableObjectFuture));

    // Implicit down-cast to return type.
    FutureOr<num?> nullableFun2(dynamic objectValue) => objectValue;
    nullableFun2(nullValue);
    nullableFun2(intValue);
    nullableFun2(doubleValue);
    nullableFun2(numFutureInt);
    nullableFun2(numFutureDouble);
    nullableFun2(intFuture);
    nullableFun2(doubleFuture);
    nullableFun2(nullFuture);
    nullableFun2(nullableNumFutureInt);
    nullableFun2(nullableNumFutureDouble);
    nullableFun2(nullableIntFuture);
    nullableFun2(nullableDoubleFuture);

    Expect.throws(() => nullableFun2(nullableObjectFuture));
    Expect.throws(() => nullableFun2(objectValue));
    Expect.throws(() => nullableFun2(objectFuture));
    Expect.throws(() => nullableFun2(objectFutureInt));
  }

  {
    List<Object> list = <FutureOr<num>>[];
    list.add(intValue);
    list.add(doubleValue);
    list.add(numFutureInt);
    list.add(numFutureDouble);
    list.add(intFuture);
    list.add(doubleFuture);

    Expect.throws(() => list.add(nullValue));
    Expect.throws(() => list.add(objectValue));
    Expect.throws(() => list.add(nullFuture));
    Expect.throws(() => list.add(objectFuture));
    Expect.throws(() => list.add(objectFutureInt));
    Expect.throws(() => list.add(nullableNumFutureInt));
    Expect.throws(() => list.add(nullableNumFutureDouble));
    Expect.throws(() => list.add(nullableIntFuture));
    Expect.throws(() => list.add(nullableDoubleFuture));
    Expect.throws(() => list.add(nullableObjectFuture));

    List<Object?> nullableList = <FutureOr<num?>>[];
    nullableList.add(nullValue);
    nullableList.add(intValue);
    nullableList.add(doubleValue);
    nullableList.add(numFutureInt);
    nullableList.add(numFutureDouble);
    nullableList.add(intFuture);
    nullableList.add(doubleFuture);
    nullableList.add(nullFuture);
    nullableList.add(nullableNumFutureInt);
    nullableList.add(nullableNumFutureDouble);
    nullableList.add(nullableIntFuture);
    nullableList.add(nullableDoubleFuture);

    Expect.throws(() => nullableList.add(nullableObjectFuture));
    Expect.throws(() => nullableList.add(objectValue));
    Expect.throws(() => nullableList.add(objectFuture));
    Expect.throws(() => nullableList.add(objectFutureInt));
  }

  {
    // Casts.
    intValue as FutureOr<num>;
    doubleValue as FutureOr<num>;
    numFutureInt as FutureOr<num>;
    numFutureDouble as FutureOr<num>;
    intFuture as FutureOr<num>;
    doubleFuture as FutureOr<num>;

    // Disallows invalid values.
    // These are all valid down-casts that fail at runtime.
    Expect.throws(() => nullValue as FutureOr<num>);
    Expect.throws(() => objectValue as FutureOr<num>);
    Expect.throws(() => nullFuture as FutureOr<num>);
    Expect.throws(() => objectFuture as FutureOr<num>);
    Expect.throws(() => objectFutureInt as FutureOr<num>);
    Expect.throws(() => nullableNumFutureInt as FutureOr<num>);
    Expect.throws(() => nullableNumFutureDouble as FutureOr<num>);
    Expect.throws(() => nullableIntFuture as FutureOr<num>);
    Expect.throws(() => nullableDoubleFuture as FutureOr<num>);
    Expect.throws(() => nullableObjectFuture as FutureOr<num>);

    // Casts.
    nullValue as FutureOr<num?>;
    intValue as FutureOr<num?>;
    doubleValue as FutureOr<num?>;
    numFutureInt as FutureOr<num?>;
    numFutureDouble as FutureOr<num?>;
    intFuture as FutureOr<num?>;
    doubleFuture as FutureOr<num?>;
    nullFuture as FutureOr<num?>;
    nullableNumFutureInt as FutureOr<num?>;
    nullableNumFutureDouble as FutureOr<num?>;
    nullableIntFuture as FutureOr<num?>;
    nullableDoubleFuture as FutureOr<num?>;

    // Disallows invalid values.
    // These are all valid down-casts that fail at runtime.
    Expect.throws(() => nullableObjectFuture as FutureOr<num?>);
    Expect.throws(() => objectValue as FutureOr<num?>);
    Expect.throws(() => objectFuture as FutureOr<num?>);
    Expect.throws(() => objectFutureInt as FutureOr<num?>);
  }

  {
    // On-catch.
    String check(Object objectValue) {
      try {
        throw objectValue;
      } on FutureOr<num> {
        return "caught";
      } on Object {
        return "uncaught";
      }
    }

    // Can't throw null, so no null or nullable FutureOr cases here.
    Expect.equals("caught", check(intValue));
    Expect.equals("caught", check(doubleValue));
    Expect.equals("caught", check(numFutureInt));
    Expect.equals("caught", check(numFutureDouble));
    Expect.equals("caught", check(intFuture));
    Expect.equals("caught", check(doubleFuture));

    Expect.equals("uncaught", check(objectValue));
    Expect.equals("uncaught", check(nullFuture));
    Expect.equals("uncaught", check(objectFuture));
    Expect.equals("uncaught", check(objectFutureInt));
  }

  {
    // Type variable bound.
    var valids = <C<FutureOr<num>>>[
      new C<int>(),
      new C<double>(),
      new C<num>(),
      new C<Future<int>>(),
      new C<Future<double>>(),
      new C<Future<num>>(),
      new C<FutureOr<int>>(),
      new C<FutureOr<double>>(),
      new C<FutureOr<num>>(),
    ];
    Expect.equals(9, valids.length);

    // Nullable variable bound.
    var nullableValids = <C<FutureOr<num?>>>[
      new C<Null>(),
      new C<int>(),
      new C<double>(),
      new C<num>(),
      new C<num?>(),
      new C<Future<Null>>(),
      new C<Future<int>>(),
      new C<Future<double>>(),
      new C<Future<num>>(),
      new C<Future<num?>>(),
      new C<FutureOr<Null>>(),
      new C<FutureOr<int>>(),
      new C<FutureOr<double>>(),
      new C<FutureOr<num>>(),
      new C<FutureOr<num?>>(),
    ];
    Expect.equals(15, nullableValids.length);
  }

  {
    // Dynamic checks.
    Expect.isFalse(new C<FutureOr<num>>().isCheck(nullValue));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(intValue));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(doubleValue));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(numFutureInt));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(numFutureDouble));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(intFuture));
    Expect.isTrue(new C<FutureOr<num>>().isCheck(doubleFuture));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(nullFuture));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(nullableNumFutureInt));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(nullableNumFutureDouble));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(nullableIntFuture));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(nullableDoubleFuture));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(nullableObjectFuture));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(objectValue));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(objectFuture));
    Expect.isFalse(new C<FutureOr<num>>().isCheck(objectFutureInt));

    Expect.isFalse(new C<FutureOr<int>>().isCheck(nullValue));
    Expect.isTrue(new C<FutureOr<int>>().isCheck(intValue));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(doubleValue));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(numFutureInt));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(numFutureDouble));
    Expect.isTrue(new C<FutureOr<int>>().isCheck(intFuture));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(doubleFuture));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(nullFuture));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(nullableNumFutureInt));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(nullableNumFutureDouble));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(nullableIntFuture));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(nullableDoubleFuture));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(nullableObjectFuture));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(objectValue));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(objectFuture));
    Expect.isFalse(new C<FutureOr<int>>().isCheck(objectFutureInt));

    Expect.isTrue(new C<FutureOr<Null>>().isCheck(nullValue));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(intValue));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(doubleValue));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(numFutureInt));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(numFutureDouble));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(intFuture));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(doubleFuture));
    Expect.isTrue(new C<FutureOr<Null>>().isCheck(nullFuture));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(nullableNumFutureInt));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(nullableNumFutureDouble));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(nullableIntFuture));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(nullableDoubleFuture));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(nullableObjectFuture));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(objectValue));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(objectFuture));
    Expect.isFalse(new C<FutureOr<Null>>().isCheck(objectFutureInt));

    Expect.isFalse(new C<Future<num>>().isCheck(nullValue));
    Expect.isFalse(new C<Future<num>>().isCheck(intValue));
    Expect.isFalse(new C<Future<num>>().isCheck(doubleValue));
    Expect.isTrue(new C<Future<num>>().isCheck(numFutureInt));
    Expect.isTrue(new C<Future<num>>().isCheck(numFutureDouble));
    Expect.isTrue(new C<Future<num>>().isCheck(intFuture));
    Expect.isTrue(new C<Future<num>>().isCheck(doubleFuture));
    Expect.isFalse(new C<Future<num>>().isCheck(nullFuture));
    Expect.isFalse(new C<Future<num>>().isCheck(nullableNumFutureInt));
    Expect.isFalse(new C<Future<num>>().isCheck(nullableNumFutureDouble));
    Expect.isFalse(new C<Future<num>>().isCheck(nullableIntFuture));
    Expect.isFalse(new C<Future<num>>().isCheck(nullableDoubleFuture));
    Expect.isFalse(new C<Future<num>>().isCheck(nullableObjectFuture));
    Expect.isFalse(new C<Future<num>>().isCheck(objectValue));
    Expect.isFalse(new C<Future<num>>().isCheck(objectFuture));
    Expect.isFalse(new C<Future<num>>().isCheck(objectFutureInt));

    Expect.isFalse(new C<Future<int>>().isCheck(nullValue));
    Expect.isFalse(new C<Future<int>>().isCheck(intValue));
    Expect.isFalse(new C<Future<int>>().isCheck(doubleValue));
    Expect.isFalse(new C<Future<int>>().isCheck(numFutureInt));
    Expect.isFalse(new C<Future<int>>().isCheck(numFutureDouble));
    Expect.isTrue(new C<Future<int>>().isCheck(intFuture));
    Expect.isFalse(new C<Future<int>>().isCheck(doubleFuture));
    Expect.isFalse(new C<Future<int>>().isCheck(nullFuture));
    Expect.isFalse(new C<Future<int>>().isCheck(nullableNumFutureInt));
    Expect.isFalse(new C<Future<int>>().isCheck(nullableNumFutureDouble));
    Expect.isFalse(new C<Future<int>>().isCheck(nullableIntFuture));
    Expect.isFalse(new C<Future<int>>().isCheck(nullableDoubleFuture));
    Expect.isFalse(new C<Future<int>>().isCheck(nullableObjectFuture));
    Expect.isFalse(new C<Future<int>>().isCheck(objectValue));
    Expect.isFalse(new C<Future<int>>().isCheck(objectFuture));
    Expect.isFalse(new C<Future<int>>().isCheck(objectFutureInt));

    Expect.isFalse(new C<num>().isCheck(nullValue));
    Expect.isTrue(new C<num>().isCheck(intValue));
    Expect.isTrue(new C<num>().isCheck(doubleValue));
    Expect.isFalse(new C<num>().isCheck(numFutureInt));
    Expect.isFalse(new C<num>().isCheck(numFutureDouble));
    Expect.isFalse(new C<num>().isCheck(intFuture));
    Expect.isFalse(new C<num>().isCheck(doubleFuture));
    Expect.isFalse(new C<num>().isCheck(nullFuture));
    Expect.isFalse(new C<num>().isCheck(nullableNumFutureInt));
    Expect.isFalse(new C<num>().isCheck(nullableNumFutureDouble));
    Expect.isFalse(new C<num>().isCheck(nullableIntFuture));
    Expect.isFalse(new C<num>().isCheck(nullableDoubleFuture));
    Expect.isFalse(new C<num>().isCheck(nullableObjectFuture));
    Expect.isFalse(new C<num>().isCheck(objectValue));
    Expect.isFalse(new C<num>().isCheck(objectFuture));
    Expect.isFalse(new C<num>().isCheck(objectFutureInt));

    Expect.isFalse(new C<int>().isCheck(nullValue));
    Expect.isTrue(new C<int>().isCheck(intValue));
    Expect.isFalse(new C<int>().isCheck(doubleValue));
    Expect.isFalse(new C<int>().isCheck(numFutureInt));
    Expect.isFalse(new C<int>().isCheck(numFutureDouble));
    Expect.isFalse(new C<int>().isCheck(intFuture));
    Expect.isFalse(new C<int>().isCheck(doubleFuture));
    Expect.isFalse(new C<int>().isCheck(nullFuture));
    Expect.isFalse(new C<int>().isCheck(nullableNumFutureInt));
    Expect.isFalse(new C<int>().isCheck(nullableNumFutureDouble));
    Expect.isFalse(new C<int>().isCheck(nullableIntFuture));
    Expect.isFalse(new C<int>().isCheck(nullableDoubleFuture));
    Expect.isFalse(new C<int>().isCheck(nullableObjectFuture));
    Expect.isFalse(new C<int>().isCheck(objectValue));
    Expect.isFalse(new C<int>().isCheck(objectFuture));
    Expect.isFalse(new C<int>().isCheck(objectFutureInt));

    Expect.isTrue(new C<Null>().isCheck(nullValue));
    Expect.isFalse(new C<Null>().isCheck(intValue));
    Expect.isFalse(new C<Null>().isCheck(doubleValue));
    Expect.isFalse(new C<Null>().isCheck(numFutureInt));
    Expect.isFalse(new C<Null>().isCheck(numFutureDouble));
    Expect.isFalse(new C<Null>().isCheck(intFuture));
    Expect.isFalse(new C<Null>().isCheck(doubleFuture));
    Expect.isFalse(new C<Null>().isCheck(nullFuture));
    Expect.isFalse(new C<Null>().isCheck(nullableNumFutureInt));
    Expect.isFalse(new C<Null>().isCheck(nullableNumFutureDouble));
    Expect.isFalse(new C<Null>().isCheck(nullableIntFuture));
    Expect.isFalse(new C<Null>().isCheck(nullableDoubleFuture));
    Expect.isFalse(new C<Null>().isCheck(nullableObjectFuture));
    Expect.isFalse(new C<Null>().isCheck(objectValue));
    Expect.isFalse(new C<Null>().isCheck(objectFuture));
    Expect.isFalse(new C<Null>().isCheck(objectFutureInt));

    Expect.isTrue(new C<FutureOr<num?>>().isCheck(nullValue));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(intValue));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(doubleValue));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(numFutureInt));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(numFutureDouble));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(intFuture));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(doubleFuture));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(nullFuture));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(nullableNumFutureInt));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(nullableNumFutureDouble));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(nullableIntFuture));
    Expect.isTrue(new C<FutureOr<num?>>().isCheck(nullableDoubleFuture));
    Expect.isFalse(new C<FutureOr<num?>>().isCheck(nullableObjectFuture));
    Expect.isFalse(new C<FutureOr<num?>>().isCheck(objectValue));
    Expect.isFalse(new C<FutureOr<num?>>().isCheck(objectFuture));
    Expect.isFalse(new C<FutureOr<num?>>().isCheck(objectFutureInt));
  }
}

// FutureOr used as type parameter bound.
class C<T extends FutureOr<num?>> {
  bool isCheck(dynamic objectValue) => objectValue is T;
}
