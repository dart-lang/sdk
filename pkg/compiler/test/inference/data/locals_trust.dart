// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  trustLocals();
  trustFunctions();
  inferFromFunctions();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we trust the explicit type of a local.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustLocals:[exact=JSBool|powerset=0]*/
_trustLocals(int Function(int)? /*[null|subclass=Closure|powerset=1]*/ f) {
  int c = f!(0);
  return c /*invoke: [subclass=JSInt|powerset=0]*/ == 0;
}

/*member: trustLocals:[null|powerset=1]*/
trustLocals() {
  _trustLocals(
    /*[exact=JSUInt31|powerset=0]*/ (/*[exact=JSUInt31|powerset=0]*/ o) => o,
  );
  _trustLocals(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test that we infer the type of a dynamic local from the type of the function.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustFunctions:[exact=JSBool|powerset=0]*/
_trustFunctions(int Function(int)? /*[null|subclass=Closure|powerset=1]*/ f) {
  dynamic c = f!(0);
  c = f(0);
  return c /*invoke: [subclass=JSInt|powerset=0]*/ == 0;
}

/*member: trustFunctions:[null|powerset=1]*/
trustFunctions() {
  _trustFunctions(
    /*[exact=JSUInt31|powerset=0]*/ (/*[exact=JSUInt31|powerset=0]*/ o) => o,
  );
  _trustFunctions(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test that we infer the type of a 'var' local from the type of the function.
////////////////////////////////////////////////////////////////////////////////

/*member: _inferFromFunctions:[exact=JSBool|powerset=0]*/
_inferFromFunctions(
  int Function(int)? /*[null|subclass=Closure|powerset=1]*/ f,
) {
  var c = f!(0);
  return c /*invoke: [subclass=JSInt|powerset=0]*/ == 0;
}

/*member: inferFromFunctions:[null|powerset=1]*/
inferFromFunctions() {
  _inferFromFunctions(
    /*[exact=JSUInt31|powerset=0]*/ (/*[exact=JSUInt31|powerset=0]*/ o) => o,
  );
  _inferFromFunctions(null);
}
