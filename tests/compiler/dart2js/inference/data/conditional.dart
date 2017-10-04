// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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

/*element: _simpleConditional:Union of [[exact=JSString], [exact=JSUInt31]]*/
_simpleConditional(/*[exact=JSBool]*/ c) => c ? '' : 0;

/*element: simpleConditional:[null]*/
simpleConditional() {
  _simpleConditional(true);
  _simpleConditional(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*element: _simpleConditionalTrue:Union of [[exact=JSString], [exact=JSUInt31]]*/
_simpleConditionalTrue(/*Value mask: [true] type: [exact=JSBool]*/ c) =>
    c ? '' : 0;

/*element: simpleConditionalTrue:[null]*/
simpleConditionalTrue() {
  _simpleConditionalTrue(true);
}

////////////////////////////////////////////////////////////////////////////////
/// Simple conditional with unknown condition value.
////////////////////////////////////////////////////////////////////////////////

/*element: _simpleConditionalFalse:Union of [[exact=JSString], [exact=JSUInt31]]*/
_simpleConditionalFalse(/*Value mask: [false] type: [exact=JSBool]*/ c) =>
    c ? '' : 0;

/*element: simpleConditionalFalse:[null]*/
simpleConditionalFalse() {
  _simpleConditionalFalse(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*element: _conditionalIs:Union of [[exact=JSString], [subclass=JSPositiveInt]]*/
_conditionalIs(/*[null|exact=JSUInt31]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31]*/ abs() : '';

/*element: conditionalIs:[null]*/
conditionalIs() {
  _conditionalIs(null);
  _conditionalIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*element: _conditionalIsInt:Union of [[exact=JSString], [subclass=JSPositiveInt]]*/
_conditionalIsInt(/*[exact=JSUInt31]*/ o) =>
    o is int ? o. /*invoke: [exact=JSUInt31]*/ abs() : '';

/*element: conditionalIsInt:[null]*/
conditionalIsInt() {
  _conditionalIsInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not test.
////////////////////////////////////////////////////////////////////////////////
/*element: _conditionalIsNot:Union of [[exact=JSString], [subclass=JSPositiveInt]]*/
_conditionalIsNot(/*[null|exact=JSUInt31]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31]*/ abs();

/*element: conditionalIsNot:[null]*/
conditionalIsNot() {
  _conditionalIsNot(null);
  _conditionalIsNot(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is-not `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*element: _conditionalIsNotInt:Union of [[exact=JSString], [subclass=JSPositiveInt]]*/
_conditionalIsNotInt(/*[exact=JSUInt31]*/ o) =>
    o is! int ? '' : o. /*invoke: [exact=JSUInt31]*/ abs();

/*element: conditionalIsNotInt:[null]*/
conditionalIsNotInt() {
  _conditionalIsNotInt(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is test.
////////////////////////////////////////////////////////////////////////////////
/*element: _conditionalNull:Union of [[exact=JSString], [subclass=JSPositiveInt]]*/
_conditionalNull(/*[null|exact=JSUInt31]*/ o) =>
    o == null ? '' : o. /*invoke: [exact=JSUInt31]*/ abs();

/*element: conditionalNull:[null]*/
conditionalNull() {
  _conditionalNull(null);
  _conditionalNull(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Conditional with an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*element: _conditionalNotNull:Union of [[exact=JSString], [subclass=JSPositiveInt]]*/
_conditionalNotNull(/*[null|exact=JSUInt31]*/ o) =>
    o != null ? o. /*invoke: [exact=JSUInt31]*/ abs() : '';

/*element: conditionalNotNull:[null]*/
conditionalNotNull() {
  _conditionalNotNull(null);
  _conditionalNotNull(1);
}
