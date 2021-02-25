// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
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

/*member: _asIntWithString:[exact=JSUInt31]*/
_asIntWithString(/*Union([exact=JSString], [exact=JSUInt31])*/ o) => o as int;

/*member: asIntWithString:[null]*/
asIntWithString() {
  _asIntWithString(0);
  _asIntWithString('');
}

////////////////////////////////////////////////////////////////////////////////
// As int of known int and an unknown int types.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntWithNegative:[subclass=JSInt]*/
_asIntWithNegative(/*[subclass=JSInt]*/ o) => o as int;

/*member: asIntWithNegative:[null]*/
asIntWithNegative() {
  _asIntWithNegative(0);
  _asIntWithNegative(-1);
}

////////////////////////////////////////////////////////////////////////////////
// As int of 0.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntOfZero:[exact=JSUInt31]*/
_asIntOfZero(/*[exact=JSUInt31]*/ o) => o as int;

/*member: asIntOfZero:[null]*/
asIntOfZero() {
  _asIntOfZero(0);
}

////////////////////////////////////////////////////////////////////////////////
// As int of -1.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntOfMinusOne:[subclass=JSInt]*/
_asIntOfMinusOne(/*[subclass=JSInt]*/ o) => o as int;

/*member: asIntOfMinusOne:[null]*/
asIntOfMinusOne() {
  _asIntOfMinusOne(-1);
}

////////////////////////////////////////////////////////////////////////////////
// As int of string.
////////////////////////////////////////////////////////////////////////////////

/*member: _asIntOfString:[empty]*/
_asIntOfString(/*Value([exact=JSString], value: "")*/ o) => o as int;

/*member: asIntOfString:[null]*/
asIntOfString() {
  _asIntOfString('');
}
