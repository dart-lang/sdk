// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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

/*element: _asIntWithString:[exact=JSUInt31]*/
_asIntWithString(/*Union of [[exact=JSString], [exact=JSUInt31]]*/ o) =>
    o as int;

/*element: asIntWithString:[null]*/
asIntWithString() {
  _asIntWithString(0);
  _asIntWithString('');
}

////////////////////////////////////////////////////////////////////////////////
// As int of known int and an unknown int types.
////////////////////////////////////////////////////////////////////////////////

/*element: _asIntWithNegative:[subclass=JSInt]*/
_asIntWithNegative(/*[subclass=JSInt]*/ o) => o as int;

/*element: asIntWithNegative:[null]*/
asIntWithNegative() {
  _asIntWithNegative(0);
  _asIntWithNegative(/*invoke: [exact=JSUInt31]*/ -1);
}

////////////////////////////////////////////////////////////////////////////////
// As int of 0.
////////////////////////////////////////////////////////////////////////////////

/*element: _asIntOfZero:[exact=JSUInt31]*/
_asIntOfZero(/*[exact=JSUInt31]*/ o) => o as int;

/*element: asIntOfZero:[null]*/
asIntOfZero() {
  _asIntOfZero(0);
}

////////////////////////////////////////////////////////////////////////////////
// As int of -1.
////////////////////////////////////////////////////////////////////////////////

/*element: _asIntOfMinusOne:[subclass=JSInt]*/
_asIntOfMinusOne(/*[subclass=JSInt]*/ o) => o as int;

/*element: asIntOfMinusOne:[null]*/
asIntOfMinusOne() {
  _asIntOfMinusOne(/*invoke: [exact=JSUInt31]*/ -1);
}

////////////////////////////////////////////////////////////////////////////////
// As int of string.
////////////////////////////////////////////////////////////////////////////////

/*element: _asIntOfString:[empty]*/
_asIntOfString(/*Value mask: [""] type: [exact=JSString]*/ o) => o as int;

/*element: asIntOfString:[null]*/
asIntOfString() {
  _asIntOfString('');
}
