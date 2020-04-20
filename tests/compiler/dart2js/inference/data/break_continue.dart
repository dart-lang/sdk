// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  breakInWhile();
  noBreakInWhile();
  continueInWhile();
  noContinueInWhile();
  breakInIf();
  noBreakInIf();
}

////////////////////////////////////////////////////////////////////////////////
// A break statement in a while loop.
////////////////////////////////////////////////////////////////////////////////

/*member: _breakInWhile:Union([exact=JSString], [exact=JSUInt31])*/
_breakInWhile(/*[exact=JSBool]*/ b) {
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

/*member: breakInWhile:[null]*/
breakInWhile() {
  _breakInWhile(true);
  _breakInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// The while loop above _without_ the break statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _noBreakInWhile:[exact=JSUInt31]*/
_noBreakInWhile(/*[exact=JSBool]*/ b) {
  dynamic local = 42;
  while (b) {
    if (b) {
      local = '';
    }
    local = 0;
  }
  return local;
}

/*member: noBreakInWhile:[null]*/
noBreakInWhile() {
  _noBreakInWhile(true);
  _noBreakInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// A continue statement in a while loop.
////////////////////////////////////////////////////////////////////////////////

/*member: _continueInWhile:Union([exact=JSString], [exact=JSUInt31])*/
_continueInWhile(/*[exact=JSBool]*/ b) {
  dynamic local = 42;
  while (b) {
    local /*invoke: Union([exact=JSString], [exact=JSUInt31])*/ + null;
    if (b) {
      local = '';
      continue;
    }
    local = 0;
  }
  return local;
}

/*member: continueInWhile:[null]*/
continueInWhile() {
  _continueInWhile(true);
  _continueInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// The while loop above _without_ the continue statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _noContinueInWhile:[exact=JSUInt31]*/
_noContinueInWhile(/*[exact=JSBool]*/ b) {
  dynamic local = 42;
  while (b) {
    local /*invoke: [exact=JSUInt31]*/ + null;
    if (b) {
      local = '';
    }
    local = 0;
  }
  return local;
}

/*member: noContinueInWhile:[null]*/
noContinueInWhile() {
  _noContinueInWhile(true);
  _noContinueInWhile(false);
}

////////////////////////////////////////////////////////////////////////////////
// A break statement in a labeled statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _breakInIf:Union([exact=JSString], [exact=JSUInt31])*/
_breakInIf(/*[exact=JSBool]*/ b) {
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

/*member: breakInIf:[null]*/
breakInIf() {
  _breakInIf(true);
  _breakInIf(false);
}

////////////////////////////////////////////////////////////////////////////////
// The "labeled statement" above _without_ the break statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _noBreakInIf:[exact=JSUInt31]*/
_noBreakInIf(/*[exact=JSBool]*/ b) {
  dynamic local = 42;
  {
    local = '';
    if (b) {}
    local = 0;
  }
  return local;
}

/*member: noBreakInIf:[null]*/
noBreakInIf() {
  _noBreakInIf(true);
  _noBreakInIf(false);
}
