// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  asIntWithString();
  asIntWithNegative();
  asIntOfZero();
  asIntOfMinusOne();
  asIntOfString();
}

////////////////////////////////////////////////////////////////////////////////
// As int of int and non-int types.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntWithString:[exact=JSUInt31|powerset={I}{O}{N}]*/
_asIntWithString(
  /*Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ o,
) => o as int;

/*member: asIntWithString:[null|powerset={null}]*/
asIntWithString() {
  _asIntWithString(0);
  _asIntWithString('');
}

////////////////////////////////////////////////////////////////////////////////
// As int of known int and an unknown int types.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntWithNegative:[subclass=JSInt|powerset={I}{O}{N}]*/
_asIntWithNegative(/*[subclass=JSInt|powerset={I}{O}{N}]*/ o) => o as int;

/*member: asIntWithNegative:[null|powerset={null}]*/
asIntWithNegative() {
  _asIntWithNegative(0);
  _asIntWithNegative(-1);
}

////////////////////////////////////////////////////////////////////////////////
// As int of 0.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntOfZero:[exact=JSUInt31|powerset={I}{O}{N}]*/
_asIntOfZero(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) => o as int;

/*member: asIntOfZero:[null|powerset={null}]*/
asIntOfZero() {
  _asIntOfZero(0);
}

////////////////////////////////////////////////////////////////////////////////
// As int of -1.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntOfMinusOne:[subclass=JSInt|powerset={I}{O}{N}]*/
_asIntOfMinusOne(/*[subclass=JSInt|powerset={I}{O}{N}]*/ o) => o as int;

/*member: asIntOfMinusOne:[null|powerset={null}]*/
asIntOfMinusOne() {
  _asIntOfMinusOne(-1);
}

////////////////////////////////////////////////////////////////////////////////
// As int of string.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntOfString:[empty|powerset=empty]*/
_asIntOfString(
  /*Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I})*/ o,
) => o as int;

/*member: asIntOfString:[null|powerset={null}]*/
asIntOfString() {
  _asIntOfString('');
}
