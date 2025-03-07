// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: _asIntWithString:[exact=JSUInt31|powerset=0]*/
_asIntWithString(
  /*Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
) => o as int;

/*member: asIntWithString:[null|powerset=1]*/
asIntWithString() {
  _asIntWithString(0);
  _asIntWithString('');
}

////////////////////////////////////////////////////////////////////////////////
// As int of known int and an unknown int types.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntWithNegative:[subclass=JSInt|powerset=0]*/
_asIntWithNegative(/*[subclass=JSInt|powerset=0]*/ o) => o as int;

/*member: asIntWithNegative:[null|powerset=1]*/
asIntWithNegative() {
  _asIntWithNegative(0);
  _asIntWithNegative(-1);
}

////////////////////////////////////////////////////////////////////////////////
// As int of 0.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntOfZero:[exact=JSUInt31|powerset=0]*/
_asIntOfZero(/*[exact=JSUInt31|powerset=0]*/ o) => o as int;

/*member: asIntOfZero:[null|powerset=1]*/
asIntOfZero() {
  _asIntOfZero(0);
}

////////////////////////////////////////////////////////////////////////////////
// As int of -1.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntOfMinusOne:[subclass=JSInt|powerset=0]*/
_asIntOfMinusOne(/*[subclass=JSInt|powerset=0]*/ o) => o as int;

/*member: asIntOfMinusOne:[null|powerset=1]*/
asIntOfMinusOne() {
  _asIntOfMinusOne(-1);
}

////////////////////////////////////////////////////////////////////////////////
// As int of string.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntOfString:[empty|powerset=0]*/
_asIntOfString(
  /*Value([exact=JSString|powerset=0], value: "", powerset: 0)*/ o,
) => o as int;

/*member: asIntOfString:[null|powerset=1]*/
asIntOfString() {
  _asIntOfString('');
}
