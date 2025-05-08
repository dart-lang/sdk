// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  returnTrue();
  returnFalse();
  returnNot();
  returnNotFalse();
  returnNotTrue();
  returnNotOfNull();

  returnIs();
  returnIsOneInt();
  returnIsNullInt();
  returnNotIs();
  returnNotIsOneInt();
  returnNotIsNullInt();

  returnLogicalAnd();
  returnLogicalAndTrueTrue();
  returnLogicalAndFalseTrue();
  returnLogicalAndNullTrue();

  returnLogicalAndIs();
  returnLogicalAndIsNot();
  returnLogicalAndNull();
  returnLogicalAndNotNull();

  returnLogicalOr();
  returnLogicalOrFalseTrue();
  returnLogicalOrFalseFalse();
  returnLogicalOrNullTrue();

  returnLogicalOrIs();
  returnLogicalOrIsNot();
  returnLogicalOrNull();
  returnLogicalOrNotNull();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnTrue:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
returnTrue() => true;

////////////////////////////////////////////////////////////////////////////////
/// Return `false`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnFalse:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
returnFalse() => false;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of a boolean value.
////////////////////////////////////////////////////////////////////////////////

/*member: _returnNot:[exact=JSBool|powerset={I}{O}{N}]*/
_returnNot(/*[exact=JSBool|powerset={I}{O}{N}]*/ o) => !o;

