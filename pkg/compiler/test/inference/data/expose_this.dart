// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: _method1:[null|powerset=1]*/
_method1(/*[exact=Class1|powerset=0]*/ o) {}

class Class1 {
  // The inferred type of the field includes `null` because `this` has been
  // exposed before its initialization.
  /*member: Class1.field:[null|exact=JSUInt31|powerset=1]*/
  var field;

  /*member: Class1.:[exact=Class1|powerset=0]*/
  Class1() {
    _method1(this);
    /*update: [exact=Class1|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis1:[exact=Class1|powerset=0]*/
exposeThis1() => Class1();

////////////////////////////////////////////////////////////////////////////////
// Expose this trough a instance method invocation on this.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*member: Class2.field:[null|exact=JSUInt31|powerset=1]*/
  var field;

  /*member: Class2.:[exact=Class2|powerset=0]*/
  Class2() {
    /*invoke: [exact=Class2|powerset=0]*/
    method();
    /*update: [exact=Class2|powerset=0]*/
    field = 42;
  }

  /*member: Class2.method:[null|powerset=1]*/
  method() {}
}

/*member: exposeThis2:[exact=Class2|powerset=0]*/
exposeThis2() => Class2();

////////////////////////////////////////////////////////////////////////////////
// A this expression itself does _not_ expose this.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*member: Class3.field:[exact=JSUInt31|powerset=0]*/
  var field;

  /*member: Class3.:[exact=Class3|powerset=0]*/
  Class3() {
    this;
    /*update: [exact=Class3|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis3:[exact=Class3|powerset=0]*/
exposeThis3() => Class3();

////////////////////////////////////////////////////////////////////////////////
// Expose this through a static field assignment.
////////////////////////////////////////////////////////////////////////////////

/*member: field1:[null|exact=Class4|powerset=1]*/
var field1;

class Class4 {
  /*member: Class4.field:[null|exact=JSUInt31|powerset=1]*/
  var field;

  /*member: Class4.:[exact=Class4|powerset=0]*/
  Class4() {
    field1 = this;
    /*update: [exact=Class4|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis4:[exact=Class4|powerset=0]*/
exposeThis4() => Class4();

////////////////////////////////////////////////////////////////////////////////
// Expose this through an instance field assignment.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  /*member: Class5.field:[null|exact=JSUInt31|powerset=1]*/
  var field;

  /*member: Class5.:[exact=Class5|powerset=0]*/
  Class5(/*[null|powerset=1]*/ o) {
    o. /*update: [null|powerset=1]*/ field5 = this;
    /*update: [exact=Class5|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis5:[exact=Class5|powerset=0]*/
exposeThis5() => Class5(null);

////////////////////////////////////////////////////////////////////////////////
// Expose this through a local variable assignment.
////////////////////////////////////////////////////////////////////////////////

class Class6 {
  /*member: Class6.field:[null|exact=JSUInt31|powerset=1]*/
  var field;

  /*member: Class6.:[exact=Class6|powerset=0]*/
  Class6() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o;
    o = this;
    /*update: [exact=Class6|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis6:[exact=Class6|powerset=0]*/
exposeThis6() => Class6();

////////////////////////////////////////////////////////////////////////////////
// Expose this through a local variable initializer.
////////////////////////////////////////////////////////////////////////////////

class Class7 {
  /*member: Class7.field:[null|exact=JSUInt31|powerset=1]*/
  var field;

  /*member: Class7.:[exact=Class7|powerset=0]*/
  Class7() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o = this;
    /*update: [exact=Class7|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis7:[exact=Class7|powerset=0]*/
exposeThis7() => Class7();
