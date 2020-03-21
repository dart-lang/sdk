// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  superFieldAccess();
  superGetterAccess();
  superMethodAccess();
}

////////////////////////////////////////////////////////////////////////////////
// Access of super field.
////////////////////////////////////////////////////////////////////////////////

/*member: Super1.:[exact=Super1]*/
class Super1 {
  /*member: Super1.field:[exact=JSUInt31]*/
  var field = 42;
}

/*member: Sub1.:[exact=Sub1]*/
class Sub1 extends Super1 {
  /*member: Sub1.method:[exact=JSUInt31]*/
  method() => super.field;
}

/*member: superFieldAccess:[null]*/
superFieldAccess() {
  new Sub1(). /*invoke: [exact=Sub1]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Access of super getter.
////////////////////////////////////////////////////////////////////////////////

/*member: Super2.:[exact=Super2]*/
class Super2 {
  /*member: Super2.getter:[exact=JSUInt31]*/
  get getter => 42;
}

/*member: Sub2.:[exact=Sub2]*/
class Sub2 extends Super2 {
  /*member: Sub2.method:[exact=JSUInt31]*/
  method() => super.getter;
}

/*member: superGetterAccess:[null]*/
superGetterAccess() {
  new Sub2(). /*invoke: [exact=Sub2]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Access of super method.
////////////////////////////////////////////////////////////////////////////////

/*member: Super3.:[exact=Super3]*/
class Super3 {
  /*member: Super3.superMethod:[null]*/
  superMethod() {}
}

/*member: Sub3.:[exact=Sub3]*/
class Sub3 extends Super3 {
  /*member: Sub3.method:[subclass=Closure]*/
  method() => super.superMethod;
}

/*member: superMethodAccess:[null]*/
superMethodAccess() {
  new Sub3(). /*invoke: [exact=Sub3]*/ method();
}
