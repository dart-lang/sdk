// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  simpleConditional();
  simpleConditionalTrue();
  simpleConditionalFalse();
  conditionalIs();
  conditionalIsInt();
  conditionalIsNot();
  conditionalIsNotInt();
  conditionalNull();
  conditionalNotNull();
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleConditional:Union([exact=JSString], [exact=JSUInt31])*/
_simpleConditional(/*[exact=JSBool]*/ c) => c ? '' : 0;

/*member: simpleConditional:[null]*/
simpleConditional() {
  _simpleConditional(true);
  _simpleConditional(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleConditionalTrue:Union([exact=JSString], [exact=JSUInt31])*/
_simpleConditionalTrue(/*Value([exact=JSBool], value: true)*/ c) => c ? '' : 0;

/*member: simpleConditionalTrue:[null]*/
simpleConditionalTrue() {
  _simpleConditionalTrue(true);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleConditionalFalse:Union([exact=JSString], [exact=JSUInt31])*/
_simpleConditionalFalse(/*Value([exact=JSBool], value: false)*/ c) =>
    c ? '' : 0;

/*member: simpleConditionalFalse:[null]*/
simpleConditionalFalse() {
  _simpleConditionalFalse(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIs:Union([exact=JSString], [subclass=JSPositiveInt])*/
_conditionalIs(/*[null|exact=JSUInt31]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31]*/ abs() : '';

/*member: conditionalIs:[null]*/
conditionalIs() {
  _conditionalIs(null);
  _conditionalIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsInt:Union([exact=JSString], [subclass=JSPositiveInt])*/
_conditionalIsInt(/*[exact=JSUInt31]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31]*/ abs() : '';

/*member: conditionalIsInt:[null]*/
conditionalIsInt() {
  _conditionalIsInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsNot:Union([exact=JSString], [subclass=JSPositiveInt])*/
_conditionalIsNot(/*[null|exact=JSUInt31]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31]*/ abs();

/*member: conditionalIsNot:[null]*/
conditionalIsNot() {
  _conditionalIsNot(null);
  _conditionalIsNot(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsNotInt:Union([exact=JSString], [subclass=JSPositiveInt])*/
_conditionalIsNotInt(/*[exact=JSUInt31]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31]*/ abs();

/*member: conditionalIsNotInt:[null]*/
conditionalIsNotInt() {
  _conditionalIsNotInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalNull:Union([exact=JSString], [subclass=JSPositiveInt])*/
_conditionalNull(/*[null|exact=JSUInt31]*/ o) =>
    o == null ? '' : o. /*invoke: [exact=JSUInt31]*/ abs();

/*member: conditionalNull:[null]*/
conditionalNull() {
  _conditionalNull(null);
  _conditionalNull(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalNotNull:Union([exact=JSString], [subclass=JSPositiveInt])*/
_conditionalNotNull(/*[null|exact=JSUInt31]*/ o) =>
    o != null ? o. /*invoke: [exact=JSUInt31]*/ abs() : '';

/*member: conditionalNotNull:[null]*/
conditionalNotNull() {
  _conditionalNotNull(null);
  _conditionalNotNull(1);
}
