// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  simpleIfThen();
  simpleIfThenElse();
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleIfThen:[null|exact=JSUInt31]*/
_simpleIfThen(/*[exact=JSBool]*/ c) {
  if (c) return 1;
  return null;
}

/*member: simpleIfThen:[null]*/
simpleIfThen() {
  _simpleIfThen(true);
  _simpleIfThen(false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleIfThenElse:[null|exact=JSUInt31]*/
_simpleIfThenElse(/*[exact=JSBool]*/ c) {
  if (c)
    return 1;
  else
    return null;
}

/*member: simpleIfThenElse:[null]*/
simpleIfThenElse() {
  _simpleIfThenElse(true);
  _simpleIfThenElse(false);
}
