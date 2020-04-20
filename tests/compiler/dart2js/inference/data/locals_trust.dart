// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  trustLocals();
  trustFunctions();
  inferFromFunctions();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we trust the explicit type of a local.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustLocals:[exact=JSBool]*/ _trustLocals(
    int Function(int) /*[null|subclass=Closure]*/ f) {
  int c = f(0);
  return c /*invoke: [null|subclass=JSInt]*/ == 0;
}

/*member: trustLocals:[null]*/
trustLocals() {
  _trustLocals(/*[exact=JSUInt31]*/ (/*[exact=JSUInt31]*/ o) => o);
  _trustLocals(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test that we infer the type of a dynamic local from the type of the function.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustFunctions:[exact=JSBool]*/
_trustFunctions(int Function(int) /*[null|subclass=Closure]*/ f) {
  dynamic c = f(0);
  c = f(0);
  return c /*invoke: [null|subclass=JSInt]*/ == 0;
}

/*member: trustFunctions:[null]*/
trustFunctions() {
  _trustFunctions(/*[exact=JSUInt31]*/ (/*[exact=JSUInt31]*/ o) => o);
  _trustFunctions(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test that we infer the type of a 'var' local from the type of the function.
////////////////////////////////////////////////////////////////////////////////

/*member: _inferFromFunctions:[exact=JSBool]*/
_inferFromFunctions(int Function(int) /*[null|subclass=Closure]*/ f) {
  var c = f(0);
  return c /*invoke: [null|subclass=JSInt]*/ == 0;
}

/*member: inferFromFunctions:[null]*/
inferFromFunctions() {
  _inferFromFunctions(/*[exact=JSUInt31]*/ (/*[exact=JSUInt31]*/ o) => o);
  _inferFromFunctions(null);
}
