// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: _breakInWhile:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
_breakInWhile(/*[exact=JSBool|powerset=0]*/ b) {
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

/*member: breakInWhile:[null|powerset=1]*/
breakInWhile() {
  _breakInWhile(true);
  _breakInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// The while loop above _without_ the break statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _noBreakInWhile:[exact=JSUInt31|powerset=0]*/
_noBreakInWhile(/*[exact=JSBool|powerset=0]*/ b) {
  dynamic local = 42;
  while (b) {
    if (b) {
      local = '';
    }
    local = 0;
  }
  return local;
}

/*member: noBreakInWhile:[null|powerset=1]*/
noBreakInWhile() {
  _noBreakInWhile(true);
  _noBreakInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// A continue statement in a while loop.
////////////////////////////////////////////////////////////////////////////////

/*member: _continueInWhile:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
_continueInWhile(/*[exact=JSBool|powerset=0]*/ b) {
  dynamic local = 42;
  while (b) {
    local /*invoke: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ +
        null;
    if (b) {
      local = '';
      continue;
    }
    local = 0;
  }
  return local;
}

/*member: continueInWhile:[null|powerset=1]*/
continueInWhile() {
  _continueInWhile(true);
  _continueInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// The while loop above _without_ the continue statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _noContinueInWhile:[exact=JSUInt31|powerset=0]*/
_noContinueInWhile(/*[exact=JSBool|powerset=0]*/ b) {
  dynamic local = 42;
  while (b) {
    local /*invoke: [exact=JSUInt31|powerset=0]*/ + null;
    if (b) {
      local = '';
    }
    local = 0;
  }
  return local;
}

/*member: noContinueInWhile:[null|powerset=1]*/
noContinueInWhile() {
  _noContinueInWhile(true);
  _noContinueInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// A conditional break statement in a labeled statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _breakInIf:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
_breakInIf(/*[exact=JSBool|powerset=0]*/ b) {
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

/*member: breakInIf:[null|powerset=1]*/
breakInIf() {
  _breakInIf(true);
  _breakInIf(false);
}

////////////////////////////////////////////////////////////////////////////////
// The "labeled statement" above _without_ the break statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _noBreakInIf:[exact=JSUInt31|powerset=0]*/
_noBreakInIf(/*[exact=JSBool|powerset=0]*/ b) {
  dynamic local = 42;
  {
    local = '';
    if (b) {}
    local = 0;
  }
  return local;
}

/*member: noBreakInIf:[null|powerset=1]*/
noBreakInIf() {
  _noBreakInIf(true);
  _noBreakInIf(false);
}

////////////////////////////////////////////////////////////////////////////////
// An unconditional break statement in a labeled statement.
////////////////////////////////////////////////////////////////////////////////

/*member: breakInBlock:Value([exact=JSString|powerset=0], value: "", powerset: 0)*/
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

/*member: noBreakInBlock:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
noBreakInBlock() {
  dynamic local = 42;
  label:
  {
    local = '';
    local = false;
  }
  return local;
}
