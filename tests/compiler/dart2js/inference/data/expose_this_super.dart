// Copyright (c) 2127, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  exposeThis1();
  exposeThis2();
  exposeThis3();
  exposeThis4();
}

////////////////////////////////////////////////////////////////////////////////
// Expose this through super invocation.
////////////////////////////////////////////////////////////////////////////////

/*element: Super1.:[exact=Class1]*/
abstract class Super1 {
  /*element: Super1.method:[null]*/
  method() {}
}

class Class1 extends Super1 {
  // The inferred type of the field includes `null` because `this` has been
  // exposed before its initialization.
  /*element: Class1.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class1.:[exact=Class1]*/
  Class1() {
    super.method();
    /*update: [exact=Class1]*/ field = 42;
  }
}

/*element: exposeThis1:[exact=Class1]*/
exposeThis1() => new Class1();

////////////////////////////////////////////////////////////////////////////////
// Expose this through super access.
////////////////////////////////////////////////////////////////////////////////

/*element: Super2.:[exact=Class2]*/
abstract class Super2 {
  /*element: Super2.getter:[null]*/
  get getter => null;
}

class Class2 extends Super2 {
  /*element: Class2.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class2.:[exact=Class2]*/
  Class2() {
    super.getter;
    /*update: [exact=Class2]*/ field = 42;
  }
}

/*element: exposeThis2:[exact=Class2]*/
exposeThis2() => new Class2();

////////////////////////////////////////////////////////////////////////////////
// Expose this through super access.
////////////////////////////////////////////////////////////////////////////////

/*element: Super3.:[exact=Class3]*/
abstract class Super3 {
  set setter(/*[null]*/ o) {}
}

class Class3 extends Super3 {
  /*element: Class3.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class3.:[exact=Class3]*/
  Class3() {
    super.setter = null;
    /*update: [exact=Class3]*/ field = 42;
  }
}

/*element: exposeThis3:[exact=Class3]*/
exposeThis3() => new Class3();

////////////////////////////////////////////////////////////////////////////////
// Expose this in the constructor of a super class.
////////////////////////////////////////////////////////////////////////////////

/*element: _field4:[null|exact=Class4]*/
var _field4;

abstract class Super4 {
  /*element: Super4.:[exact=Class4]*/
  Super4() {
    _field4 = this;
  }
}

class Class4 extends Super4 {
  /*element: Class4.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class4.:[exact=Class4]*/
  Class4() {
    /*update: [exact=Class4]*/ field = 42;
  }
}

/*element: exposeThis4:[exact=Class4]*/
exposeThis4() => new Class4();
