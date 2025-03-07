// Copyright (c) 2127, the Dart project authors.  Please see the AUTHORS file
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
// Class with initializer in constructor body. No prior use of this.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  // The inferred type of the field does _not_ include `null` because it has
  // _not_ been read before its initialization.
  /*member: Class1.field:[exact=JSUInt31|powerset=0]*/
  var field;

  /*member: Class1.:[exact=Class1|powerset=0]*/
  Class1() {
    /*update: [exact=Class1|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis1:[exact=Class1|powerset=0]*/
exposeThis1() => Class1();

////////////////////////////////////////////////////////////////////////////////
// Class with self-assigning initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  // The inferred type of the field includes `null` because it has been read
  // before its initialization.
  /*member: Class2.field:[null|powerset=1]*/
  var field;

  /*member: Class2.:[exact=Class2|powerset=0]*/
  Class2() {
    /*update: [exact=Class2|powerset=0]*/
    field = /*[exact=Class2|powerset=0]*/ field;
  }
}

/*member: exposeThis2:[exact=Class2|powerset=0]*/
exposeThis2() => Class2();

////////////////////////////////////////////////////////////////////////////////
// Class with prior self-assigning initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*member: Class3.field:[null|exact=JSUInt31|powerset=1]*/
  var field;

  /*member: Class3.:[exact=Class3|powerset=0]*/
  Class3() {
    /*update: [exact=Class3|powerset=0]*/
    field = /*[exact=Class3|powerset=0]*/ field;
    /*update: [exact=Class3|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis3:[exact=Class3|powerset=0]*/
exposeThis3() => Class3();

////////////////////////////////////////////////////////////////////////////////
// Class with access prior to initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class4 {
  /*member: Class4.field:[null|exact=JSUInt31|powerset=1]*/
  var field;

  /*member: Class4.:[exact=Class4|powerset=0]*/
  Class4() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o = /*[exact=Class4|powerset=0]*/ field;
    /*update: [exact=Class4|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis4:[exact=Class4|powerset=0]*/
exposeThis4() => Class4();

////////////////////////////////////////////////////////////////////////////////
// Class with postfix prior to initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  /*member: Class5.field:[null|subclass=JSPositiveInt|powerset=1]*/
  var field;

  /*member: Class5.:[exact=Class5|powerset=0]*/
  Class5() {
    /*[exact=Class5|powerset=0]*/ /*update: [exact=Class5|powerset=0]*/
    field /*invoke: [null|subclass=JSPositiveInt|powerset=1]*/ ++;
    /*update: [exact=Class5|powerset=0]*/
    field = 42;
  }
}

/*member: exposeThis5:[exact=Class5|powerset=0]*/
exposeThis5() => Class5();

////////////////////////////////////////////////////////////////////////////////
// Class with postfix after initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class6 {
  /*member: Class6.field:[subclass=JSPositiveInt|powerset=0]*/
  var field;

  /*member: Class6.:[exact=Class6|powerset=0]*/
  Class6() {
    /*update: [exact=Class6|powerset=0]*/
    field = 42;
    /*[exact=Class6|powerset=0]*/ /*update: [exact=Class6|powerset=0]*/
    field /*invoke: [subclass=JSPositiveInt|powerset=0]*/ ++;
  }
}

/*member: exposeThis6:[exact=Class6|powerset=0]*/
exposeThis6() => Class6();

////////////////////////////////////////////////////////////////////////////////
// Class with accesses prior to initializers in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class7 {
  /*member: Class7.field1:[null|exact=JSUInt31|powerset=1]*/
  var field1;

  /*member: Class7.field2:[null|exact=JSUInt31|powerset=1]*/
  var field2;

  /*member: Class7.:[exact=Class7|powerset=0]*/
  Class7() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o1 = /*[exact=Class7|powerset=0]*/ field1;
    // ignore: UNUSED_LOCAL_VARIABLE
    var o2 = /*[exact=Class7|powerset=0]*/ field2;
    /*update: [exact=Class7|powerset=0]*/
    field1 = 42;
    /*update: [exact=Class7|powerset=0]*/
    field2 = 87;
  }
}

/*member: exposeThis7:[exact=Class7|powerset=0]*/
exposeThis7() => Class7();
