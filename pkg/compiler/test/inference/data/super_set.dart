// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  superFieldUpdate();
  superSetterUpdate();
}

////////////////////////////////////////////////////////////////////////////////
// Update of super field.
////////////////////////////////////////////////////////////////////////////////

/*member: Super1.:[empty|powerset=empty]*/
class Super1 {
  /*member: Super1.field:Union([exact=JSUInt31|powerset={I}{O}{N}], [exact=Sub1|powerset={N}{O}{N}], powerset: {IN}{O}{N})*/
  dynamic field = 42;
}

/*member: Sub1.:[exact=Sub1|powerset={N}{O}{N}]*/
class Sub1 extends Super1 {
  /*member: Sub1.method:[subclass=Closure|powerset={N}{O}{N}]*/
  method() {
    var a = super.field = Sub1();
    return a. /*[exact=Sub1|powerset={N}{O}{N}]*/ method;
  }
}

/*member: superFieldUpdate:[null|powerset={null}]*/
superFieldUpdate() {
  Sub1(). /*invoke: [exact=Sub1|powerset={N}{O}{N}]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Update of super setter.
////////////////////////////////////////////////////////////////////////////////

/*member: Super2.:[empty|powerset=empty]*/
class Super2 {
  set setter(/*[exact=Sub2|powerset={N}{O}{N}]*/ value) {}
}

/*member: Sub2.:[exact=Sub2|powerset={N}{O}{N}]*/
class Sub2 extends Super2 {
  /*member: Sub2.method:[subclass=Closure|powerset={N}{O}{N}]*/
  method() {
    var a = super.setter = Sub2();
    return a. /*[exact=Sub2|powerset={N}{O}{N}]*/ method;
  }
}

/*member: superSetterUpdate:[null|powerset={null}]*/
superSetterUpdate() {
  Sub2(). /*invoke: [exact=Sub2|powerset={N}{O}{N}]*/ method();
}
