// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  directCall();
  indirectCall();
  instanceTearOff();
  localCall();
  instantiatedCall();
}

/*member: _directCall:apply*/
_directCall() {}

/*member: directCall:*/
void directCall() {
  Function.apply(_directCall, []);
}

/*member: _indirectCall:apply*/
_indirectCall() {}

/*member: _indirectCallHelper:*/
_indirectCallHelper(f) => Function.apply(f, []);

/*member: indirectCall:*/
void indirectCall() {
  _indirectCallHelper(_indirectCall);
}

/*member: Class.:*/
class Class {
  /*member: Class.instanceTearOff1:apply*/
  instanceTearOff1() {}

  /*member: Class.instanceTearOff2:*/
  instanceTearOff2() {}
}

/*member: _instanceTearOffHelper:*/
_instanceTearOffHelper(f) => Function.apply(f, []);

instanceTearOff() {
  var c = new Class();
  _instanceTearOffHelper(c.instanceTearOff1);
  return c.instanceTearOff2;
}

localCall() {
  /*apply*/ local1() {}
  local2() {}
  local3() {}

  Function.apply(local1, []);
  local2();
  return local3;
}

instantiatedCall() {
  /*apply*/ local1<T>(T t) {}
  local2<T>(T t) {}
  local3<T>(T t) {}

  Function(int) f1 = local1;
  Function(int) f2 = local2;
  Function(int) f3 = local3;

  Function.apply(f1, [0]);
  f2(0);
  return f3;
}
