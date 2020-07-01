// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

////////////////////////////////////////////////////////////////////////////////
/// A sound assignment to a local variable doesn't capture the type variable.
////////////////////////////////////////////////////////////////////////////////

method1<T>(T o) {
  /*fields=[o],free=[o]*/
  dynamic local() {
    T t = o;
    return t;
  }

  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// A local function parameter type is captured in spec:nnbd-off mode.
////////////////////////////////////////////////////////////////////////////////

method2<T>() {
  /*spec.fields=[T],free=[T]*/
  dynamic local(T t) => t;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// A local function return type is captured in spec:nnbd-off mode.
////////////////////////////////////////////////////////////////////////////////

method3<T>(dynamic o) {
  /*spec.fields=[T,o],free=[T,o]*/
  /*prod.fields=[o],free=[o]*/
  T local() => o;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// A member parameter type is not captured.
////////////////////////////////////////////////////////////////////////////////

method4<T>(T o) {
  /*fields=[o],free=[o]*/
  dynamic local() => o;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// A member return type is not captured.
////////////////////////////////////////////////////////////////////////////////

T method5<T>(dynamic o) {
  /*fields=[o],free=[o]*/
  dynamic local() => o;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
/// A local function parameter type is not captured by an inner local function.
////////////////////////////////////////////////////////////////////////////////

method6<T>() {
  /*spec.fields=[T],free=[T]*/
  dynamic local(T t) {
    /*fields=[t],free=[t]*/
    dynamic inner() => t;
    return inner;
  }

  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// A local function return type is not captured by an inner local function.
////////////////////////////////////////////////////////////////////////////////

method7<T>(dynamic o) {
  /*spec.fields=[T,o],free=[T,o]*/
  /*prod.fields=[o],free=[o]*/
  T local() {
    /*fields=[o],free=[o]*/
    dynamic inner() => o;
    return inner();
  }

  return local;
}

main() {
  method1<int>(0).call();
  method2<int>().call(0);
  method3<int>(0).call();
  method4<int>(0).call();
  method5<int>(0);
  method6<int>().call(0).call();
  method7<int>(0).call().call();
}
