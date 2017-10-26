// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: callExpression:Depends on [] field store static store, Changes [] field static.*/
callExpression() => (null)();

/*element: Super.:Depends on nothing, Changes nothing.*/
class Super {
  var field;

  /*element: Super.getter:Depends on nothing, Changes nothing.*/
  get getter => null;
}

/*element: Class.:Depends on nothing, Changes nothing.*/
class Class extends Super {
  /*element: Class.callSuperField:Depends on [] field store static store, Changes [] field static.*/
  callSuperField() => field();

  /*element: Class.callSuperGetter:Depends on [] field store static store, Changes [] field static.*/
  callSuperGetter() => getter();

  /*element: Class.call:Depends on nothing, Changes nothing.*/
  call() {}
}

/*element: callCall:Depends on [] field store static store, Changes [] field static.*/
callCall(c) => c.call();

/*element: main:Depends on [] field store static store, Changes [] field static.*/
main() {
  var c = new Class();
  callExpression();
  c.callSuperField();
  c.callSuperGetter();
  callCall(c);
}
