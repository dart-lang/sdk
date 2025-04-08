// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  simpleIfThen();
  simpleIfThenElse();
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleIfThen:[null|exact=JSUInt31|powerset=1]*/
_simpleIfThen(/*[exact=JSBool|powerset=0]*/ c) {
  if (c) return 1;
  return null;
}

/*member: simpleIfThen:[null|powerset=1]*/
simpleIfThen() {
  _simpleIfThen(true);
  _simpleIfThen(false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleIfThenElse:[null|exact=JSUInt31|powerset=1]*/
_simpleIfThenElse(/*[exact=JSBool|powerset=0]*/ c) {
  if (c)
    return 1;
  else
    return null;
}

/*member: simpleIfThenElse:[null|powerset=1]*/
simpleIfThenElse() {
  _simpleIfThenElse(true);
  _simpleIfThenElse(false);
}
