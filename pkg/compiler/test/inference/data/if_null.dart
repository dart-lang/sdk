// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  ifNull();
  ifNotNullInvoke();
  notIfNotNullInvoke();
}

////////////////////////////////////////////////////////////////////////////////
// If-null on parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _ifNull:[exact=JSUInt31]*/
_ifNull(/*[null|exact=JSUInt31]*/ o) => o ?? 0;

/*member: ifNull:[null]*/
ifNull() {
  _ifNull(null);
  _ifNull(0);
}

////////////////////////////////////////////////////////////////////////////////
// If-not-null access on parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _ifNotNullInvoke:[null|exact=JSBool]*/
_ifNotNullInvoke(/*[null|exact=JSUInt31]*/ o) {
  return o?.
      /*[exact=JSUInt31]*/
      isEven;
}

/*member: ifNotNullInvoke:[null]*/
ifNotNullInvoke() {
  _ifNotNullInvoke(null);
  _ifNotNullInvoke(0);
}

////////////////////////////////////////////////////////////////////////////////
// As above but unconditional access.
////////////////////////////////////////////////////////////////////////////////

/*member: _notIfNotNullInvoke:[exact=JSBool]*/
_notIfNotNullInvoke(/*[null|exact=JSUInt31]*/ o) {
  return o. /*[null|exact=JSUInt31]*/ isEven;
}

/*member: notIfNotNullInvoke:[null]*/
notIfNotNullInvoke() {
  _notIfNotNullInvoke(null);
  _notIfNotNullInvoke(0);
}
