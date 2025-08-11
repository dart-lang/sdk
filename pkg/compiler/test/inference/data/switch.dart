// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: _switchWithoutDefault:Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
_switchWithoutDefault(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
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

/*member: switchWithoutDefault:[null|powerset={null}]*/
switchWithoutDefault() {
  _switchWithoutDefault(0);
  _switchWithoutDefault(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement with default case.
////////////////////////////////////////////////////////////////////////////////

/*member: _switchWithDefault:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
_switchWithDefault(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
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

/*member: switchWithDefault:[null|powerset={null}]*/
switchWithDefault() {
  _switchWithDefault(0);
  _switchWithDefault(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement with default case without break.
////////////////////////////////////////////////////////////////////////////////

/*member: _switchWithDefaultWithoutBreak:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
_switchWithDefaultWithoutBreak(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
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

/*member: switchWithDefaultWithoutBreak:[null|powerset={null}]*/
switchWithDefaultWithoutBreak() {
  _switchWithDefaultWithoutBreak(0);
  _switchWithDefaultWithoutBreak(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement with continue.
////////////////////////////////////////////////////////////////////////////////

/*member: _switchWithContinue:Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {I}{O}{IN})*/
_switchWithContinue(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
  dynamic local;
  switch (o) {
    case 0:
      local = 0;
      continue label;
    label:
    case 1:
      local = local
          . /*Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/ isEven;
      break;
    case 2:
    default:
      local = '';
  }
  return local;
}

/*member: switchWithContinue:[null|powerset={null}]*/
switchWithContinue() {
  _switchWithContinue(0);
  _switchWithContinue(1);
}

////////////////////////////////////////////////////////////////////////////////
// Switch statement without continue. Identical to previous test but without
// the continue statement.
////////////////////////////////////////////////////////////////////////////////

/*member: _switchWithoutContinue:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
_switchWithoutContinue(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ o) {
  dynamic local;
  switch (o) {
    case 0:
      local = 0;
      break;
    case 1:
      local = local. /*[null|powerset={null}]*/ isEven;
      break;
    case 2:
    default:
      local = '';
  }
  return local;
}

/*member: switchWithoutContinue:[null|powerset={null}]*/
switchWithoutContinue() {
  _switchWithoutContinue(0);
  _switchWithoutContinue(1);
}
