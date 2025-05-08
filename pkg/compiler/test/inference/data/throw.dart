// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  unconditionalThrow();
  conditionalThrow();
  conditionalThrowReturn();
  unconditionalRethrow();
}

////////////////////////////////////////////////////////////////////////////////
/// Method that throws unconditionally.
////////////////////////////////////////////////////////////////////////////////

/*member: unconditionalThrow:[empty|powerset=empty]*/
unconditionalThrow() => throw 'foo';

////////////////////////////////////////////////////////////////////////////////
/// Method that throws conditionally.
////////////////////////////////////////////////////////////////////////////////

/*member: _conditionalThrow:[null|powerset={null}]*/
_conditionalThrow(/*[exact=JSBool|powerset={I}{O}{N}]*/ o) {
  if (o) throw 'foo';
}

/*member: conditionalThrow:[null|powerset={null}]*/
conditionalThrow() {
  _conditionalThrow(true);
  _conditionalThrow(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Method that throws conditionally and return 0.
////////////////////////////////////////////////////////////////////////////////

/*member: _conditionalThrowReturn:[exact=JSUInt31|powerset={I}{O}{N}]*/
_conditionalThrowReturn(/*[exact=JSBool|powerset={I}{O}{N}]*/ o) {
  if (o) throw 'foo';
  return 0;
}

/*member: conditionalThrowReturn:[null|powerset={null}]*/
conditionalThrowReturn() {
  _conditionalThrowReturn(true);
  _conditionalThrowReturn(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Method that rethrows unconditionally.
////////////////////////////////////////////////////////////////////////////////

/*member: unconditionalRethrow:[empty|powerset=empty]*/
unconditionalRethrow() {
  try {
    throw 'foo';
  } catch (e) {
    rethrow;
  }
}
