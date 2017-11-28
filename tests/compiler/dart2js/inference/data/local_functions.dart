// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  namedLocalFunctionInvoke();
  unnamedLocalFunctionInvoke();
  namedLocalFunctionGet();
  recursiveLocalFunction();
  namedLocalFunctionInvokeMissingArgument();
  namedLocalFunctionInvokeExtraArgument();
  namedLocalFunctionInvokeExtraNamedArgument();
  closureToString();
  closureCallToString();
  callCompare();
  callClosure();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of a named local function.
////////////////////////////////////////////////////////////////////////////////

/*element: namedLocalFunctionInvoke:[exact=JSUInt31]*/
namedLocalFunctionInvoke() {
  /*[exact=JSUInt31]*/ local() => 0;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of an unnamed local function.
////////////////////////////////////////////////////////////////////////////////

/*element: unnamedLocalFunctionInvoke:[null|subclass=Object]*/
unnamedLocalFunctionInvoke() {
  var local = /*[exact=JSUInt31]*/ () => 0;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Access of a named local function.
////////////////////////////////////////////////////////////////////////////////

/*element: namedLocalFunctionGet:[subclass=Closure]*/
namedLocalFunctionGet() {
  /*[exact=JSUInt31]*/ local() => 0;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function recursively.
////////////////////////////////////////////////////////////////////////////////

/*element: recursiveLocalFunction:[subclass=Closure]*/
recursiveLocalFunction() {
  /*[subclass=Closure]*/ local() => local;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with a missing argument.
////////////////////////////////////////////////////////////////////////////////

/*element: namedLocalFunctionInvokeMissingArgument:[null|subclass=Object]*/
namedLocalFunctionInvokeMissingArgument() {
  /*[exact=JSUInt31]*/ local(/*[empty]*/ x) => 0;
  // ignore: NOT_ENOUGH_REQUIRED_ARGUMENTS
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with an extra argument.
////////////////////////////////////////////////////////////////////////////////

/*element: namedLocalFunctionInvokeExtraArgument:[null|subclass=Object]*/
namedLocalFunctionInvokeExtraArgument() {
  /*[exact=JSUInt31]*/ local() => 0;
  // ignore: EXTRA_POSITIONAL_ARGUMENTS
  return local(0);
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with an extra named argument.
////////////////////////////////////////////////////////////////////////////////

/*element: namedLocalFunctionInvokeExtraNamedArgument:[null|subclass=Object]*/
namedLocalFunctionInvokeExtraNamedArgument() {
  /*[exact=JSUInt31]*/ local() => 0;
  // ignore: UNDEFINED_NAMED_PARAMETER
  return local(a: 0);
}

////////////////////////////////////////////////////////////////////////////////
// Implicit .call on a local variable.
////////////////////////////////////////////////////////////////////////////////

/*element: closureToString:[exact=JSString]*/
closureToString() {
  var local = /*[null]*/ () {};
  local();
  return local. /*invoke: [subclass=Closure]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
// Explicit .call on a local variable.
////////////////////////////////////////////////////////////////////////////////

/*element: closureCallToString:[exact=JSString]*/
closureCallToString() {
  var local = /*[null]*/ () {};
  local.call();
  return local. /*invoke: [subclass=Closure]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
// Operator == on the result of a parameter invocation.
////////////////////////////////////////////////////////////////////////////////

/*element: _callCompare:[exact=callCompare_closure]*/
_callCompare(int /*[subclass=Closure]*/ compare({a, b})) {
  compare(a: 0, b: 1) == 0;
  return compare;
}

/*element: callCompare:[null]*/
callCompare() {
  _callCompare(/*[subclass=JSInt]*/
      ({/*[exact=JSUInt31]*/ a, /*[exact=JSUInt31]*/ b}) =>
          a /*invoke: [exact=JSUInt31]*/ - b);
}

////////////////////////////////////////////////////////////////////////////////
// Invocation on the result of a parameter invocation.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.method1:[null]*/
  method1() {}
}

/*element: _callClosure:[exact=callClosure_closure]*/
_callClosure(/*[subclass=Closure]*/ f({c})) {
  f(c: new Class1()).method1();
  return f;
}

/*element: callClosure:[null]*/
callClosure() {
  _callClosure(/*[exact=Class1]*/ ({/*[exact=Class1]*/ c}) => c);
}
