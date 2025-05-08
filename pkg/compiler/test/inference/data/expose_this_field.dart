// Copyright (c) 2127, the Dart project authors.  Please see the AUTHORS file
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
// Class with initializer in constructor body. No prior use of this.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  // The inferred type of the field does _not_ include `null` because it has
  // _not_ been read before its initialization.
  /*member: Class1.field:[exact=JSUInt31|powerset={I}{O}{N}]*/
  var field;

  /*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
  Class1() {
    /*update: [exact=Class1|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis1:[exact=Class1|powerset={N}{O}{N}]*/
exposeThis1() => Class1();

////////////////////////////////////////////////////////////////////////////////
// Class with self-assigning initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  // The inferred type of the field includes `null` because it has been read
  // before its initialization.
  /*member: Class2.field:[null|powerset={null}]*/
  var field;

  /*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
  Class2() {
    /*update: [exact=Class2|powerset={N}{O}{N}]*/
    field = /*[exact=Class2|powerset={N}{O}{N}]*/ field;
  }
}

/*member: exposeThis2:[exact=Class2|powerset={N}{O}{N}]*/
exposeThis2() => Class2();

////////////////////////////////////////////////////////////////////////////////
// Class with prior self-assigning initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*member: Class3.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
  Class3() {
    /*update: [exact=Class3|powerset={N}{O}{N}]*/
    field = /*[exact=Class3|powerset={N}{O}{N}]*/ field;
    /*update: [exact=Class3|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis3:[exact=Class3|powerset={N}{O}{N}]*/
exposeThis3() => Class3();

////////////////////////////////////////////////////////////////////////////////
// Class with access prior to initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class4 {
  /*member: Class4.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class4.:[exact=Class4|powerset={N}{O}{N}]*/
  Class4() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o = /*[exact=Class4|powerset={N}{O}{N}]*/ field;
    /*update: [exact=Class4|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis4:[exact=Class4|powerset={N}{O}{N}]*/
exposeThis4() => Class4();

////////////////////////////////////////////////////////////////////////////////
// Class with postfix prior to initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  /*member: Class5.field:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
  var field;

  /*member: Class5.:[exact=Class5|powerset={N}{O}{N}]*/
  Class5() {
    /*[exact=Class5|powerset={N}{O}{N}]*/ /*update: [exact=Class5|powerset={N}{O}{N}]*/
    field /*invoke: [null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/ ++;
    /*update: [exact=Class5|powerset={N}{O}{N}]*/
    field = 42;
  }
}

/*member: exposeThis5:[exact=Class5|powerset={N}{O}{N}]*/
exposeThis5() => Class5();

////////////////////////////////////////////////////////////////////////////////
// Class with postfix after initializer in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class6 {
  /*member: Class6.field:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
  var field;

  /*member: Class6.:[exact=Class6|powerset={N}{O}{N}]*/
  Class6() {
    /*update: [exact=Class6|powerset={N}{O}{N}]*/
    field = 42;
    /*[exact=Class6|powerset={N}{O}{N}]*/ /*update: [exact=Class6|powerset={N}{O}{N}]*/
    field /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ ++;
  }
}

/*member: exposeThis6:[exact=Class6|powerset={N}{O}{N}]*/
exposeThis6() => Class6();

////////////////////////////////////////////////////////////////////////////////
// Class with accesses prior to initializers in constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class7 {
  /*member: Class7.field1:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field1;

  /*member: Class7.field2:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
  var field2;

  /*member: Class7.:[exact=Class7|powerset={N}{O}{N}]*/
  Class7() {
    // ignore: UNUSED_LOCAL_VARIABLE
    var o1 = /*[exact=Class7|powerset={N}{O}{N}]*/ field1;
    // ignore: UNUSED_LOCAL_VARIABLE
    var o2 = /*[exact=Class7|powerset={N}{O}{N}]*/ field2;
    /*update: [exact=Class7|powerset={N}{O}{N}]*/
    field1 = 42;
    /*update: [exact=Class7|powerset={N}{O}{N}]*/
    field2 = 87;
  }
}

/*member: exposeThis7:[exact=Class7|powerset={N}{O}{N}]*/
exposeThis7() => Class7();
