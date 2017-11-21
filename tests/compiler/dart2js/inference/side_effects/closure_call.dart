// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: callExpression:Reads anything; writes anything.*/
callExpression() => (null)();

/*element: Super.:Reads nothing; writes nothing.*/
class Super {
  var field;

  /*element: Super.getter:Reads nothing; writes nothing.*/
  get getter => null;
}

/*element: Class.:Reads nothing; writes nothing.*/
class Class extends Super {
  /*element: Class.callSuperField:Reads anything; writes anything.*/
  callSuperField() => field();

  /*element: Class.callSuperGetter:Reads anything; writes anything.*/
  callSuperGetter() => getter();

  /*element: Class.call:Reads nothing; writes nothing.*/
  call() {}
}

/*element: callCall:Reads anything; writes anything.*/
callCall(c) => c.call();

/*element: main:Reads anything; writes anything.*/
main() {
  var c = new Class();
  callExpression();
  c.callSuperField();
  c.callSuperGetter();
  callCall(c);
}
