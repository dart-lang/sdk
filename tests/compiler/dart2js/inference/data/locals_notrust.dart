// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  dontTrustLocals();
  dontTrustFunctions();
  inferFromFunctions();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we don't trust the explicit type of a local, unless we are in
// strong mode.
////////////////////////////////////////////////////////////////////////////////

/*element: _dontTrustLocals:[exact=JSBool]*/ _dontTrustLocals(
    int Function(int) /*[null|subclass=Closure]*/ f) {
  int c = f(0);
  return c /*strong.invoke: [null|subclass=JSInt]*/ == 0;
}

/*element: dontTrustLocals:[null]*/
dontTrustLocals() {
  _dontTrustLocals(/*[exact=JSUInt31]*/ (/*[exact=JSUInt31]*/ o) => o);
  _dontTrustLocals(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test that we don't infer the type of a dynamic local from the type of the
// function.
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

////////////////////////////////////////////////////////////////////////////////
// Test that we don't infer the type of a 'var' local from the type of the
// function, unless we are in strong mode.
////////////////////////////////////////////////////////////////////////////////

/*element: _inferFromFunctions:[exact=JSBool]*/
_inferFromFunctions(int Function(int) /*[null|subclass=Closure]*/ f) {
  var c = f(0);
  return c /*strong.invoke: [null|subclass=JSInt]*/ == 0;
}

/*element: inferFromFunctions:[null]*/
inferFromFunctions() {
  _inferFromFunctions(/*[exact=JSUInt31]*/ (/*[exact=JSUInt31]*/ o) => o);
  _inferFromFunctions(null);
}
