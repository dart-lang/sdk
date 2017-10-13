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
  exposeThis6();
  exposeThis7();
}

////////////////////////////////////////////////////////////////////////////////
// Expose this through a top level method invocation.
////////////////////////////////////////////////////////////////////////////////

/*element: _method1:[null]*/
_method1(/*[exact=Class1]*/ o) {}

class Class1 {
  // The inferred type of the field includes `null` because `this` has been
  // exposed before its initialization.
  /*element: Class1.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class1.:[exact=Class1]*/
  Class1() {
    _method1(this);
    /*update: [exact=Class1]*/ field = 42;
  }
}

/*element: exposeThis1:[exact=Class1]*/
exposeThis1() => new Class1();

////////////////////////////////////////////////////////////////////////////////
// Expose this trough a instance method invocation on this.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*element: Class2.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class2.:[exact=Class2]*/
  Class2() {
    /*invoke: [exact=Class2]*/ method();
    /*update: [exact=Class2]*/ field = 42;
  }

  /*element: Class2.method:[null]*/
  method() {}
}

/*element: exposeThis2:[exact=Class2]*/
exposeThis2() => new Class2();

////////////////////////////////////////////////////////////////////////////////
// A this expression itself does _not_ expose this.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*element: Class3.field:[exact=JSUInt31]*/
  var field;

  /*element: Class3.:[exact=Class3]*/
  Class3() {
    this;
    /*update: [exact=Class3]*/ field = 42;
  }

  /*element: Class3.method:[null]*/
  method() {}
}

/*element: exposeThis3:[exact=Class3]*/
exposeThis3() => new Class3();

////////////////////////////////////////////////////////////////////////////////
// Expose this through a static field assignment.
////////////////////////////////////////////////////////////////////////////////

/*element: _field1:[null|exact=Class4]*/
var _field1;

class Class4 {
  /*element: Class4.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class4.:[exact=Class4]*/
  Class4() {
    _field1 = this;
    /*update: [exact=Class4]*/ field = 42;
  }
}

/*element: exposeThis4:[exact=Class4]*/
exposeThis4() => new Class4();

////////////////////////////////////////////////////////////////////////////////
// Expose this through an instance field assignment.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  /*element: Class5.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class5.:[exact=Class5]*/
  Class5(/*[null]*/ o) {
    o. /*update: [null]*/ field5 = this;
    /*update: [exact=Class5]*/ field = 42;
  }
}

/*element: exposeThis5:[exact=Class5]*/
exposeThis5() => new Class5(null);

////////////////////////////////////////////////////////////////////////////////
// Expose this through a local variable assignment.
////////////////////////////////////////////////////////////////////////////////

class Class6 {
  /*element: Class6.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class6.:[exact=Class6]*/
  Class6() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o;
    o = this;
    /*update: [exact=Class6]*/ field = 42;
  }
}

/*element: exposeThis6:[exact=Class6]*/
exposeThis6() => new Class6();

////////////////////////////////////////////////////////////////////////////////
// Expose this through a local variable initializer.
////////////////////////////////////////////////////////////////////////////////

class Class7 {
  /*element: Class7.field:[null|exact=JSUInt31]*/
  var field;

  /*element: Class7.:[exact=Class7]*/
  Class7() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o = this;
    /*update: [exact=Class7]*/ field = 42;
  }
}

/*element: exposeThis7:[exact=Class7]*/
exposeThis7() => new Class7();
