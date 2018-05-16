// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
/// Explicit is-test is always required.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:hasThis*/
class Class1<T> {
  /*element: Class1.method1:hasThis*/
  method1(dynamic o) {
    /*fields=[o,this],free=[o,this],hasThis*/
    dynamic local() => o is T;
    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// Explicit as-cast is always required.
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:hasThis*/
class Class2<T> {
  /*element: Class2.method2:hasThis*/
  method2(dynamic o) {
    /*fields=[o,this],free=[o,this],hasThis*/
    dynamic local() => o as T;
    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// Implicit as-cast is only required in strong mode.
////////////////////////////////////////////////////////////////////////////////

/*element: Class3.:hasThis*/
class Class3<T> {
  /*element: Class3.method3:hasThis*/
  method3(dynamic o) {
    /*kernel.fields=[o],free=[o],hasThis*/
    /*strong.fields=[o,this],free=[o,this],hasThis*/
    T local() => o;
    return local;
  }
}

main() {
  new Class1<int>().method1(0).call();
  new Class2<int>().method2(0).call();
  new Class3<int>().method3(0).call();
}
