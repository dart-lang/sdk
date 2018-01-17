// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:needsArgs,exp*/
class A<T> {
  instanceMethod() => T;

  /*ast.element: A.staticMethod:exp*/
  /*kernel.element: A.staticMethod:needsArgs,exp*/
  static staticMethod<S>() => S;

  /*ast.element: A.staticMethodNested:exp*/
  /*kernel.element: A.staticMethodNested:needsArgs,exp*/
  static staticMethodNested<S>() {
    var inner = () => S;
    return inner();
  }

  /*ast.element: A.genericMethod:exp*/
  /*kernel.element: A.genericMethod:needsArgs,exp*/
  genericMethod<S>() => S;

  /*ast.element: A.genericMethodNested:exp*/
  /*kernel.element: A.genericMethodNested:needsArgs,exp*/
  genericMethodNested<S>() {
    var inner = () => S;
    return inner();
  }

  localFunction() {
    /*ast.exp*/ /*kernel.needsArgs,exp*/ local<S>() => S;

    return local<bool>();
  }

  localFunctionNested() {
    /*ast.exp*/ /*kernel.needsArgs,exp*/ local<S>() {
      var inner = () => S;
      return inner();
    }

    return local<bool>();
  }
}

/*ast.element: topLevelMethod:exp*/
/*kernel.element: topLevelMethod:needsArgs,exp*/
topLevelMethod<S>() => S;

/*ast.element: topLevelMethodNested:exp*/
/*kernel.element: topLevelMethodNested:needsArgs,exp*/
topLevelMethodNested<S>() {
  var inner = () => S;
  return inner();
}

main() {
  var a = new A<int>();
  a.instanceMethod();
  a.genericMethod<String>();
  a.genericMethodNested<String>();
  a.localFunction();
  a.localFunctionNested();
  A.staticMethod<double>();
  A.staticMethodNested<double>();
  topLevelMethod<num>();
  topLevelMethodNested<num>();
}
