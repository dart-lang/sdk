// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  superFieldUpdate();
  superSetterUpdate();
}

////////////////////////////////////////////////////////////////////////////////
// Update of super field.
////////////////////////////////////////////////////////////////////////////////

/*member: Super1.:[exact=Super1]*/
class Super1 {
  /*member: Super1.field:Union([exact=JSUInt31], [exact=Sub1])*/
  dynamic field = 42;
}

/*member: Sub1.:[exact=Sub1]*/
class Sub1 extends Super1 {
  /*member: Sub1.method:[subclass=Closure]*/
  method() {
    var a = super.field = new Sub1();
    return a. /*[exact=Sub1]*/ method;
  }
}

/*member: superFieldUpdate:[null]*/
superFieldUpdate() {
  new Sub1(). /*invoke: [exact=Sub1]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Update of super setter.
////////////////////////////////////////////////////////////////////////////////

/*member: Super2.:[exact=Super2]*/
class Super2 {
  set setter(/*[exact=Sub2]*/ value) {}
}

/*member: Sub2.:[exact=Sub2]*/
class Sub2 extends Super2 {
  /*member: Sub2.method:[subclass=Closure]*/
  method() {
    var a = super.setter = new Sub2();
    return a. /*[exact=Sub2]*/ method;
  }
}

/*member: superSetterUpdate:[null]*/
superSetterUpdate() {
  new Sub2(). /*invoke: [exact=Sub2]*/ method();
}
