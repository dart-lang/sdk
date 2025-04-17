// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  ifNull();
  ifNotNullInvoke();
  notIfNotNullInvoke();
}

////////////////////////////////////////////////////////////////////////////////
// If-null on parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _ifNull:[exact=JSUInt31|powerset={I}]*/
_ifNull(/*[null|exact=JSUInt31|powerset={null}{I}]*/ o) => o ?? 0;

/*member: ifNull:[null|powerset={null}]*/
ifNull() {
  _ifNull(null);
  _ifNull(0);
}

////////////////////////////////////////////////////////////////////////////////
// If-not-null access on parameter.
////////////////////////////////////////////////////////////////////////////////

/*member: _ifNotNullInvoke:[null|exact=JSBool|powerset={null}{I}]*/
_ifNotNullInvoke(/*[null|exact=JSUInt31|powerset={null}{I}]*/ o) {
  return o
      ?.
      /*[exact=JSUInt31|powerset={I}]*/
      isEven;
}

/*member: ifNotNullInvoke:[null|powerset={null}]*/
ifNotNullInvoke() {
  _ifNotNullInvoke(null);
  _ifNotNullInvoke(0);
}

////////////////////////////////////////////////////////////////////////////////
// As above but unconditional access.
////////////////////////////////////////////////////////////////////////////////

/*member: _notIfNotNullInvoke:[exact=JSBool|powerset={I}]*/
_notIfNotNullInvoke(/*[null|exact=JSUInt31|powerset={null}{I}]*/ o) {
  return o. /*[null|exact=JSUInt31|powerset={null}{I}]*/ isEven;
}

/*member: notIfNotNullInvoke:[null|powerset={null}]*/
notIfNotNullInvoke() {
  _notIfNotNullInvoke(null);
  _notIfNotNullInvoke(0);
}
