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

/*member: _simpleConditional:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
_simpleConditional(/*[exact=JSBool|powerset={I}]*/ c) => c ? '' : 0;

/*member: simpleConditional:[null|powerset={null}]*/
simpleConditional() {
  _simpleConditional(true);
  _simpleConditional(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleConditionalTrue:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
_simpleConditionalTrue(
  /*Value([exact=JSBool|powerset={I}], value: true, powerset: {I})*/ c,
) => c ? '' : 0;

/*member: simpleConditionalTrue:[null|powerset={null}]*/
simpleConditionalTrue() {
  _simpleConditionalTrue(true);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*member: _simpleConditionalFalse:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
_simpleConditionalFalse(
  /*Value([exact=JSBool|powerset={I}], value: false, powerset: {I})*/ c,
) => c ? '' : 0;

/*member: simpleConditionalFalse:[null|powerset={null}]*/
simpleConditionalFalse() {
  _simpleConditionalFalse(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIs:Union([exact=JSString|powerset={I}], [subclass=JSPositiveInt|powerset={I}], powerset: {I})*/
_conditionalIs(/*[null|exact=JSUInt31|powerset={null}{I}]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31|powerset={I}]*/ abs() : '';

/*member: conditionalIs:[null|powerset={null}]*/
conditionalIs() {
  _conditionalIs(null);
  _conditionalIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsInt:Union([exact=JSString|powerset={I}], [subclass=JSPositiveInt|powerset={I}], powerset: {I})*/
_conditionalIsInt(/*[exact=JSUInt31|powerset={I}]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31|powerset={I}]*/ abs() : '';

/*member: conditionalIsInt:[null|powerset={null}]*/
conditionalIsInt() {
  _conditionalIsInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsNot:Union([exact=JSString|powerset={I}], [subclass=JSPositiveInt|powerset={I}], powerset: {I})*/
_conditionalIsNot(/*[null|exact=JSUInt31|powerset={null}{I}]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31|powerset={I}]*/ abs();

/*member: conditionalIsNot:[null|powerset={null}]*/
conditionalIsNot() {
  _conditionalIsNot(null);
  _conditionalIsNot(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalIsNotInt:Union([exact=JSString|powerset={I}], [subclass=JSPositiveInt|powerset={I}], powerset: {I})*/
_conditionalIsNotInt(/*[exact=JSUInt31|powerset={I}]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31|powerset={I}]*/ abs();

/*member: conditionalIsNotInt:[null|powerset={null}]*/
conditionalIsNotInt() {
  _conditionalIsNotInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalNull:Union([exact=JSString|powerset={I}], [subclass=JSPositiveInt|powerset={I}], powerset: {I})*/
_conditionalNull(/*[null|exact=JSUInt31|powerset={null}{I}]*/ o) =>
    o == null ? '' : o. /*invoke: [exact=JSUInt31|powerset={I}]*/ abs();

/*member: conditionalNull:[null|powerset={null}]*/
conditionalNull() {
  _conditionalNull(null);
  _conditionalNull(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: _conditionalNotNull:Union([exact=JSString|powerset={I}], [subclass=JSPositiveInt|powerset={I}], powerset: {I})*/
_conditionalNotNull(/*[null|exact=JSUInt31|powerset={null}{I}]*/ o) =>
    o != null ? o. /*invoke: [exact=JSUInt31|powerset={I}]*/ abs() : '';

/*member: conditionalNotNull:[null|powerset={null}]*/
conditionalNotNull() {
  _conditionalNotNull(null);
  _conditionalNotNull(1);
}
