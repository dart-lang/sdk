// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'never_opt_out_lib.dart';

Never optOutNever;
var inferredOptOutNever = optInNever;

genericMethod<T>() {}

class GenericClass<T> {}

main() {
  optInNever = optOutNever;

  Type typeNever = Never;
  genericMethod<Never>();
  new GenericClass<Never>();

  Never localNever = null;
  Null localNull = null;
  var inferredLocalNever = optInNever;

  localNever = localNever;
  optOutNever = localNever;
  optInNever = localNever;
  localNull = localNever;
  inferredOptOutNever = localNever;
  inferredLocalNever = localNever;

  localNever = optOutNever;
  optOutNever = optOutNever;
  optInNever = optOutNever;
  localNull = optOutNever;
  inferredOptOutNever = optOutNever;
  inferredLocalNever = optOutNever;

  localNever = optInNever;
  optOutNever = optInNever;
  optInNever = optInNever;
  localNull = optInNever;
  inferredOptOutNever = optInNever;
  inferredLocalNever = optInNever;

  localNever = localNull;
  optOutNever = localNull;
  optInNever = localNull;
  localNull = localNull;
  inferredOptOutNever = localNull;
  inferredLocalNever = localNull;

  localNever = inferredOptOutNever;
  optOutNever = inferredOptOutNever;
  optInNever = inferredOptOutNever;
  localNull = inferredOptOutNever;
  inferredOptOutNever = inferredOptOutNever;
  inferredLocalNever = inferredOptOutNever;

  localNever = inferredLocalNever;
  optOutNever = inferredLocalNever;
  optInNever = inferredLocalNever;
  localNull = inferredLocalNever;
  inferredOptOutNever = inferredLocalNever;
  inferredLocalNever = inferredLocalNever;

  throws(() => optOutNever = throwing());
  throws(() => localNever = throwing());
  throws(() => optOutNever = throwing());
  throws(() => optInNever = throwing());
  throws(() => inferredOptOutNever = throwing());
  throws(() => inferredLocalNever = throwing());

  var boundedGenericClass = new BoundedGenericClass();
  throws(() {
    var boundedGenericMethodResult1 = boundedGenericMethod1();
  });
  var boundedGenericMethodResult2 = boundedGenericMethod2();

  dynamic dyn = null;
  optInNever = dyn;
}

class B extends A {
  Null neverField;
  Null neverMethod(Null value) => value;
  Null get neverProperty => null;
  void set neverProperty(Null value) {}

  Null nullField;
  Null nullMethod(Null value) => value;
  Null get nullProperty => null;
  void set nullProperty(Null value) {}
}

class C extends A {
  Never neverField;
  Never neverMethod(Never value) => value;
  Never get neverProperty => null;
  void set neverProperty(Never value) {}

  Never nullField;
  Never nullMethod(Never value) => value;
  Never get nullProperty => null;
  void set nullProperty(Never value) {}
}

throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Expected exception';
}
