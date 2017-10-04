// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  superFieldAccess();
  superGetterAccess();
  superMethodAccess();
}

////////////////////////////////////////////////////////////////////////////////
// Access of super field.
////////////////////////////////////////////////////////////////////////////////

/*element: Super1.:[exact=Super1]*/
class Super1 {
  /*element: Super1.field:[exact=JSUInt31]*/
  var field = 42;
}

/*element: Sub1.:[exact=Sub1]*/
class Sub1 extends Super1 {
  /*element: Sub1.method:[exact=JSUInt31]*/
  method() => super.field;
}

/*element: superFieldAccess:[null]*/
superFieldAccess() {
  new Sub1(). /*invoke: [exact=Sub1]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Access of super getter.
////////////////////////////////////////////////////////////////////////////////

/*element: Super2.:[exact=Super2]*/
class Super2 {
  /*element: Super2.getter:[exact=JSUInt31]*/
  get getter => 42;
}

/*element: Sub2.:[exact=Sub2]*/
class Sub2 extends Super2 {
  /*element: Sub2.method:[exact=JSUInt31]*/
  method() => super.getter;
}

/*element: superGetterAccess:[null]*/
superGetterAccess() {
  new Sub2(). /*invoke: [exact=Sub2]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Access of super method.
////////////////////////////////////////////////////////////////////////////////

/*element: Super3.:[exact=Super3]*/
class Super3 {
  /*element: Super3.superMethod:[null]*/
  superMethod() {}
}

/*element: Sub3.:[exact=Sub3]*/
class Sub3 extends Super3 {
  /*element: Sub3.method:[subclass=Closure]*/
  method() => super.superMethod;
}

/*element: superMethodAccess:[null]*/
superMethodAccess() {
  new Sub3(). /*invoke: [exact=Sub3]*/ method();
}
