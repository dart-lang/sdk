// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  trustLocals();
  trustFunctions();
  inferFromFunctions();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we trust the explicit type of a local.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustLocals:[exact=JSBool|powerset={I}]*/
_trustLocals(
  int Function(int)? /*[null|subclass=Closure|powerset={null}{N}]*/ f,
) {
  int c = f!(0);
  return c /*invoke: [subclass=JSInt|powerset={I}]*/ == 0;
}

/*member: trustLocals:[null|powerset={null}]*/
trustLocals() {
  _trustLocals(
    /*[exact=JSUInt31|powerset={I}]*/ (/*[exact=JSUInt31|powerset={I}]*/ o) =>
        o,
  );
  _trustLocals(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test that we infer the type of a dynamic local from the type of the function.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustFunctions:[exact=JSBool|powerset={I}]*/
_trustFunctions(
  int Function(int)? /*[null|subclass=Closure|powerset={null}{N}]*/ f,
) {
  dynamic c = f!(0);
  c = f(0);
  return c /*invoke: [subclass=JSInt|powerset={I}]*/ == 0;
}

/*member: trustFunctions:[null|powerset={null}]*/
trustFunctions() {
  _trustFunctions(
    /*[exact=JSUInt31|powerset={I}]*/ (/*[exact=JSUInt31|powerset={I}]*/ o) =>
        o,
  );
  _trustFunctions(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test that we infer the type of a 'var' local from the type of the function.
////////////////////////////////////////////////////////////////////////////////

/*member: _inferFromFunctions:[exact=JSBool|powerset={I}]*/
_inferFromFunctions(
  int Function(int)? /*[null|subclass=Closure|powerset={null}{N}]*/ f,
) {
  var c = f!(0);
  return c /*invoke: [subclass=JSInt|powerset={I}]*/ == 0;
}

/*member: inferFromFunctions:[null|powerset={null}]*/
inferFromFunctions() {
  _inferFromFunctions(
    /*[exact=JSUInt31|powerset={I}]*/ (/*[exact=JSUInt31|powerset={I}]*/ o) =>
        o,
  );
  _inferFromFunctions(null);
}
