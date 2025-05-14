// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: namedLocalFunctionInvoke:[exact=JSUInt31|powerset=0]*/
namedLocalFunctionInvoke() {
  /*[exact=JSUInt31|powerset=0]*/
  local() => 0;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of an unnamed local function.
////////////////////////////////////////////////////////////////////////////////

/*member: unnamedLocalFunctionInvoke:[subclass=JSInt|powerset=0]*/
unnamedLocalFunctionInvoke() {
  var local = /*[exact=JSUInt31|powerset=0]*/ () => 0;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Access of a named local function.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionGet:[subclass=Closure|powerset=0]*/
namedLocalFunctionGet() {
  /*[exact=JSUInt31|powerset=0]*/
  local() => 0;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function recursively.
////////////////////////////////////////////////////////////////////////////////

/*member: recursiveLocalFunction:[subclass=Closure|powerset=0]*/
recursiveLocalFunction() {
  /*[subclass=Closure|powerset=0]*/
  local() => local;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with a missing argument.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionInvokeMissingArgument:[null|subclass=Object|powerset=1]*/
@pragma('dart2js:disableFinal')
namedLocalFunctionInvokeMissingArgument() {
  /*[exact=JSUInt31|powerset=0]*/
  local(/*[empty|powerset=0]*/ x) => 0;
  dynamic b = local;
  return b();
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with an extra argument.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionInvokeExtraArgument:[null|subclass=Object|powerset=1]*/
@pragma('dart2js:disableFinal')
namedLocalFunctionInvokeExtraArgument() {
  /*[exact=JSUInt31|powerset=0]*/
  local() => 0;
  dynamic b = local;
  return b(0);
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with an extra named argument.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionInvokeExtraNamedArgument:[null|subclass=Object|powerset=1]*/
@pragma('dart2js:disableFinal')
namedLocalFunctionInvokeExtraNamedArgument() {
  /*[exact=JSUInt31|powerset=0]*/
  local() => 0;
  dynamic b = local;
  return b(a: 0);
}

////////////////////////////////////////////////////////////////////////////////
// Implicit .call on a local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: closureToString:[exact=JSString|powerset=0]*/
closureToString() {
  var local = /*[null|powerset=1]*/ () {};
  local();
  return local. /*invoke: [subclass=Closure|powerset=0]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
// Explicit .call on a local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: closureCallToString:[exact=JSString|powerset=0]*/
closureCallToString() {
  var local = /*[null|powerset=1]*/ () {};
  local.call();
  return local. /*invoke: [subclass=Closure|powerset=0]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
// Operator == on the result of a parameter invocation.
////////////////////////////////////////////////////////////////////////////////

/*member: _callCompare:[subclass=Closure|powerset=0]*/
_callCompare(int /*[subclass=Closure|powerset=0]*/ compare({a, b})) {
  compare(a: 0, b: 1) /*invoke: [subclass=JSInt|powerset=0]*/ == 0;
  return compare;
}

/*member: callCompare:[null|powerset=1]*/
callCompare() {
  _callCompare(
    /*[subclass=JSInt|powerset=0]*/
    ({/*[exact=JSUInt31|powerset=0]*/ a, /*[exact=JSUInt31|powerset=0]*/ b}) =>
        a /*invoke: [exact=JSUInt31|powerset=0]*/ - b,
  );
}

////////////////////////////////////////////////////////////////////////////////
// Invocation on the result of a parameter invocation.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.method1:[null|powerset=1]*/
  method1() {}
}

/*member: _callClosure:[subclass=Closure|powerset=0]*/
_callClosure(/*[subclass=Closure|powerset=0]*/ f({c})) {
  f(c: Class1()).method1();
  return f;
}

/*member: callClosure:[null|powerset=1]*/
callClosure() {
  _callClosure(
    /*[exact=Class1|powerset=0]*/ ({/*[exact=Class1|powerset=0]*/ c}) => c,
  );
}
