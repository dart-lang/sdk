// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: namedLocalFunctionInvoke:[exact=JSUInt31|powerset={I}{O}{N}]*/
namedLocalFunctionInvoke() {
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  local() => 0;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of an unnamed local function.
////////////////////////////////////////////////////////////////////////////////

/*member: unnamedLocalFunctionInvoke:[subclass=JSInt|powerset={I}{O}{N}]*/
unnamedLocalFunctionInvoke() {
  var local = /*[exact=JSUInt31|powerset={I}{O}{N}]*/ () => 0;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Access of a named local function.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionGet:[subclass=Closure|powerset={N}{O}{N}]*/
namedLocalFunctionGet() {
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  local() => 0;
  return local;
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function recursively.
////////////////////////////////////////////////////////////////////////////////

/*member: recursiveLocalFunction:[subclass=Closure|powerset={N}{O}{N}]*/
recursiveLocalFunction() {
  /*[subclass=Closure|powerset={N}{O}{N}]*/
  local() => local;
  return local();
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with a missing argument.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionInvokeMissingArgument:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
@pragma('dart2js:disableFinal')
namedLocalFunctionInvokeMissingArgument() {
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  local(/*[empty|powerset=empty]*/ x) => 0;
  dynamic b = local;
  return b();
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with an extra argument.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionInvokeExtraArgument:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
@pragma('dart2js:disableFinal')
namedLocalFunctionInvokeExtraArgument() {
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  local() => 0;
  dynamic b = local;
  return b(0);
}

////////////////////////////////////////////////////////////////////////////////
// Call a named local function with an extra named argument.
////////////////////////////////////////////////////////////////////////////////

/*member: namedLocalFunctionInvokeExtraNamedArgument:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
@pragma('dart2js:disableFinal')
namedLocalFunctionInvokeExtraNamedArgument() {
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  local() => 0;
  dynamic b = local;
  return b(a: 0);
}

////////////////////////////////////////////////////////////////////////////////
// Implicit .call on a local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: closureToString:[exact=JSString|powerset={I}{O}{I}]*/
closureToString() {
  var local = /*[null|powerset={null}]*/ () {};
  local();
  return local. /*invoke: [subclass=Closure|powerset={N}{O}{N}]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
// Explicit .call on a local variable.
////////////////////////////////////////////////////////////////////////////////

/*member: closureCallToString:[exact=JSString|powerset={I}{O}{I}]*/
closureCallToString() {
  var local = /*[null|powerset={null}]*/ () {};
  local.call();
  return local. /*invoke: [subclass=Closure|powerset={N}{O}{N}]*/ toString();
}

////////////////////////////////////////////////////////////////////////////////
// Operator == on the result of a parameter invocation.
////////////////////////////////////////////////////////////////////////////////

/*member: _callCompare:[subclass=Closure|powerset={N}{O}{N}]*/
_callCompare(int /*[subclass=Closure|powerset={N}{O}{N}]*/ compare({a, b})) {
  compare(a: 0, b: 1) /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ == 0;
  return compare;
}

/*member: callCompare:[null|powerset={null}]*/
callCompare() {
  _callCompare(
    /*[subclass=JSInt|powerset={I}{O}{N}]*/
    ({
      /*[exact=JSUInt31|powerset={I}{O}{N}]*/ a,
      /*[exact=JSUInt31|powerset={I}{O}{N}]*/ b,
    }) => a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ - b,
  );
}

////////////////////////////////////////////////////////////////////////////////
// Invocation on the result of a parameter invocation.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  /*member: Class1.method1:[null|powerset={null}]*/
  method1() {}
}

/*member: _callClosure:[subclass=Closure|powerset={N}{O}{N}]*/
_callClosure(/*[subclass=Closure|powerset={N}{O}{N}]*/ f({c})) {
  f(c: Class1()).method1();
  return f;
}

/*member: callClosure:[null|powerset={null}]*/
callClosure() {
  _callClosure(
    /*[exact=Class1|powerset={N}{O}{N}]*/ ({
      /*[exact=Class1|powerset={N}{O}{N}]*/ c,
    }) => c,
  );
}
