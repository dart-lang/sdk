// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
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

/*member: returnTrue:Value([exact=JSBool], value: true)*/
returnTrue() => true;

////////////////////////////////////////////////////////////////////////////////
/// Return `false`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnFalse:Value([exact=JSBool], value: false)*/
returnFalse() => false;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of a boolean value.
////////////////////////////////////////////////////////////////////////////////

/*member: _returnNot:[exact=JSBool]*/
_returnNot(/*[exact=JSBool]*/ o) => !o;

/*member: returnNot:[null]*/
returnNot() {
  _returnNot(true);
  _returnNot(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `false`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnNotFalse:Value([exact=JSBool], value: true)*/
returnNotFalse() => !false;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnNotTrue:Value([exact=JSBool], value: false)*/
returnNotTrue() => !true;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `null`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnNotOfNull:[exact=JSBool]*/
returnNotOfNull() => !null;

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _returnIs:[exact=JSBool]*/
_returnIs(/*[null|exact=JSUInt31]*/ o) => o is int;

/*member: returnIs:[null]*/
returnIs() {
  _returnIs(null);
  _returnIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: returnIsOneInt:Value([exact=JSBool], value: true)*/
returnIsOneInt() => 1 is int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: returnIsNullInt:Value([exact=JSBool], value: false)*/
returnIsNullInt() => null is int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _returnNotIs:[exact=JSBool]*/
_returnNotIs(/*[null|exact=JSUInt31]*/ o) => o is! int;

/*member: returnNotIs:[null]*/
returnNotIs() {
  _returnNotIs(null);
  _returnNotIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: returnNotIsOneInt:Value([exact=JSBool], value: false)*/
returnNotIsOneInt() => 1 is! int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: returnNotIsNullInt:Value([exact=JSBool], value: true)*/
returnNotIsNullInt() => null is! int;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of booleans values.
////////////////////////////////////////////////////////////////////////////////

/*member: _returnLogicalAnd:[exact=JSBool]*/
_returnLogicalAnd(/*[exact=JSBool]*/ a, /*[exact=JSBool]*/ b) => a && b;

/*member: returnLogicalAnd:[null]*/
returnLogicalAnd() {
  _returnLogicalAnd(true, true);
  _returnLogicalAnd(false, false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `true` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalAndTrueTrue:Value([exact=JSBool], value: true)*/
returnLogicalAndTrueTrue() => true && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `false` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalAndFalseTrue:Value([exact=JSBool], value: false)*/
/// ignore: dead_code
returnLogicalAndFalseTrue() => false && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `null` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalAndNullTrue:[exact=JSBool]*/
returnLogicalAndNullTrue() => null && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of is test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1]*/
class Class1 {
  /*member: Class1.field:Value([exact=JSBool], value: true)*/
  final bool field = true;
}

/*member: _returnLogicalAndIs:[exact=JSBool]*/
_returnLogicalAndIs(/*[null|exact=Class1]*/ o) {
  return o is Class1 && o. /*[exact=Class1]*/ field;
}

/*member: returnLogicalAndIs:[null]*/
returnLogicalAndIs() {
  _returnLogicalAndIs(new Class1());
  _returnLogicalAndIs(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of is-not test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2]*/
class Class2 {
  /*member: Class2.field:Value([exact=JSBool], value: true)*/
  final bool field = true;
}

/*member: _returnLogicalAndIsNot:[exact=JSBool]*/
_returnLogicalAndIsNot(/*[null|exact=Class2]*/ o) {
  // TODO(johnniwinther): Use negative type knowledge to show that the receiver
  // is [null].
  return o is! Class2 && o. /*[null|exact=Class2]*/ field;
}

/*member: returnLogicalAndIsNot:[null]*/
returnLogicalAndIsNot() {
  _returnLogicalAndIsNot(new Class2());
  _returnLogicalAndIsNot(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of null test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3]*/
class Class3 {
  /*member: Class3.field:Value([exact=JSBool], value: true)*/
  final bool field = true;
}

/*member: _returnLogicalAndNull:[exact=JSBool]*/
_returnLogicalAndNull(/*[null|exact=Class3]*/ o) {
  return o == null && o. /*[null]*/ field;
}

/*member: returnLogicalAndNull:[null]*/
returnLogicalAndNull() {
  _returnLogicalAndNull(new Class3());
  _returnLogicalAndNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of not null test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4]*/
class Class4 {
  /*member: Class4.field:Value([exact=JSBool], value: true)*/
  final bool field = true;
}

/*member: _returnLogicalAndNotNull:[exact=JSBool]*/
_returnLogicalAndNotNull(/*[null|exact=Class4]*/ o) {
  return o != null && o. /*[exact=Class4]*/ field;
}

/*member: returnLogicalAndNotNull:[null]*/
returnLogicalAndNotNull() {
  _returnLogicalAndNotNull(new Class4());
  _returnLogicalAndNotNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of booleans values.
////////////////////////////////////////////////////////////////////////////////

/*member: _returnLogicalOr:[exact=JSBool]*/
_returnLogicalOr(/*[exact=JSBool]*/ a, /*[exact=JSBool]*/ b) => a || b;

/*member: returnLogicalOr:[null]*/
returnLogicalOr() {
  _returnLogicalOr(true, true);
  _returnLogicalOr(false, false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `false` || `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalOrFalseTrue:Value([exact=JSBool], value: true)*/
returnLogicalOrFalseTrue() => false || true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `false` || `false`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalOrFalseFalse:Value([exact=JSBool], value: false)*/
returnLogicalOrFalseFalse() => false || false;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `null` || `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalOrNullTrue:[exact=JSBool]*/
returnLogicalOrNullTrue() => null || true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of is test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5]*/
class Class5 {
  /*member: Class5.field:Value([exact=JSBool], value: true)*/
  final bool field = true;
}

/*member: _returnLogicalOrIs:[exact=JSBool]*/
_returnLogicalOrIs(/*[null|exact=Class5]*/ o) {
  // TODO(johnniwinther): Use negative type knowledge to show that the receiver
  // is [null].
  return o is Class5 || o. /*[null|exact=Class5]*/ field;
}

/*member: returnLogicalOrIs:[null]*/
returnLogicalOrIs() {
  _returnLogicalOrIs(new Class5());
  _returnLogicalOrIs(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of is-not test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class6.:[exact=Class6]*/
class Class6 {
  /*member: Class6.field:Value([exact=JSBool], value: true)*/
  final bool field = true;
}

/*member: _returnLogicalOrIsNot:[exact=JSBool]*/
_returnLogicalOrIsNot(/*[null|exact=Class6]*/ o) {
  return o is! Class6 || o. /*[exact=Class6]*/ field;
}

/*member: returnLogicalOrIsNot:[null]*/
returnLogicalOrIsNot() {
  _returnLogicalOrIsNot(new Class6());
  _returnLogicalOrIsNot(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of null test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7]*/
class Class7 {
  /*member: Class7.field:Value([exact=JSBool], value: true)*/
  final bool field = true;
}

/*member: _returnLogicalOrNull:[exact=JSBool]*/
_returnLogicalOrNull(/*[null|exact=Class7]*/ o) {
  return o == null || o. /*[exact=Class7]*/ field;
}

/*member: returnLogicalOrNull:[null]*/
returnLogicalOrNull() {
  _returnLogicalOrNull(new Class7());
  _returnLogicalOrNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of not null test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class8.:[exact=Class8]*/
class Class8 {
  /*member: Class8.field:Value([exact=JSBool], value: true)*/
  final bool field = true;
}

/*member: _returnLogicalOrNotNull:[exact=JSBool]*/
_returnLogicalOrNotNull(/*[null|exact=Class8]*/ o) {
  return o != null || o. /*[null]*/ field;
}

/*member: returnLogicalOrNotNull:[null]*/
returnLogicalOrNotNull() {
  _returnLogicalOrNotNull(new Class8());
  _returnLogicalOrNotNull(null);
}
