// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:exp,needsArgs*/
class A<T> {
  instanceMethod() => T;

  /*element: A.staticMethod:exp,needsArgs*/
  static staticMethod<S>() => S;

  /*element: A.staticMethodNested:exp,needsArgs*/
  static staticMethodNested<S>() {
    var inner = () => S;
    return inner();
  }

  /*element: A.genericMethod:exp,needsArgs,selectors=[Selector(call, genericMethod, arity=0, types=1)]*/
  genericMethod<S>() => S;

  /*element: A.genericMethodNested:exp,needsArgs,selectors=[Selector(call, genericMethodNested, arity=0, types=1)]*/
  genericMethodNested<S>() {
    var inner = () => S;
    return inner();
  }

  localFunction() {
    /*exp,needsArgs,selectors=[Selector(call, call, arity=0, types=1)]*/
    local<S>() => S;

    return local<bool>();
  }

  localFunctionNested() {
    /*exp,needsArgs,selectors=[Selector(call, call, arity=0, types=1)]*/
    local<S>() {
      var inner = () => S;
      return inner();
    }

    return local<bool>();
  }
}

/*element: topLevelMethod:exp,needsArgs*/
topLevelMethod<S>() => S;

/*element: topLevelMethodNested:exp,needsArgs*/
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
