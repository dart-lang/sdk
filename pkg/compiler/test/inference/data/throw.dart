// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  unconditionalThrow();
  conditionalThrow();
  conditionalThrowReturn();
  unconditionalRethrow();
}

////////////////////////////////////////////////////////////////////////////////
/// Method that throws unconditionally.
////////////////////////////////////////////////////////////////////////////////

/*member: unconditionalThrow:[empty|powerset=0]*/
unconditionalThrow() => throw 'foo';

////////////////////////////////////////////////////////////////////////////////
/// Method that throws conditionally.
////////////////////////////////////////////////////////////////////////////////

/*member: _conditionalThrow:[null|powerset=1]*/
_conditionalThrow(/*[exact=JSBool|powerset=0]*/ o) {
  if (o) throw 'foo';
}

/*member: conditionalThrow:[null|powerset=1]*/
conditionalThrow() {
  _conditionalThrow(true);
  _conditionalThrow(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Method that throws conditionally and return 0.
////////////////////////////////////////////////////////////////////////////////

/*member: _conditionalThrowReturn:[exact=JSUInt31|powerset=0]*/
_conditionalThrowReturn(/*[exact=JSBool|powerset=0]*/ o) {
  if (o) throw 'foo';
  return 0;
}

/*member: conditionalThrowReturn:[null|powerset=1]*/
conditionalThrowReturn() {
  _conditionalThrowReturn(true);
  _conditionalThrowReturn(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Method that rethrows unconditionally.
////////////////////////////////////////////////////////////////////////////////

/*member: unconditionalRethrow:[empty|powerset=0]*/
unconditionalRethrow() {
  try {
    throw 'foo';
  } catch (e) {
    rethrow;
  }
}
