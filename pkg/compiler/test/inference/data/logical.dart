// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: returnTrue:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
returnTrue() => true;

////////////////////////////////////////////////////////////////////////////////
/// Return `false`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnFalse:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
returnFalse() => false;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of a boolean value.
////////////////////////////////////////////////////////////////////////////////

/*member: _returnNot:[exact=JSBool|powerset=0]*/
_returnNot(/*[exact=JSBool|powerset=0]*/ o) => !o;

/*member: returnNot:[null|powerset=1]*/
returnNot() {
  _returnNot(true);
  _returnNot(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `false`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnNotFalse:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
returnNotFalse() => !false;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnNotTrue:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
returnNotTrue() => !true;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `null`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnNotOfNull:[exact=JSBool|powerset=0]*/
returnNotOfNull() => !(null as dynamic);

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _returnIs:[exact=JSBool|powerset=0]*/
_returnIs(/*[null|exact=JSUInt31|powerset=1]*/ o) => o is int;

/*member: returnIs:[null|powerset=1]*/
returnIs() {
  _returnIs(null);
  _returnIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: returnIsOneInt:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
returnIsOneInt() => 1 is int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: returnIsNullInt:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
returnIsNullInt() => null is int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is test.
////////////////////////////////////////////////////////////////////////////////
/*member: _returnNotIs:[exact=JSBool|powerset=0]*/
_returnNotIs(/*[null|exact=JSUInt31|powerset=1]*/ o) => o is! int;

/*member: returnNotIs:[null|powerset=1]*/
returnNotIs() {
  _returnNotIs(null);
  _returnNotIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*member: returnNotIsOneInt:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
returnNotIsOneInt() => 1 is! int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*member: returnNotIsNullInt:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
returnNotIsNullInt() => null is! int;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of booleans values.
////////////////////////////////////////////////////////////////////////////////

/*member: _returnLogicalAnd:[exact=JSBool|powerset=0]*/
_returnLogicalAnd(
  /*[exact=JSBool|powerset=0]*/ a,
  /*[exact=JSBool|powerset=0]*/ b,
) => a && b;

/*member: returnLogicalAnd:[null|powerset=1]*/
returnLogicalAnd() {
  _returnLogicalAnd(true, true);
  _returnLogicalAnd(false, false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `true` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalAndTrueTrue:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
returnLogicalAndTrueTrue() => true && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `false` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalAndFalseTrue:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
/// ignore: dead_code
returnLogicalAndFalseTrue() => false && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `null` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalAndNullTrue:[exact=JSBool|powerset=0]*/
returnLogicalAndNullTrue() => (null as dynamic) && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of is test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.field:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  final bool field = true;
}

/*member: _returnLogicalAndIs:[exact=JSBool|powerset=0]*/
_returnLogicalAndIs(/*[null|exact=Class1|powerset=1]*/ o) {
  return o is Class1 && o. /*[exact=Class1|powerset=0]*/ field;
}

/*member: returnLogicalAndIs:[null|powerset=1]*/
returnLogicalAndIs() {
  _returnLogicalAndIs(new Class1());
  _returnLogicalAndIs(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of is-not test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset=0]*/
class Class2 {
  /*member: Class2.field:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  final bool field = true;
}

/*member: _returnLogicalAndIsNot:[exact=JSBool|powerset=0]*/
_returnLogicalAndIsNot(/*[null|exact=Class2|powerset=1]*/ o) {
  // TODO(johnniwinther): Use negative type knowledge to show that the receiver
  // is [null].
  return o is! Class2 && o. /*[null|exact=Class2|powerset=1]*/ field;
}

/*member: returnLogicalAndIsNot:[null|powerset=1]*/
returnLogicalAndIsNot() {
  _returnLogicalAndIsNot(new Class2());
  _returnLogicalAndIsNot(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of null test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset=0]*/
class Class3 {
  /*member: Class3.field:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  final bool field = true;
}

/*member: _returnLogicalAndNull:[exact=JSBool|powerset=0]*/
_returnLogicalAndNull(/*[null|exact=Class3|powerset=1]*/ o) {
  return o == null && o. /*[null|powerset=1]*/ field;
}

/*member: returnLogicalAndNull:[null|powerset=1]*/
returnLogicalAndNull() {
  _returnLogicalAndNull(new Class3());
  _returnLogicalAndNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of not null test and use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset=0]*/
class Class4 {
  /*member: Class4.field:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  final bool field = true;
}

/*member: _returnLogicalAndNotNull:[exact=JSBool|powerset=0]*/
_returnLogicalAndNotNull(/*[null|exact=Class4|powerset=1]*/ o) {
  return o != null && o. /*[exact=Class4|powerset=0]*/ field;
}

/*member: returnLogicalAndNotNull:[null|powerset=1]*/
returnLogicalAndNotNull() {
  _returnLogicalAndNotNull(new Class4());
  _returnLogicalAndNotNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of booleans values.
////////////////////////////////////////////////////////////////////////////////

/*member: _returnLogicalOr:[exact=JSBool|powerset=0]*/
_returnLogicalOr(
  /*[exact=JSBool|powerset=0]*/ a,
  /*[exact=JSBool|powerset=0]*/ b,
) => a || b;

/*member: returnLogicalOr:[null|powerset=1]*/
returnLogicalOr() {
  _returnLogicalOr(true, true);
  _returnLogicalOr(false, false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `false` || `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalOrFalseTrue:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
returnLogicalOrFalseTrue() => false || true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `false` || `false`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalOrFalseFalse:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
returnLogicalOrFalseFalse() => false || false;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `null` || `true`.
////////////////////////////////////////////////////////////////////////////////

/*member: returnLogicalOrNullTrue:[exact=JSBool|powerset=0]*/
returnLogicalOrNullTrue() => (null as dynamic) || true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of is test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5|powerset=0]*/
class Class5 {
  /*member: Class5.field:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  final bool field = true;
}

/*member: _returnLogicalOrIs:[exact=JSBool|powerset=0]*/
_returnLogicalOrIs(/*[null|exact=Class5|powerset=1]*/ o) {
  // TODO(johnniwinther): Use negative type knowledge to show that the receiver
  // is [null].
  return o is Class5 || o. /*[null|exact=Class5|powerset=1]*/ field;
}

/*member: returnLogicalOrIs:[null|powerset=1]*/
returnLogicalOrIs() {
  _returnLogicalOrIs(new Class5());
  _returnLogicalOrIs(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of is-not test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class6.:[exact=Class6|powerset=0]*/
class Class6 {
  /*member: Class6.field:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  final bool field = true;
}

/*member: _returnLogicalOrIsNot:[exact=JSBool|powerset=0]*/
_returnLogicalOrIsNot(/*[null|exact=Class6|powerset=1]*/ o) {
  return o is! Class6 || o. /*[exact=Class6|powerset=0]*/ field;
}

/*member: returnLogicalOrIsNot:[null|powerset=1]*/
returnLogicalOrIsNot() {
  _returnLogicalOrIsNot(new Class6());
  _returnLogicalOrIsNot(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of null test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7|powerset=0]*/
class Class7 {
  /*member: Class7.field:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  final bool field = true;
}

/*member: _returnLogicalOrNull:[exact=JSBool|powerset=0]*/
_returnLogicalOrNull(/*[null|exact=Class7|powerset=1]*/ o) {
  return o == null || o. /*[exact=Class7|powerset=0]*/ field;
}

/*member: returnLogicalOrNull:[null|powerset=1]*/
returnLogicalOrNull() {
  _returnLogicalOrNull(new Class7());
  _returnLogicalOrNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of not null test or use.
////////////////////////////////////////////////////////////////////////////////

/*member: Class8.:[exact=Class8|powerset=0]*/
class Class8 {
  /*member: Class8.field:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
  final bool field = true;
}

/*member: _returnLogicalOrNotNull:[exact=JSBool|powerset=0]*/
_returnLogicalOrNotNull(/*[null|exact=Class8|powerset=1]*/ o) {
  return o != null || o. /*[null|powerset=1]*/ field;
}

/*member: returnLogicalOrNotNull:[null|powerset=1]*/
returnLogicalOrNotNull() {
  _returnLogicalOrNotNull(new Class8());
  _returnLogicalOrNotNull(null);
}
