// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  unconditionalThrow();
  conditionalThrow();
  conditionalThrowReturn();
}

////////////////////////////////////////////////////////////////////////////////
/// Method that throws unconditionally.
////////////////////////////////////////////////////////////////////////////////

/*element: unconditionalThrow:[empty]*/
unconditionalThrow() => throw 'foo';

////////////////////////////////////////////////////////////////////////////////
/// Method that throws conditionally.
////////////////////////////////////////////////////////////////////////////////

/*element: _conditionalThrow:[null]*/
_conditionalThrow(/*[exact=JSBool]*/ o) {
  if (o) throw 'foo';
}

/*element: conditionalThrow:[null]*/
conditionalThrow() {
  _conditionalThrow(true);
  _conditionalThrow(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Method that throws conditionally and return 0.
////////////////////////////////////////////////////////////////////////////////

/*element: _conditionalThrowReturn:[exact=JSUInt31]*/
_conditionalThrowReturn(/*[exact=JSBool]*/ o) {
  if (o) throw 'foo';
  return 0;
}

/*element: conditionalThrowReturn:[null]*/
conditionalThrowReturn() {
  _conditionalThrowReturn(true);
  _conditionalThrowReturn(false);
}
