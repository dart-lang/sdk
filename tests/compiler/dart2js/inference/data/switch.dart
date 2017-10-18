// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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

/*element: _switchWithoutDefault:Union of [[exact=JSUInt31], [null|exact=JSString]]*/
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

/*element: switchWithoutDefault:[null]*/
switchWithoutDefault() {
  _switchWithoutDefault(0);
  _switchWithoutDefault(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement with default case.
////////////////////////////////////////////////////////////////////////////////

/*element: _switchWithDefault:Union of [[exact=JSString], [exact=JSUInt31]]*/
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

/*element: switchWithDefault:[null]*/
switchWithDefault() {
  _switchWithDefault(0);
  _switchWithDefault(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement with default case without break.
////////////////////////////////////////////////////////////////////////////////

/*element: _switchWithDefaultWithoutBreak:Union of [[exact=JSString], [exact=JSUInt31]]*/
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

/*element: switchWithDefaultWithoutBreak:[null]*/
switchWithDefaultWithoutBreak() {
  _switchWithDefaultWithoutBreak(0);
  _switchWithDefaultWithoutBreak(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement with continue.
////////////////////////////////////////////////////////////////////////////////

/*element: _switchWithContinue:Union of [[exact=JSBool], [exact=JSString], [null|exact=JSUInt31]]*/
_switchWithContinue(/*[exact=JSUInt31]*/ o) {
  dynamic local;
  switch (o) {
    case 0:
      local = 0;
      continue label;
    label:
    case 1:
      local = local
          . /*Union of [[exact=JSBool], [exact=JSString], [null|exact=JSUInt31]]*/ isEven;
      break;
    case 2:
    default:
      local = '';
  }
  return local;
}

/*element: switchWithContinue:[null]*/
switchWithContinue() {
  _switchWithContinue(0);
  _switchWithContinue(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement without continue. Identical to previous test but without
// the continue statement.
////////////////////////////////////////////////////////////////////////////////

/*element: _switchWithoutContinue:Union of [[exact=JSString], [exact=JSUInt31]]*/
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

/*element: switchWithoutContinue:[null]*/
switchWithoutContinue() {
  _switchWithoutContinue(0);
  _switchWithoutContinue(1);
}
