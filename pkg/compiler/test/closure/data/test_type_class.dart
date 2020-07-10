// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

////////////////////////////////////////////////////////////////////////////////
/// Explicit is-test is always required.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:hasThis*/
class Class1<T> {
  /*member: Class1.method1:hasThis*/
  method1(dynamic o) {
    /*fields=[o,this],free=[o,this],hasThis*/
    dynamic local() => o is T;
    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// Explicit as-cast is always required.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:hasThis*/
class Class2<T> {
  /*member: Class2.method2:hasThis*/
  method2(dynamic o) {
    /*fields=[o,this],free=[o,this],hasThis*/
    dynamic local() => o as T;
    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// Implicit as-cast is only required in spec:nnbd-off mode.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:hasThis*/
class Class3<T> {
  /*member: Class3.method3:hasThis*/
  method3(dynamic o) {
    /*spec.fields=[o,this],free=[o,this],hasThis*/
    /*prod.fields=[o],free=[o],hasThis*/
    T local() => o;
    return local;
  }
}

main() {
  new Class1<int>().method1(0).call();
  new Class2<int>().method2(0).call();
  new Class3<int>().method3(0).call();
}
