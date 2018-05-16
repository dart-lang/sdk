// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
/// A sound initialization of a local variable doesn't capture the type
/// variable.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:hasThis*/
class Class1<T> {
  /*element: Class1.method1:hasThis*/
  method1(T o) {
    /*fields=[o],free=[o],hasThis*/
    dynamic local() {
      T t = o;
      return t;
    }

    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// A sound assignment to a local variable doesn't capture the type variable.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1b.:hasThis*/
class Class1b<T> {
  /*element: Class1b.method1b:hasThis*/
  method1b(T o) {
    /*fields=[o],free=[o],hasThis*/
    dynamic local() {
      T t = null;
      t = o;
      return t;
    }

    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// A local function parameter type is only captured in strong mode.
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:hasThis*/
class Class2<T> {
  /*element: Class2.method2:hasThis*/
  method2() {
    /*kernel.hasThis*/
    /*strong.fields=[this],free=[this],hasThis*/
    dynamic local(T t) => t;
    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// A local function return type is only captured in strong mode.
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

////////////////////////////////////////////////////////////////////////////////
/// A member parameter type is not captured.
////////////////////////////////////////////////////////////////////////////////

/*element: Class4.:hasThis*/
class Class4<T> {
  /*element: Class4.method4:hasThis*/
  method4(T o) {
    /*fields=[o],free=[o],hasThis*/
    dynamic local() => o;
    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// A member return type is not captured.
////////////////////////////////////////////////////////////////////////////////

/*element: Class5.:hasThis*/
class Class5<T> {
  /*element: Class5.method5:hasThis*/
  T method5(dynamic o) {
    /*fields=[o],free=[o],hasThis*/
    dynamic local() => o;
    return local();
  }
}

////////////////////////////////////////////////////////////////////////////////
/// A local function parameter type is not captured by an inner local function.
////////////////////////////////////////////////////////////////////////////////

/*element: Class6.:hasThis*/
class Class6<T> {
  /*element: Class6.method6:hasThis*/
  method6() {
    /*kernel.hasThis*/
    /*strong.fields=[this],free=[this],hasThis*/
    dynamic local(T t) {
      /*fields=[t],free=[t],hasThis*/
      dynamic inner() => t;
      return inner;
    }

    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// A local function return type is not captured by an inner local function.
////////////////////////////////////////////////////////////////////////////////

/*element: Class7.:hasThis*/
class Class7<T> {
  /*element: Class7.method7:hasThis*/
  method7(dynamic o) {
    /*kernel.fields=[o],free=[o],hasThis*/
    /*strong.fields=[o,this],free=[o,this],hasThis*/
    T local() {
      /*fields=[o],free=[o],hasThis*/
      dynamic inner() => o;
      return inner();
    }

    return local;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// A field type is not captured.
////////////////////////////////////////////////////////////////////////////////

/*element: Class8.:hasThis*/
class Class8<T> {
  /*element: Class8.field8:hasThis*/
  T field8 = /*hasThis*/ () {
    return null;
  }();
}

main() {
  new Class1<int>().method1(0).call();
  new Class1b<int>().method1b(0).call();
  new Class2<int>().method2().call(0);
  new Class3<int>().method3(0).call();
  new Class4<int>().method4(0).call();
  new Class5<int>().method5(0);
  new Class6<int>().method6().call(0).call();
  new Class7<int>().method7(0).call().call();
  new Class8<int>().field8;
}
