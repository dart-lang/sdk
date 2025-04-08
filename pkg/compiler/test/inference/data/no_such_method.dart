// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  missingGetter();
  missingMethod();
  closureThroughMissingMethod();
  closureThroughMissingSetter();
}

////////////////////////////////////////////////////////////////////////////////
// Access missing getter.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.noSuchMethod:[exact=JSUInt31|powerset=0]*/
  noSuchMethod(
    Invocation
    /*spec.[null|subclass=Object|powerset=1]*/
    /*prod.[exact=JSInvocationMirror|powerset=0]*/
    _,
  ) => 42;

  /*member: Class1.method:[exact=JSUInt31|powerset=0]*/
  method() {
    dynamic a = this;
    return a. /*[exact=Class1|powerset=0]*/ missingGetter;
  }
}

/*member: missingGetter:[exact=JSUInt31|powerset=0]*/
missingGetter() => Class1(). /*invoke: [exact=Class1|powerset=0]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Invoke missing method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset=0]*/
class Class2 {
  /*member: Class2.noSuchMethod:[exact=JSUInt31|powerset=0]*/
  noSuchMethod(
    Invocation
    /*spec.[null|subclass=Object|powerset=1]*/
    /*prod.[exact=JSInvocationMirror|powerset=0]*/
    _,
  ) => 42;

  /*member: Class2.method:[exact=JSUInt31|powerset=0]*/
  method() {
    dynamic a = this;
    return a. /*invoke: [exact=Class2|powerset=0]*/ missingMethod();
  }
}

/*member: missingMethod:[exact=JSUInt31|powerset=0]*/
missingMethod() => Class2(). /*invoke: [exact=Class2|powerset=0]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Pass closure to missing method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset=0]*/
class Class3 {
  /*member: Class3.noSuchMethod:[null|subclass=Object|powerset=1]*/
  noSuchMethod(
    Invocation
    /*spec.[null|subclass=Object|powerset=1]*/
    /*prod.[exact=JSInvocationMirror|powerset=0]*/
    invocation,
  ) {
    return invocation
        .
        /*[exact=JSInvocationMirror|powerset=0]*/
        positionalArguments
        .
        /*[exact=JSUnmodifiableArray|powerset=0]*/
        first;
  }

  /*member: Class3.method:[null|subclass=Object|powerset=1]*/
  method() {
    dynamic a = this;
    return a. /*invoke: [exact=Class3|powerset=0]*/ missingMethod(
      /*[null|powerset=1]*/ (
        /*[null|subclass=Object|powerset=1]*/ parameter,
      ) {},
    )(0);
  }
}

/*member: closureThroughMissingMethod:[null|subclass=Object|powerset=1]*/
closureThroughMissingMethod() =>
    Class3(). /*invoke: [exact=Class3|powerset=0]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Pass closure to missing setter.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset=0]*/
class Class4 {
  /*member: Class4.field:[null|subclass=Object|powerset=1]*/
  var field;

  /*member: Class4.noSuchMethod:[null|powerset=1]*/
  noSuchMethod(
    Invocation
    /*spec.[null|subclass=Object|powerset=1]*/
    /*prod.[exact=JSInvocationMirror|powerset=0]*/
    invocation,
  ) {
    this. /*update: [exact=Class4|powerset=0]*/ field =
        invocation
            .
            /*[exact=JSInvocationMirror|powerset=0]*/
            positionalArguments
            .
            /*[exact=JSUnmodifiableArray|powerset=0]*/
            first;
    return null;
  }

  /*member: Class4.method:[null|powerset=1]*/
  method() {
    dynamic a = this;
    a. /*update: [exact=Class4|powerset=0]*/ missingSetter =
        /*[null|powerset=1]*/ (
          /*[null|subclass=Object|powerset=1]*/ parameter,
        ) {};
    a. /*invoke: [exact=Class4|powerset=0]*/ field(0);
  }
}

/*member: closureThroughMissingSetter:[null|powerset=1]*/
closureThroughMissingSetter() =>
    Class4(). /*invoke: [exact=Class4|powerset=0]*/ method();
