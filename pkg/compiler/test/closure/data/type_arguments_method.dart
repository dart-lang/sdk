// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

////////////////////////////////////////////////////////////////////////////////
/// A constructor invocation for a class that needs type arguments captures the
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
/// A constructor invocation for a class that _doesn't_ needs type arguments
/// does _not_ capture the type variables.
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

////////////////////////////////////////////////////////////////////////////////
/// A static invocation of a method that needs type arguments captures the type
/// variables.
////////////////////////////////////////////////////////////////////////////////

method3a<T>(o) => o is T;

method3b<T>(o) {
  /*fields=[T,o],free=[T,o]*/
  dynamic local() => method3a<T>(o);
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// A static invocation of a method that _doesn't_ needs type arguments does
/// _not_ capture the type variables.
////////////////////////////////////////////////////////////////////////////////

method4a<T>(o) => o;

method4b<T>(o) {
  /*fields=[o],free=[o]*/
  dynamic local() => method4a<T>(o);
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// An instance member invocation of a method that needs type arguments captures
/// the type variables.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5a.:hasThis*/
class Class5a {
  /*member: Class5a.method5a:hasThis*/
  method5a<T>(o) => o is T;
}

method5b<T>(o) {
  /*fields=[T,o],free=[T,o]*/
  dynamic local() => new Class5a().method5a<T>(o);
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// An instance member invocation of a method that _doesn't_ needs type
/// arguments does _not_ capture the type variables.
////////////////////////////////////////////////////////////////////////////////

/*member: Class6a.:hasThis*/
class Class6a {
  /*member: Class6a.method6a:hasThis*/
  method6a<T>(o) => o;
}

method6b<T>(o) {
  /*fields=[o],free=[o]*/
  dynamic local() => new Class6a().method6a<T>(o);
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// An invocation of a local function that needs type arguments captures the
/// type variables.
////////////////////////////////////////////////////////////////////////////////

method7b<T>(o) {
  /**/
  method7a<S>(p) => p is S;

  /*fields=[T,method7a,o],free=[T,method7a,o]*/
  dynamic local() => method7a<T>(o);
  return local;
}

////////////////////////////////////////////////////////////////////////////////
/// An invocation if a local function that _doesn't_ needs type arguments does
/// _not_ capture the type variables.
////////////////////////////////////////////////////////////////////////////////

method8b<T>(o) {
  /**/
  method8a<S>(p) => p;

  /*fields=[T,method8a,o],free=[T,method8a,o]*/
  dynamic local() => method8a<T>(o);
  return local;
}

main() {
  new Class1b<int>().method1().call() is Class1a<int>;
  new Class2b<int>().method2().call();
  method3b<int>(0).call();
  method4b<int>(0).call();
  method5b<int>(0).call();
  method6b<int>(0).call();
  method7b<int>(0).call();
  method8b<int>(0).call();
}
