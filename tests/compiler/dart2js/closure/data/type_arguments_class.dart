// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

////////////////////////////////////////////////////////////////////////////////
/// A constructor invocation to a class that needs type arguments captures the
/// type variables.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1a.:hasThis*/
class Class1a<T> {}

/*member: Class1b.:hasThis*/
class Class1b<T> {
  /*member: Class1b.method1:hasThis*/
  method1() {
    /*fields=[this],free=[this],hasThis*/
    dynamic local() => new Class1a<T>();
    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// A constructor invocation to a class that _doesn't_ needs type arguments does
/// _not_ capture the type variables.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2a.:hasThis*/
class Class2a<T> {}

/*member: Class2b.:hasThis*/
class Class2b<T> {
  /*member: Class2b.method2:hasThis*/
  method2() {
    /*hasThis*/
    dynamic local() => new Class2a<T>();
    return local;
  }
}

main() {
  new Class1b<int>().method1().call() is Class1a<int>;
  new Class2b<int>().method2().call();
}
