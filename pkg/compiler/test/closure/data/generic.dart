// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class1<T> {
  /*member: Class1.field:hasThis*/
  var field = /*fields=[T],free=[T],hasThis*/ () => T;

  /*member: Class1.funcField:hasThis*/
  Function funcField;

  /*member: Class1.:hasThis*/
  Class1() {
    field = /*fields=[T],free=[T],hasThis*/ () => T;
  }

  /*member: Class1.setFunc:hasThis*/
  Class1.setFunc(this.funcField);

  /*member: Class1.fact:*/
  factory Class1.fact() => new Class1<T>();

  /*member: Class1.fact2:*/
  factory Class1.fact2() =>
      new Class1.setFunc(/*fields=[T],free=[T]*/ () => new Set<T>());

  /*member: Class1.method1:hasThis*/
  method1() => T;

  /*member: Class1.method2:hasThis*/
  method2() {
    return /*fields=[this],free=[this],hasThis*/ () => T;
  }

  /*member: Class1.method3:hasThis*/
  method3<S>() => S;

  /*member: Class1.method4:hasThis*/
  method4<S>() {
    return /*fields=[S],free=[S],hasThis*/ () => S;
  }

  /*member: Class1.method5:hasThis*/
  method5() {
    /*hasThis*/ local<S>() {
      return /*fields=[S],free=[S],hasThis*/ () => S;
    }

    return local<double>();
  }

  /*member: Class1.method6:hasThis*/
  method6<S>() {
    /*fields=[S],free=[S],hasThis*/ local<U>() {
      return /*fields=[S,U],free=[S,U],hasThis*/ () => '$S$U';
    }

    var local2 =
        /*prod.hasThis*/
        /*spec.fields=[S,this],free=[S,this],hasThis*/
        (o) {
      return
          /*prod.hasThis*/
          /*spec.fields=[S,this],free=[S,this],hasThis*/
          () => new Map<T, S>();
    };
    return local2(local<double>());
  }

  /*member: Class1.staticMethod1:*/
  static staticMethod1<S>() => S;

  /*member: Class1.staticMethod2:*/
  static staticMethod2<S>() {
    return /*fields=[S],free=[S]*/ () => S;
  }

  /*member: Class1.staticMethod3:*/
  static staticMethod3() {
    local<S>() {
      return /*fields=[S],free=[S]*/ () => S;
    }

    return local<double>();
  }

  /*member: Class1.staticMethod4:*/
  static staticMethod4<S>() {
    /*fields=[S],free=[S]*/ local<U>() {
      return /*fields=[S,U],free=[S,U]*/ () => '$S$U';
    }

    var local2 = /*fields=[S],free=[S]*/ (o) {
      return /*fields=[S],free=[S]*/ () => new Set<S>();
    };
    return local2(local<double>());
  }
}

/*member: topLevelMethod1:*/
topLevelMethod1<S>() => S;

/*member: topLevelMethod2:*/
topLevelMethod2<S>() {
  return /*fields=[S],free=[S]*/ () => S;
}

/*member: topLevelMethod3:*/
topLevelMethod3() {
  local<S>() {
    return /*fields=[S],free=[S]*/ () => S;
  }

  return local<double>();
}

/*member: topLevelMethod4:*/
topLevelMethod4<S>() {
  /*fields=[S],free=[S]*/ local<U>() {
    return /*fields=[S,U],free=[S,U]*/ () => '$S$U';
  }

  var local2 = /*fields=[S],free=[S]*/ (o) {
    return /*fields=[S],free=[S]*/ () => new Set<S>();
  };
  return local2(local<double>());
}

/*member: main:*/
main() {
  new Class1<int>().method1();
  new Class1<int>.fact().method2();
  new Class1<int>.fact2().funcField() is Set;
  new Class1<int>().method3<double>();
  new Class1<int>().method4<double>();
  new Class1<int>().method5();
  new Class1<int>().method6<double>();
  Class1.staticMethod1<double>();
  Class1.staticMethod2<double>();
  Class1.staticMethod3();
  Class1.staticMethod4<double>();
  topLevelMethod1<double>();
  topLevelMethod2<double>();
  topLevelMethod3();
  topLevelMethod4<double>();
}
