// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  superFieldUpdate();
  superSetterUpdate();
}

////////////////////////////////////////////////////////////////////////////////
// Update of super field.
////////////////////////////////////////////////////////////////////////////////

/*element: Super1.:[exact=Super1]*/
class Super1 {
  /*element: Super1.field:Union of [[exact=JSUInt31], [exact=Sub1]]*/
  dynamic field = 42;
}

/*element: Sub1.:[exact=Sub1]*/
class Sub1 extends Super1 {
  /*element: Sub1.method:[subclass=Closure]*/
  method() {
    var a = super.field = new Sub1();
    return a. /*[exact=Sub1]*/ method;
  }
}

/*element: superFieldUpdate:[null]*/
superFieldUpdate() {
  new Sub1(). /*invoke: [exact=Sub1]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Update of super setter.
////////////////////////////////////////////////////////////////////////////////

/*element: Super2.:[exact=Super2]*/
class Super2 {
  set setter(/*[exact=Sub2]*/ value) {}
}

/*element: Sub2.:[exact=Sub2]*/
class Sub2 extends Super2 {
  /*element: Sub2.method:[subclass=Closure]*/
  method() {
    var a = super.setter = new Sub2();
    return a. /*[exact=Sub2]*/ method;
  }
}

/*element: superSetterUpdate:[null]*/
superSetterUpdate() {
  new Sub2(). /*invoke: [exact=Sub2]*/ method();
}
