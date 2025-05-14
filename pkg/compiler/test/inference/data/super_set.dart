// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  superFieldUpdate();
  superSetterUpdate();
}

////////////////////////////////////////////////////////////////////////////////
// Update of super field.
////////////////////////////////////////////////////////////////////////////////

/*member: Super1.:[exact=Super1|powerset=0]*/
class Super1 {
  /*member: Super1.field:Union([exact=JSUInt31|powerset=0], [exact=Sub1|powerset=0], powerset: 0)*/
  dynamic field = 42;
}

/*member: Sub1.:[exact=Sub1|powerset=0]*/
class Sub1 extends Super1 {
  /*member: Sub1.method:[subclass=Closure|powerset=0]*/
  method() {
    var a = super.field = Sub1();
    return a. /*[exact=Sub1|powerset=0]*/ method;
  }
}

/*member: superFieldUpdate:[null|powerset=1]*/
superFieldUpdate() {
  Sub1(). /*invoke: [exact=Sub1|powerset=0]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Update of super setter.
////////////////////////////////////////////////////////////////////////////////

/*member: Super2.:[exact=Super2|powerset=0]*/
class Super2 {
  set setter(/*[exact=Sub2|powerset=0]*/ value) {}
}

/*member: Sub2.:[exact=Sub2|powerset=0]*/
class Sub2 extends Super2 {
  /*member: Sub2.method:[subclass=Closure|powerset=0]*/
  method() {
    var a = super.setter = Sub2();
    return a. /*[exact=Sub2|powerset=0]*/ method;
  }
}

/*member: superSetterUpdate:[null|powerset=1]*/
superSetterUpdate() {
  Sub2(). /*invoke: [exact=Sub2|powerset=0]*/ method();
}
