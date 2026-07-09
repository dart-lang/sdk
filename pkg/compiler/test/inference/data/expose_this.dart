// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: _method1:[null|powerset={null}]*/
_method1(/*[exact=Class1|powerset={N}{O}{N}]*/ o) {}

class Class1 {
  // The inferred type of the field includes `null` because `this` has been
  // exposed before its initialization.
  /*member: Class1.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
  Class1() {
    _method1(this);
    /*update: [exact=Class1|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis1:[exact=Class1|powerset={N}{O}{N}]*/
exposeThis1() => Class1();

////////////////////////////////////////////////////////////////////////////////
// Expose this trough a instance method invocation on this.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*member: Class2.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
  Class2() {
    /*invoke: [exact=Class2|powerset={N}{O}{N}]*/
    method();
    /*update: [exact=Class2|powerset={N}{O}{N}]*/
    field = 42;
  }

  /*member: Class2.method:[null|powerset={null}]*/
  method() {}
}

/*member: exposeThis2:[exact=Class2|powerset={N}{O}{N}]*/
exposeThis2() => Class2();

////////////////////////////////////////////////////////////////////////////////
// A this expression itself does _not_ expose this.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*member: Class3.field:[exact=JSUInt31|powerset={I}{O}{N}]*/
  var field;

  /*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
  Class3() {
    this;
    /*update: [exact=Class3|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis3:[exact=Class3|powerset={N}{O}{N}]*/
exposeThis3() => Class3();

////////////////////////////////////////////////////////////////////////////////
// Expose this through a static field assignment.
////////////////////////////////////////////////////////////////////////////////

/*member: field1:[null|exact=Class4|powerset={null}{N}{O}{N}]*/
var field1;

class Class4 {
  /*member: Class4.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class4.:[exact=Class4|powerset={N}{O}{N}]*/
  Class4() {
    field1 = this;
    /*update: [exact=Class4|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis4:[exact=Class4|powerset={N}{O}{N}]*/
exposeThis4() => Class4();

////////////////////////////////////////////////////////////////////////////////
// Expose this through an instance field assignment.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  /*member: Class5.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class5.:[exact=Class5|powerset={N}{O}{N}]*/
  Class5(/*[null|powerset={null}]*/ o) {
    o. /*update: [null|powerset={null}]*/ field5 = this;
    /*update: [exact=Class5|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis5:[exact=Class5|powerset={N}{O}{N}]*/
exposeThis5() => Class5(null);

////////////////////////////////////////////////////////////////////////////////
// Expose this through a local variable assignment.
////////////////////////////////////////////////////////////////////////////////

class Class6 {
  /*member: Class6.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class6.:[exact=Class6|powerset={N}{O}{N}]*/
  Class6() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o;
    o = this;
    /*update: [exact=Class6|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis6:[exact=Class6|powerset={N}{O}{N}]*/
exposeThis6() => Class6();

////////////////////////////////////////////////////////////////////////////////
// Expose this through a local variable initializer.
////////////////////////////////////////////////////////////////////////////////

class Class7 {
  /*member: Class7.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class7.:[exact=Class7|powerset={N}{O}{N}]*/
  Class7() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o = this;
    /*update: [exact=Class7|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis7:[exact=Class7|powerset={N}{O}{N}]*/
exposeThis7() => Class7();
