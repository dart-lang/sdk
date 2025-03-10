// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: _simpleConditional:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
_simpleConditional(/*[exact=JSBool|powerset=0]*/ c) => c ? '' : 0;

/*member: simpleConditional:[null|powerset=1]*/
simpleConditional() {
  _simpleConditional(true);
  _simpleConditional(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleConditionalTrue:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
_simpleConditionalTrue(
  /*Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/ c,
) => c ? '' : 0;

/*member: simpleConditionalTrue:[null|powerset=1]*/
simpleConditionalTrue() {
  _simpleConditionalTrue(true);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleConditionalFalse:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
_simpleConditionalFalse(
  /*Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/ c,
) => c ? '' : 0;

/*member: simpleConditionalFalse:[null|powerset=1]*/
simpleConditionalFalse() {
  _simpleConditionalFalse(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIs:Union([exact=JSString|powerset=0], [subclass=JSPositiveInt|powerset=0], powerset: 0)*/
_conditionalIs(/*[null|exact=JSUInt31|powerset=1]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31|powerset=0]*/ abs() : '';

/*member: conditionalIs:[null|powerset=1]*/
conditionalIs() {
  _conditionalIs(null);
  _conditionalIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsInt:Union([exact=JSString|powerset=0], [subclass=JSPositiveInt|powerset=0], powerset: 0)*/
_conditionalIsInt(/*[exact=JSUInt31|powerset=0]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31|powerset=0]*/ abs() : '';

/*member: conditionalIsInt:[null|powerset=1]*/
conditionalIsInt() {
  _conditionalIsInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsNot:Union([exact=JSString|powerset=0], [subclass=JSPositiveInt|powerset=0], powerset: 0)*/
_conditionalIsNot(/*[null|exact=JSUInt31|powerset=1]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31|powerset=0]*/ abs();

/*member: conditionalIsNot:[null|powerset=1]*/
conditionalIsNot() {
  _conditionalIsNot(null);
  _conditionalIsNot(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsNotInt:Union([exact=JSString|powerset=0], [subclass=JSPositiveInt|powerset=0], powerset: 0)*/
_conditionalIsNotInt(/*[exact=JSUInt31|powerset=0]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31|powerset=0]*/ abs();

/*member: conditionalIsNotInt:[null|powerset=1]*/
conditionalIsNotInt() {
  _conditionalIsNotInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalNull:Union([exact=JSString|powerset=0], [subclass=JSPositiveInt|powerset=0], powerset: 0)*/
_conditionalNull(/*[null|exact=JSUInt31|powerset=1]*/ o) =>
    o == null ? '' : o. /*invoke: [exact=JSUInt31|powerset=0]*/ abs();

/*member: conditionalNull:[null|powerset=1]*/
conditionalNull() {
  _conditionalNull(null);
  _conditionalNull(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalNotNull:Union([exact=JSString|powerset=0], [subclass=JSPositiveInt|powerset=0], powerset: 0)*/
_conditionalNotNull(/*[null|exact=JSUInt31|powerset=1]*/ o) =>
    o != null ? o. /*invoke: [exact=JSUInt31|powerset=0]*/ abs() : '';

/*member: conditionalNotNull:[null|powerset=1]*/
conditionalNotNull() {
  _conditionalNotNull(null);
  _conditionalNotNull(1);
}
