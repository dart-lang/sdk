// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
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

/*member: namedLocalFunctionInvoke:[exact=JSUInt31]*/
namedLocalFunctionInvoke() {
  /*[exact=JSUInt31]*/ local() => 0;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of an unnamed local function.
////////////////////////////////////////////////////////////////////////////////

/*member: unnamedLocalFunctionInvoke:[null|subclass=JSInt]*/
unnamedLocalFunctionInvoke() {
  var local = /*[exact=JSUInt31]*/ () => 0;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Access of a named local function.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionGet:[subclass=Closure]*/
namedLocalFunctionGet() {
  /*[exact=JSUInt31]*/ local() => 0;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function recursively.
////////////////////////////////////////////////////////////////////////////////

/*member: recursiveLocalFunction:[subclass=Closure]*/
recursiveLocalFunction() {
  /*[subclass=Closure]*/ local() => local;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with a missing argument.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionInvokeMissingArgument:[null|subclass=Object]*/
@pragma('dart2js:disableFinal')
namedLocalFunctionInvokeMissingArgument() {
  /*[exact=JSUInt31]*/ local(/*[empty]*/ x) => 0;
  dynamic b = local;
  return b();
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with an extra argument.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionInvokeExtraArgument:[null|subclass=Object]*/
@pragma('dart2js:disableFinal')
namedLocalFunctionInvokeExtraArgument() {
  /*[exact=JSUInt31]*/ local() => 0;
  dynamic b = local;
  return b(0);
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with an extra named argument.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionInvokeExtraNamedArgument:[null|subclass=Object]*/
@pragma('dart2js:disableFinal')
namedLocalFunctionInvokeExtraNamedArgument() {
  /*[exact=JSUInt31]*/ local() => 0;
  dynamic b = local;
  return b(a: 0);
}

////////////////////////////////////////////////////////////////////////////////
// Implicit .call on a local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: closureToString:[exact=JSString]*/
closureToString() {
  var local = /*[null]*/ () {};
  local();
  return local. /*invoke: [subclass=Closure]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
// Explicit .call on a local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: closureCallToString:[exact=JSString]*/
closureCallToString() {
  var local = /*[null]*/ () {};
  local.call();
  return local. /*invoke: [subclass=Closure]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
// Operator == on the result of a parameter invocation.
////////////////////////////////////////////////////////////////////////////////

/*member: _callCompare:[subclass=Closure]*/
_callCompare(int /*[subclass=Closure]*/ compare({a, b})) {
  compare(a: 0, b: 1) /*invoke: [null|subclass=JSInt]*/ == 0;
  return compare;
}

/*member: callCompare:[null]*/
callCompare() {
  _callCompare(/*[subclass=JSInt]*/
      ({/*[exact=JSUInt31]*/ a, /*[exact=JSUInt31]*/ b}) =>
          a /*invoke: [exact=JSUInt31]*/ - b);
}

////////////////////////////////////////////////////////////////////////////////
// Invocation on the result of a parameter invocation.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1]*/
class Class1 {
  /*member: Class1.method1:[null]*/
  method1() {}
}

/*member: _callClosure:[subclass=Closure]*/
_callClosure(/*[subclass=Closure]*/ f({c})) {
  f(c: new Class1()).method1();
  return f;
}

/*member: callClosure:[null]*/
callClosure() {
  _callClosure(/*[exact=Class1]*/ ({/*[exact=Class1]*/ c}) => c);
}
