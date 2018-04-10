// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  trustLocals();
  dontTrustFunctions();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we trust the explicit type of a local with
// --trust-type-annotations.
////////////////////////////////////////////////////////////////////////////////

/*element: _trustLocals:[exact=JSBool]*/ _trustLocals(
    int Function(int) /*[null|subclass=Closure]*/ f) {
  int c = f(0);
  return c /*invoke: [null|subclass=JSInt]*/ == 0;
}

/*element: trustLocals:[null]*/
trustLocals() {
  _trustLocals(/*[exact=JSUInt31]*/ (/*[exact=JSUInt31]*/ o) => o);
  _trustLocals(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test that we don't trust the type of a function even with
// --trust-type-annotations.
////////////////////////////////////////////////////////////////////////////////

/*element: _dontTrustFunctions:[exact=JSBool]*/
_dontTrustFunctions(int Function(int) /*[null|subclass=Closure]*/ f) {
  dynamic c = f(0);
  return c == 0;
}

/*element: dontTrustFunctions:[null]*/
dontTrustFunctions() {
  _dontTrustFunctions(/*[exact=JSUInt31]*/ (/*[exact=JSUInt31]*/ o) => o);
  _dontTrustFunctions(null);
}
