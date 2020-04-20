// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  unconditionalThrow();
  conditionalThrow();
  conditionalThrowReturn();
  unconditionalRethrow();
}

////////////////////////////////////////////////////////////////////////////////
/// Method that throws unconditionally.
////////////////////////////////////////////////////////////////////////////////

/*member: unconditionalThrow:[empty]*/
unconditionalThrow() => throw 'foo';

////////////////////////////////////////////////////////////////////////////////
/// Method that throws conditionally.
////////////////////////////////////////////////////////////////////////////////

/*member: _conditionalThrow:[null]*/
_conditionalThrow(/*[exact=JSBool]*/ o) {
  if (o) throw 'foo';
}

/*member: conditionalThrow:[null]*/
conditionalThrow() {
  _conditionalThrow(true);
  _conditionalThrow(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Method that throws conditionally and return 0.
////////////////////////////////////////////////////////////////////////////////

/*member: _conditionalThrowReturn:[exact=JSUInt31]*/
_conditionalThrowReturn(/*[exact=JSBool]*/ o) {
  if (o) throw 'foo';
  return 0;
}

/*member: conditionalThrowReturn:[null]*/
conditionalThrowReturn() {
  _conditionalThrowReturn(true);
  _conditionalThrowReturn(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Method that rethrows unconditionally.
////////////////////////////////////////////////////////////////////////////////

/*member: unconditionalRethrow:[null]*/
unconditionalRethrow() {
  try {
    throw 'foo';
  } catch (e) {
    rethrow;
  }
}
