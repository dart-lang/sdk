// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: _simpleConditional:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
_simpleConditional(/*[exact=JSBool|powerset={I}{O}]*/ c) => c ? '' : 0;

/*member: simpleConditional:[null|powerset={null}]*/
simpleConditional() {
  _simpleConditional(true);
  _simpleConditional(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleConditionalTrue:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
_simpleConditionalTrue(
  /*Value([exact=JSBool|powerset={I}{O}], value: true, powerset: {I}{O})*/ c,
) => c ? '' : 0;

/*member: simpleConditionalTrue:[null|powerset={null}]*/
simpleConditionalTrue() {
  _simpleConditionalTrue(true);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleConditionalFalse:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
_simpleConditionalFalse(
  /*Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})*/ c,
) => c ? '' : 0;

/*member: simpleConditionalFalse:[null|powerset={null}]*/
simpleConditionalFalse() {
  _simpleConditionalFalse(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIs:Union([exact=JSString|powerset={I}{O}], [subclass=JSPositiveInt|powerset={I}{O}], powerset: {I}{O})*/
_conditionalIs(/*[null|exact=JSUInt31|powerset={null}{I}{O}]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ abs() : '';

/*member: conditionalIs:[null|powerset={null}]*/
conditionalIs() {
  _conditionalIs(null);
  _conditionalIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsInt:Union([exact=JSString|powerset={I}{O}], [subclass=JSPositiveInt|powerset={I}{O}], powerset: {I}{O})*/
_conditionalIsInt(/*[exact=JSUInt31|powerset={I}{O}]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ abs() : '';

/*member: conditionalIsInt:[null|powerset={null}]*/
conditionalIsInt() {
  _conditionalIsInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsNot:Union([exact=JSString|powerset={I}{O}], [subclass=JSPositiveInt|powerset={I}{O}], powerset: {I}{O})*/
_conditionalIsNot(/*[null|exact=JSUInt31|powerset={null}{I}{O}]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ abs();

/*member: conditionalIsNot:[null|powerset={null}]*/
conditionalIsNot() {
  _conditionalIsNot(null);
  _conditionalIsNot(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsNotInt:Union([exact=JSString|powerset={I}{O}], [subclass=JSPositiveInt|powerset={I}{O}], powerset: {I}{O})*/
_conditionalIsNotInt(/*[exact=JSUInt31|powerset={I}{O}]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ abs();

/*member: conditionalIsNotInt:[null|powerset={null}]*/
conditionalIsNotInt() {
  _conditionalIsNotInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalNull:Union([exact=JSString|powerset={I}{O}], [subclass=JSPositiveInt|powerset={I}{O}], powerset: {I}{O})*/
_conditionalNull(/*[null|exact=JSUInt31|powerset={null}{I}{O}]*/ o) =>
    o == null ? '' : o. /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ abs();

/*member: conditionalNull:[null|powerset={null}]*/
conditionalNull() {
  _conditionalNull(null);
  _conditionalNull(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalNotNull:Union([exact=JSString|powerset={I}{O}], [subclass=JSPositiveInt|powerset={I}{O}], powerset: {I}{O})*/
_conditionalNotNull(/*[null|exact=JSUInt31|powerset={null}{I}{O}]*/ o) =>
    o != null ? o. /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ abs() : '';

/*member: conditionalNotNull:[null|powerset={null}]*/
conditionalNotNull() {
  _conditionalNotNull(null);
  _conditionalNotNull(1);
}
