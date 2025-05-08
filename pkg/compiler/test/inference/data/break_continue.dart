// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  breakInWhile();
  noBreakInWhile();
  continueInWhile();
  noContinueInWhile();
  breakInIf();
  noBreakInIf();
  breakInBlock();
  noBreakInBlock();
}

////////////////////////////////////////////////////////////////////////////////
// A break statement in a while loop.
////////////////////////////////////////////////////////////////////////////////

/*member: _breakInWhile:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
_breakInWhile(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  dynamic local = 42;
  while (b) {
    if (b) {
      local = '';
      break;
    }
    local = 0;
  }
  return local;
}

/*member: breakInWhile:[null|powerset={null}]*/
breakInWhile() {
  _breakInWhile(true);
  _breakInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// The while loop above _without_ the break statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _noBreakInWhile:[exact=JSUInt31|powerset={I}{O}{N}]*/
_noBreakInWhile(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  dynamic local = 42;
  while (b) {
    if (b) {
      local = '';
    }
    local = 0;
  }
  return local;
}

/*member: noBreakInWhile:[null|powerset={null}]*/
noBreakInWhile() {
  _noBreakInWhile(true);
  _noBreakInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// A continue statement in a while loop.
////////////////////////////////////////////////////////////////////////////////

/*member: _continueInWhile:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
_continueInWhile(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  dynamic local = 42;
  while (b) {
    local /*invoke: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/ +
        null;
    if (b) {
      local = '';
      continue;
    }
    local = 0;
  }
  return local;
}

/*member: continueInWhile:[null|powerset={null}]*/
continueInWhile() {
  _continueInWhile(true);
  _continueInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// The while loop above _without_ the continue statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _noContinueInWhile:[exact=JSUInt31|powerset={I}{O}{N}]*/
_noContinueInWhile(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  dynamic local = 42;
  while (b) {
    local /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ + null;
    if (b) {
      local = '';
    }
    local = 0;
  }
  return local;
}

/*member: noContinueInWhile:[null|powerset={null}]*/
noContinueInWhile() {
  _noContinueInWhile(true);
  _noContinueInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// A conditional break statement in a labeled statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _breakInIf:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
_breakInIf(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  dynamic local = 42;
  label:
  {
    local = '';
    if (b) {
      break label;
    }
    local = 0;
  }
  return local;
}

/*member: breakInIf:[null|powerset={null}]*/
breakInIf() {
  _breakInIf(true);
  _breakInIf(false);
}

////////////////////////////////////////////////////////////////////////////////
// The "labeled statement" above _without_ the break statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _noBreakInIf:[exact=JSUInt31|powerset={I}{O}{N}]*/
_noBreakInIf(/*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  dynamic local = 42;
  {
    local = '';
    if (b) {}
    local = 0;
  }
  return local;
}

/*member: noBreakInIf:[null|powerset={null}]*/
noBreakInIf() {
  _noBreakInIf(true);
  _noBreakInIf(false);
}

////////////////////////////////////////////////////////////////////////////////
// An unconditional break statement in a labeled statement.
////////////////////////////////////////////////////////////////////////////////

/*member: breakInBlock:Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I})*/
breakInBlock() {
  dynamic local = 42;
  label:
  {
    local = '';
    break label;
    local = false;
  }
  return local;
}

////////////////////////////////////////////////////////////////////////////////
// The "labeled statement" above _without_ the break statement.
////////////////////////////////////////////////////////////////////////////////

/*member: noBreakInBlock:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
noBreakInBlock() {
  dynamic local = 42;
  label:
  {
    local = '';
    local = false;
  }
  return local;
}
