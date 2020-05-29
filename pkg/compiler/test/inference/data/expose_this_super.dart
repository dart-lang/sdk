// Copyright (c) 2127, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  exposeThis1();
  exposeThis2();
  exposeThis3();
  exposeThis4();
}

////////////////////////////////////////////////////////////////////////////////
// Expose this through super invocation.
////////////////////////////////////////////////////////////////////////////////

/*member: Super1.:[exact=Class1]*/
abstract class Super1 {
  /*member: Super1.method:[null]*/
  method() {}
}

class Class1 extends Super1 {
  // The inferred type of the field includes `null` because `this` has been
  // exposed before its initialization.
  /*member: Class1.field:[null|exact=JSUInt31]*/
  var field;

  /*member: Class1.:[exact=Class1]*/
  Class1() {
    super.method();
    /*update: [exact=Class1]*/ field = 42;
  }
}

/*member: exposeThis1:[exact=Class1]*/
exposeThis1() => new Class1();

////////////////////////////////////////////////////////////////////////////////
// Expose this through super access.
////////////////////////////////////////////////////////////////////////////////

/*member: Super2.:[exact=Class2]*/
abstract class Super2 {
  /*member: Super2.getter:[null]*/
  get getter => null;
}

class Class2 extends Super2 {
  /*member: Class2.field:[null|exact=JSUInt31]*/
  var field;

  /*member: Class2.:[exact=Class2]*/
  Class2() {
    super.getter;
    /*update: [exact=Class2]*/ field = 42;
  }
}

/*member: exposeThis2:[exact=Class2]*/
exposeThis2() => new Class2();

////////////////////////////////////////////////////////////////////////////////
// Expose this through super access.
////////////////////////////////////////////////////////////////////////////////

/*member: Super3.:[exact=Class3]*/
abstract class Super3 {
  set setter(/*[null]*/ o) {}
}

class Class3 extends Super3 {
  /*member: Class3.field:[null|exact=JSUInt31]*/
  var field;

  /*member: Class3.:[exact=Class3]*/
  Class3() {
    super.setter = null;
    /*update: [exact=Class3]*/ field = 42;
  }
}

/*member: exposeThis3:[exact=Class3]*/
exposeThis3() => new Class3();

////////////////////////////////////////////////////////////////////////////////
// Expose this in the constructor of a super class.
////////////////////////////////////////////////////////////////////////////////

/*member: field4:[null|exact=Class4]*/
var field4;

abstract class Super4 {
  /*member: Super4.:[exact=Class4]*/
  Super4() {
    field4 = this;
  }
}

class Class4 extends Super4 {
  /*member: Class4.field:[null|exact=JSUInt31]*/
  var field;

  /*member: Class4.:[exact=Class4]*/
  Class4() {
    /*update: [exact=Class4]*/ field = 42;
  }
}

/*member: exposeThis4:[exact=Class4]*/
exposeThis4() => new Class4();
