// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  missingSuperMethodInvoke();
  superMethodInvokeMissingArgument();
  superMethodInvokeExtraArgument();
  superMethodInvokeExtraNamedArgument();
  missingSuperMethodInvokeNoSuchMethod();
  abstractSuperMethodInvokeNoSuchMethod();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of missing super method.
////////////////////////////////////////////////////////////////////////////////

/*element: Super4.:[exact=Super4]*/
class Super4 {}

/*element: Sub4.:[exact=Sub4]*/
class Sub4 extends Super4 {
  /*element: Sub4.method:[empty]*/
  method() {
    // ignore: UNDEFINED_SUPER_METHOD
    var a = super.method();
    return a. /*invoke: [empty]*/ abs();
  }
}

/*element: missingSuperMethodInvoke:[null]*/
missingSuperMethodInvoke() {
  new Sub4(). /*invoke: [exact=Sub4]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super method with missing argument.
////////////////////////////////////////////////////////////////////////////////

/*element: Super5.:[exact=Super5]*/
class Super5 {
  /*element: Super5.method1:[exact=JSUInt31]*/
  method1(/*[exact=JSUInt31]*/ x) => 42;
}

/*element: Sub5.:[exact=Sub5]*/
class Sub5 extends Super5 {
  /*element: Sub5.method2:[empty]*/
  method2() {
    super.method1(0);
    // ignore: NOT_ENOUGH_REQUIRED_ARGUMENTS
    var a = super.method1();
    return a. /*invoke: [empty]*/ abs();
  }
}

/*element: superMethodInvokeMissingArgument:[null]*/
superMethodInvokeMissingArgument() {
  new Sub5(). /*invoke: [exact=Sub5]*/ method2();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super method with extra argument.
////////////////////////////////////////////////////////////////////////////////

/*element: Super6.:[exact=Super6]*/
class Super6 {
  /*element: Super6.method:[exact=JSUInt31]*/
  method() => 42;
}

/*element: Sub6.:[exact=Sub6]*/
class Sub6 extends Super6 {
  /*element: Sub6.method:[empty]*/
  method() {
    // ignore: EXTRA_POSITIONAL_ARGUMENTS
    var a = super.method(0);
    return a. /*invoke: [empty]*/ abs();
  }
}

/*element: superMethodInvokeExtraArgument:[null]*/
superMethodInvokeExtraArgument() {
  new Sub6(). /*invoke: [exact=Sub6]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super method with extra named argument.
////////////////////////////////////////////////////////////////////////////////

/*element: Super7.:[exact=Super7]*/
class Super7 {
  /*element: Super7.method:[exact=JSUInt31]*/
  method() => 42;
}

/*element: Sub7.:[exact=Sub7]*/
class Sub7 extends Super7 {
  /*element: Sub7.method:[empty]*/
  method() {
    // ignore: UNDEFINED_NAMED_PARAMETER
    var a = super.method(a: 0);
    return a. /*invoke: [empty]*/ abs();
  }
}

/*element: superMethodInvokeExtraNamedArgument:[null]*/
superMethodInvokeExtraNamedArgument() {
  new Sub7(). /*invoke: [exact=Sub7]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super method caught by noSuchMethod.
////////////////////////////////////////////////////////////////////////////////

/*element: Super8.:[exact=Super8]*/
class Super8 {
  /*element: Super8.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(/*[null|subclass=Object]*/ _) => 42;
}

/*element: Sub8.:[exact=Sub8]*/
class Sub8 extends Super8 {
  /*element: Sub8.method:[subclass=JSPositiveInt]*/
  method() {
    // ignore: UNDEFINED_SUPER_METHOD
    var a = super.method();
    return a. /*invoke: [exact=JSUInt31]*/ abs();
  }
}

/*element: missingSuperMethodInvokeNoSuchMethod:[null]*/
missingSuperMethodInvokeNoSuchMethod() {
  new Sub8(). /*invoke: [exact=Sub8]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of abstract super method caught by noSuchMethod.
////////////////////////////////////////////////////////////////////////////////

/*element: Super9.:[exact=Super9]*/
class Super9 {
  method();

  /*element: Super9.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(/*[null|subclass=Object]*/ im) => 42;
}

/*element: Sub9.:[exact=Sub9]*/
class Sub9 extends Super9 {
  /*element: Sub9.method:[exact=JSUInt31]*/
  // ignore: abstract_super_member_reference
  method() => super.method();
}

/*element: abstractSuperMethodInvokeNoSuchMethod:[null]*/
abstractSuperMethodInvokeNoSuchMethod() {
  new Sub9(). /*invoke: [exact=Sub9]*/ method();
}
