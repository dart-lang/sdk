// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  missingGetter();
  missingMethod();
  closureThroughMissingMethod();
  closureThroughMissingSetter();
}

////////////////////////////////////////////////////////////////////////////////
// Access missing getter.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1]*/
class Class1 {
  /*member: Class1.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(
          Invocation
              /*spec.[null|subclass=Object]*/
              /*prod.[null|exact=JSInvocationMirror]*/
              _) =>
      42;

  /*member: Class1.method:[exact=JSUInt31]*/
  method() {
    dynamic a = this;
    return a. /*[exact=Class1]*/ missingGetter;
  }
}

/*member: missingGetter:[exact=JSUInt31]*/
missingGetter() => new Class1(). /*invoke: [exact=Class1]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Invoke missing method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2]*/
class Class2 {
  /*member: Class2.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(
          Invocation
              /*spec.[null|subclass=Object]*/
              /*prod.[null|exact=JSInvocationMirror]*/
              _) =>
      42;

  /*member: Class2.method:[exact=JSUInt31]*/
  method() {
    dynamic a = this;
    return a. /*invoke: [exact=Class2]*/ missingMethod();
  }
}

/*member: missingMethod:[exact=JSUInt31]*/
missingMethod() => new Class2(). /*invoke: [exact=Class2]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Pass closure to missing method.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3]*/
class Class3 {
  /*member: Class3.noSuchMethod:[null|subclass=Object]*/
  noSuchMethod(
      Invocation
          /*spec.[null|subclass=Object]*/
          /*prod.[null|exact=JSInvocationMirror]*/
          invocation) {
    return invocation
        .
        /*[null|exact=JSInvocationMirror]*/
        positionalArguments
        .
        /*[exact=JSUnmodifiableArray]*/
        first;
  }

  /*member: Class3.method:[null|subclass=Object]*/
  method() {
    dynamic a = this;
    return a. /*invoke: [exact=Class3]*/ missingMethod(
        /*[null]*/ (/*[null|subclass=Object]*/ parameter) {})(0);
  }
}

/*member: closureThroughMissingMethod:[null|subclass=Object]*/
closureThroughMissingMethod() =>
    new Class3(). /*invoke: [exact=Class3]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Pass closure to missing setter.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4]*/
class Class4 {
  /*member: Class4.field:[null|subclass=Object]*/
  var field;

  /*member: Class4.noSuchMethod:[null]*/
  noSuchMethod(
      Invocation
          /*spec.[null|subclass=Object]*/
          /*prod.[null|exact=JSInvocationMirror]*/
          invocation) {
    this. /*update: [exact=Class4]*/ field = invocation
        .
        /*[null|exact=JSInvocationMirror]*/
        positionalArguments
        .
        /*[exact=JSUnmodifiableArray]*/
        first;
    return null;
  }

  /*member: Class4.method:[null]*/
  method() {
    dynamic a = this;
    a. /*update: [exact=Class4]*/ missingSetter =
        /*[null]*/ (/*[null|subclass=Object]*/ parameter) {};
    a. /*invoke: [exact=Class4]*/ field(0);
  }
}

/*member: closureThroughMissingSetter:[null]*/
closureThroughMissingSetter() =>
    new Class4(). /*invoke: [exact=Class4]*/ method();