/*member: returnNot:[null|powerset={null}]*/
returnNot() {
  _returnNot(true);
  _returnNot(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `false`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnNotFalse:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
returnNotFalse() => !false;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnNotTrue:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
returnNotTrue() => !true;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `null`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnNotOfNull:[exact=JSBool|powerset={I}{O}{N}]*/
returnNotOfNull() => !(null as dynamic);

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _returnIs:[exact=JSBool|powerset={I}{O}{N}]*/
_returnIs(/*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o) => o is int;

/*member: returnIs:[null|powerset={null}]*/
returnIs() {
  _returnIs(null);
  _returnIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: returnIsOneInt:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
returnIsOneInt() => 1 is int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: returnIsNullInt:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
returnIsNullInt() => null is int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _returnNotIs:[exact=JSBool|powerset={I}{O}{N}]*/
_returnNotIs(/*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o) => o is! int;

/*member: returnNotIs:[null|powerset={null}]*/
returnNotIs() {
  _returnNotIs(null);
  _returnNotIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: returnNotIsOneInt:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
returnNotIsOneInt() => 1 is! int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: returnNotIsNullInt:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
returnNotIsNullInt() => null is! int;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of booleans values.
////////////////////////////////////////////////////////////////////////////////

/*member: _returnLogicalAnd:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalAnd(
  /*[exact=JSBool|powerset={I}{O}{N}]*/ a,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ b,
) => a && b;

/*member: returnLogicalAnd:[null|powerset={null}]*/
returnLogicalAnd() {
  _returnLogicalAnd(true, true);
  _returnLogicalAnd(false, false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `true` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalAndTrueTrue:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
returnLogicalAndTrueTrue() => true && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `false` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalAndFalseTrue:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
/// ignore: dead_code
returnLogicalAndFalseTrue() => false && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `null` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalAndNullTrue:[exact=JSBool|powerset={I}{O}{N}]*/
returnLogicalAndNullTrue() => (null as dynamic) && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of is test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  /*member: Class1.field:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
  final bool field = true;
}

/*member: _returnLogicalAndIs:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalAndIs(/*[null|exact=Class1|powerset={null}{N}{O}{N}]*/ o) {
  return o is Class1 && o. /*[exact=Class1|powerset={N}{O}{N}]*/ field;
}

/*member: returnLogicalAndIs:[null|powerset={null}]*/
returnLogicalAndIs() {
  _returnLogicalAndIs(new Class1());
  _returnLogicalAndIs(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of is-not test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
class Class2 {
  /*member: Class2.field:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
  final bool field = true;
}

/*member: _returnLogicalAndIsNot:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalAndIsNot(/*[null|exact=Class2|powerset={null}{N}{O}{N}]*/ o) {
  // TODO(johnniwinther): Use negative type knowledge to show that the receiver
  // is [null].
  return o is! Class2 &&
      o. /*[null|exact=Class2|powerset={null}{N}{O}{N}]*/ field;
}

/*member: returnLogicalAndIsNot:[null|powerset={null}]*/
returnLogicalAndIsNot() {
  _returnLogicalAndIsNot(new Class2());
  _returnLogicalAndIsNot(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of null test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
class Class3 {
  /*member: Class3.field:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
  final bool field = true;
}

/*member: _returnLogicalAndNull:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalAndNull(/*[null|exact=Class3|powerset={null}{N}{O}{N}]*/ o) {
  return o == null && o. /*[null|powerset={null}]*/ field;
}

/*member: returnLogicalAndNull:[null|powerset={null}]*/
returnLogicalAndNull() {
  _returnLogicalAndNull(new Class3());
  _returnLogicalAndNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of not null test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset={N}{O}{N}]*/
class Class4 {
  /*member: Class4.field:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
  final bool field = true;
}

/*member: _returnLogicalAndNotNull:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalAndNotNull(/*[null|exact=Class4|powerset={null}{N}{O}{N}]*/ o) {
  return o != null && o. /*[exact=Class4|powerset={N}{O}{N}]*/ field;
}

/*member: returnLogicalAndNotNull:[null|powerset={null}]*/
returnLogicalAndNotNull() {
  _returnLogicalAndNotNull(new Class4());
  _returnLogicalAndNotNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of booleans values.
////////////////////////////////////////////////////////////////////////////////

/*member: _returnLogicalOr:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalOr(
  /*[exact=JSBool|powerset={I}{O}{N}]*/ a,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ b,
) => a || b;

/*member: returnLogicalOr:[null|powerset={null}]*/
returnLogicalOr() {
  _returnLogicalOr(true, true);
  _returnLogicalOr(false, false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `false` || `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalOrFalseTrue:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
returnLogicalOrFalseTrue() => false || true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `false` || `false`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalOrFalseFalse:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
returnLogicalOrFalseFalse() => false || false;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `null` || `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalOrNullTrue:[exact=JSBool|powerset={I}{O}{N}]*/
returnLogicalOrNullTrue() => (null as dynamic) || true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of is test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5|powerset={N}{O}{N}]*/
class Class5 {
  /*member: Class5.field:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
  final bool field = true;
}

/*member: _returnLogicalOrIs:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalOrIs(/*[null|exact=Class5|powerset={null}{N}{O}{N}]*/ o) {
  // TODO(johnniwinther): Use negative type knowledge to show that the receiver
  // is [null].
  return o is Class5 ||
      o. /*[null|exact=Class5|powerset={null}{N}{O}{N}]*/ field;
}

/*member: returnLogicalOrIs:[null|powerset={null}]*/
returnLogicalOrIs() {
  _returnLogicalOrIs(new Class5());
  _returnLogicalOrIs(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of is-not test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class6.:[exact=Class6|powerset={N}{O}{N}]*/
class Class6 {
  /*member: Class6.field:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
  final bool field = true;
}

/*member: _returnLogicalOrIsNot:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalOrIsNot(/*[null|exact=Class6|powerset={null}{N}{O}{N}]*/ o) {
  return o is! Class6 || o. /*[exact=Class6|powerset={N}{O}{N}]*/ field;
}

/*member: returnLogicalOrIsNot:[null|powerset={null}]*/
returnLogicalOrIsNot() {
  _returnLogicalOrIsNot(new Class6());
  _returnLogicalOrIsNot(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of null test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7|powerset={N}{O}{N}]*/
class Class7 {
  /*member: Class7.field:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
  final bool field = true;
}

/*member: _returnLogicalOrNull:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalOrNull(/*[null|exact=Class7|powerset={null}{N}{O}{N}]*/ o) {
  return o == null || o. /*[exact=Class7|powerset={N}{O}{N}]*/ field;
}

/*member: returnLogicalOrNull:[null|powerset={null}]*/
returnLogicalOrNull() {
  _returnLogicalOrNull(new Class7());
  _returnLogicalOrNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of not null test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class8.:[exact=Class8|powerset={N}{O}{N}]*/
class Class8 {
  /*member: Class8.field:Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/
  final bool field = true;
}

/*member: _returnLogicalOrNotNull:[exact=JSBool|powerset={I}{O}{N}]*/
_returnLogicalOrNotNull(/*[null|exact=Class8|powerset={null}{N}{O}{N}]*/ o) {
  return o != null || o. /*[null|powerset={null}]*/ field;
}

/*member: returnLogicalOrNotNull:[null|powerset={null}]*/
returnLogicalOrNotNull() {
  _returnLogicalOrNotNull(new Class8());
  _returnLogicalOrNotNull(null);
}
