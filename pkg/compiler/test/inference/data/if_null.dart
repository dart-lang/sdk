// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  ifNull();
  ifNotNullInvoke();
  notIfNotNullInvoke();
}

////////////////////////////////////////////////////////////////////////////////
// If-null on parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _ifNull:[exact=JSUInt31|powerset=0]*/
_ifNull(/*[null|exact=JSUInt31|powerset=1]*/ o) => o ?? 0;

/*member: ifNull:[null|powerset=1]*/
ifNull() {
  _ifNull(null);
  _ifNull(0);
}

////////////////////////////////////////////////////////////////////////////////
// If-not-null access on parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _ifNotNullInvoke:[null|exact=JSBool|powerset=1]*/
_ifNotNullInvoke(/*[null|exact=JSUInt31|powerset=1]*/ o) {
  return o
      ?.
      /*[exact=JSUInt31|powerset=0]*/
      isEven;
}

/*member: ifNotNullInvoke:[null|powerset=1]*/
ifNotNullInvoke() {
  _ifNotNullInvoke(null);
  _ifNotNullInvoke(0);
}

////////////////////////////////////////////////////////////////////////////////
// As above but unconditional access.
////////////////////////////////////////////////////////////////////////////////

/*member: _notIfNotNullInvoke:[exact=JSBool|powerset=0]*/
_notIfNotNullInvoke(/*[null|exact=JSUInt31|powerset=1]*/ o) {
  return o. /*[null|exact=JSUInt31|powerset=1]*/ isEven;
}

/*member: notIfNotNullInvoke:[null|powerset=1]*/
notIfNotNullInvoke() {
  _notIfNotNullInvoke(null);
  _notIfNotNullInvoke(0);
}
