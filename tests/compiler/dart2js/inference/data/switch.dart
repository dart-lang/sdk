// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  switchWithoutDefault();
  switchWithDefault();
  switchWithDefaultWithoutBreak();
  switchWithContinue();
  switchWithoutContinue();
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement without default case.
////////////////////////////////////////////////////////////////////////////////

/*member: _switchWithoutDefault:Union(null, [exact=JSString], [exact=JSUInt31])*/
_switchWithoutDefault(/*[exact=JSUInt31]*/ o) {
  var local;
  switch (o) {
    case 0:
      local = 0;
      break;
    case 1:
      local = '';
      break;
  }
  return local;
}

/*member: switchWithoutDefault:[null]*/
switchWithoutDefault() {
  _switchWithoutDefault(0);
  _switchWithoutDefault(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement with default case.
////////////////////////////////////////////////////////////////////////////////

/*member: _switchWithDefault:Union([exact=JSString], [exact=JSUInt31])*/
_switchWithDefault(/*[exact=JSUInt31]*/ o) {
  var local;
  switch (o) {
    case 0:
      local = 0;
      break;
    case 1:
    default:
      local = '';
      break;
  }
  return local;
}

/*member: switchWithDefault:[null]*/
switchWithDefault() {
  _switchWithDefault(0);
  _switchWithDefault(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement with default case without break.
////////////////////////////////////////////////////////////////////////////////

/*member: _switchWithDefaultWithoutBreak:Union([exact=JSString], [exact=JSUInt31])*/
_switchWithDefaultWithoutBreak(/*[exact=JSUInt31]*/ o) {
  var local;
  switch (o) {
    case 0:
      local = 0;
      break;
    case 1:
    default:
      local = '';
  }
  return local;
}

/*member: switchWithDefaultWithoutBreak:[null]*/
switchWithDefaultWithoutBreak() {
  _switchWithDefaultWithoutBreak(0);
  _switchWithDefaultWithoutBreak(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement with continue.
////////////////////////////////////////////////////////////////////////////////

/*member: _switchWithContinue:Union(null, [exact=JSBool], [exact=JSString], [exact=JSUInt31])*/
_switchWithContinue(/*[exact=JSUInt31]*/ o) {
  dynamic local;
  switch (o) {
    case 0:
      local = 0;
      continue label;
    label:
    case 1:
      local = local
          . /*Union(null, [exact=JSBool], [exact=JSString], [exact=JSUInt31])*/ isEven;
      break;
    case 2:
    default:
      local = '';
  }
  return local;
}

/*member: switchWithContinue:[null]*/
switchWithContinue() {
  _switchWithContinue(0);
  _switchWithContinue(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement without continue. Identical to previous test but without
// the continue statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _switchWithoutContinue:Union([exact=JSString], [exact=JSUInt31])*/
_switchWithoutContinue(/*[exact=JSUInt31]*/ o) {
  dynamic local;
  switch (o) {
    case 0:
      local = 0;
      break;
    case 1:
      local = local. /*[null]*/ isEven;
      break;
    case 2:
    default:
      local = '';
  }
  return local;
}

/*member: switchWithoutContinue:[null]*/
switchWithoutContinue() {
  _switchWithoutContinue(0);
  _switchWithoutContinue(1);
}
