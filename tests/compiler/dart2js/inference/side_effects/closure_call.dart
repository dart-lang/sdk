// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: method:SideEffects(reads nothing; writes nothing)*/
method() {}

/*element: callExpression:SideEffects(reads anything; writes anything)*/
callExpression() => (method)();

/*element: Super.:SideEffects(reads nothing; writes nothing)*/
class Super {
  var field;

  /*element: Super.getter:SideEffects(reads nothing; writes nothing)*/
  get getter => null;
}

/*element: Class.:SideEffects(reads nothing; writes nothing)*/
class Class extends Super {
  /*element: Class.callSuperField:SideEffects(reads anything; writes anything)*/
  callSuperField() => field();

  /*element: Class.callSuperGetter:SideEffects(reads anything; writes anything)*/
  callSuperGetter() => getter();

  /*element: Class.call:SideEffects(reads nothing; writes nothing)*/
  call() {}
}

/*element: callCall:SideEffects(reads anything; writes anything)*/
callCall(c) => c.call();

/*element: main:SideEffects(reads anything; writes anything)*/
main() {
  var c = new Class();
  callExpression();
  c.callSuperField();
  c.callSuperGetter();
  callCall(c);
}
