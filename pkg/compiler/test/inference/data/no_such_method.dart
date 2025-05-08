// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  missingGetter();
  missingMethod();
  closureThroughMissingMethod();
  closureThroughMissingSetter();
}

////////////////////////////////////////////////////////////////////////////////
// Access missing getter.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}]*/
class Class1 {
  /*member: Class1.noSuchMethod:[exact=JSUInt31|powerset={I}{O}]*/
  noSuchMethod(
    Invocation
    /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
    /*prod.[exact=JSInvocationMirror|powerset={N}{O}]*/
    _,
  ) => 42;

  /*member: Class1.method:[exact=JSUInt31|powerset={I}{O}]*/
  method() {
    dynamic a = this;
    return a. /*[exact=Class1|powerset={N}{O}]*/ missingGetter;
  }
}

/*member: missingGetter:[exact=JSUInt31|powerset={I}{O}]*/
missingGetter() => Class1(). /*invoke: [exact=Class1|powerset={N}{O}]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Invoke missing method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}{O}]*/
class Class2 {
  /*member: Class2.noSuchMethod:[exact=JSUInt31|powerset={I}{O}]*/
  noSuchMethod(
    Invocation
    /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
    /*prod.[exact=JSInvocationMirror|powerset={N}{O}]*/
    _,
  ) => 42;

  /*member: Class2.method:[exact=JSUInt31|powerset={I}{O}]*/
  method() {
    dynamic a = this;
    return a. /*invoke: [exact=Class2|powerset={N}{O}]*/ missingMethod();
  }
}

/*member: missingMethod:[exact=JSUInt31|powerset={I}{O}]*/
missingMethod() => Class2(). /*invoke: [exact=Class2|powerset={N}{O}]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Pass closure to missing method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset={N}{O}]*/
class Class3 {
  /*member: Class3.noSuchMethod:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  noSuchMethod(
    Invocation
    /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
    /*prod.[exact=JSInvocationMirror|powerset={N}{O}]*/
    invocation,
  ) {
    return invocation
        .
        /*[exact=JSInvocationMirror|powerset={N}{O}]*/
        positionalArguments
        .
        /*[exact=JSUnmodifiableArray|powerset={I}{U}]*/
        first;
  }

  /*member: Class3.method:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  method() {
    dynamic a = this;
    return a. /*invoke: [exact=Class3|powerset={N}{O}]*/ missingMethod(
      /*[null|powerset={null}]*/ (
        /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ parameter,
      ) {},
    )(0);
  }
}

/*member: closureThroughMissingMethod:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
closureThroughMissingMethod() =>
    Class3(). /*invoke: [exact=Class3|powerset={N}{O}]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Pass closure to missing setter.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset={N}{O}]*/
class Class4 {
  /*member: Class4.field:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  var field;

  /*member: Class4.noSuchMethod:[null|powerset={null}]*/
  noSuchMethod(
    Invocation
    /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
    /*prod.[exact=JSInvocationMirror|powerset={N}{O}]*/
    invocation,
  ) {
    this. /*update: [exact=Class4|powerset={N}{O}]*/ field =
        invocation
            .
            /*[exact=JSInvocationMirror|powerset={N}{O}]*/
            positionalArguments
            .
            /*[exact=JSUnmodifiableArray|powerset={I}{U}]*/
            first;
    return null;
  }

  /*member: Class4.method:[null|powerset={null}]*/
  method() {
    dynamic a = this;
    a. /*update: [exact=Class4|powerset={N}{O}]*/ missingSetter =
        /*[null|powerset={null}]*/ (
          /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ parameter,
        ) {};
    a. /*invoke: [exact=Class4|powerset={N}{O}]*/ field(0);
  }
}

/*member: closureThroughMissingSetter:[null|powerset={null}]*/
closureThroughMissingSetter() =>
    Class4(). /*invoke: [exact=Class4|powerset={N}{O}]*/ method();
