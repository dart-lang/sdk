// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  exposeThis1();
  exposeThis2();
  exposeThis3();
  exposeThis4();
  exposeThis5();
}

////////////////////////////////////////////////////////////////////////////////
// Class with two initializers. No closure.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  // The inferred type of the field does _not_ include `null` because `this`
  // is _not_ been exposed.
  /*element: Class1.field1:[exact=JSUInt31]*/
  var field1;
  /*element: Class1.field2:[exact=JSUInt31]*/
  var field2;

  /*element: Class1.:[exact=Class1]*/
  Class1()
      : field1 = 42,
        field2 = 87;
}

/*element: exposeThis1:[exact=Class1]*/
exposeThis1() => new Class1();

////////////////////////////////////////////////////////////////////////////////
// Class with initializers in the constructor body. No closure.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*element: Class2.field1:[exact=JSUInt31]*/
  var field1;
  /*element: Class2.field2:[exact=JSUInt31]*/
  var field2;

  /*element: Class2.:[exact=Class2]*/
  Class2() {
    /*update: [exact=Class2]*/ field1 = 42;
    /*update: [exact=Class2]*/ field2 = 87;
  }
}

/*element: exposeThis2:[exact=Class2]*/
exposeThis2() => new Class2();

////////////////////////////////////////////////////////////////////////////////
// Class with super call containing closure between two initializers.
////////////////////////////////////////////////////////////////////////////////

abstract class SuperClass1 {
  /*element: SuperClass1.:[exact=Class3]*/
  SuperClass1(/*[null|subclass=Object]*/ o);
}

class Class3 extends SuperClass1 {
  /*element: Class3.field1:[exact=JSUInt31]*/
  var field1;
  // The inferred type of the field includes `null` because `this` has been
  // exposed before its initialization.
  /*element: Class3.field2:[null|exact=JSUInt31]*/
  var field2;

  /*element: Class3.:[exact=Class3]*/
  Class3()
      : field1 = 42,
        // ignore: STRONG_MODE_INVALID_SUPER_INVOCATION
        super(/*[exact=JSUInt31]*/ () {
          return 42;
        }()),
        field2 = 87;
}

/*element: exposeThis3:[exact=Class3]*/
exposeThis3() => new Class3();

////////////////////////////////////////////////////////////////////////////////
// Class with closure after two initializers in the constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class4 {
  /*element: Class4.field1:[exact=JSUInt31]*/
  var field1;
  /*element: Class4.field2:[exact=JSUInt31]*/
  var field2;

  /*element: Class4.:[exact=Class4]*/
  Class4()
      : field1 = 42,
        field2 = 87 {
    /*[exact=JSUInt31]*/ () {
      return 42;
    };
  }
}

/*element: exposeThis4:[exact=Class4]*/
exposeThis4() => new Class4();

////////////////////////////////////////////////////////////////////////////////
// Class with closure between two initializers in the constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  /*element: Class5.field1:[exact=JSUInt31]*/
  var field1;
  /*element: Class5.field2:[null|exact=JSUInt31]*/
  var field2;

  /*element: Class5.:[exact=Class5]*/
  Class5() {
    /*update: [exact=Class5]*/ field1 = 42;
    /*[exact=JSUInt31]*/ () {
      return 42;
    };
    /*update: [exact=Class5]*/ field2 = 87;
  }
}

/*element: exposeThis5:[exact=Class5]*/
exposeThis5() => new Class5();
