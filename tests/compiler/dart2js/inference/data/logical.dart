// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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

/*element: returnTrue:Value mask: [true] type: [exact=JSBool]*/
returnTrue() => true;

////////////////////////////////////////////////////////////////////////////////
/// Return `false`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnFalse:Value mask: [false] type: [exact=JSBool]*/
returnFalse() => false;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of a boolean value.
////////////////////////////////////////////////////////////////////////////////

/*element: _returnNot:[exact=JSBool]*/
_returnNot(/*[exact=JSBool]*/ o) => !o;

/*element: returnNot:[null]*/
returnNot() {
  _returnNot(true);
  _returnNot(false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `false`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnNotFalse:[exact=JSBool]*/
returnNotFalse() => !false;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `true`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnNotTrue:[exact=JSBool]*/
returnNotTrue() => !true;

////////////////////////////////////////////////////////////////////////////////
/// Return negation of `null`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnNotOfNull:[exact=JSBool]*/
returnNotOfNull() => !null;

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is test.
////////////////////////////////////////////////////////////////////////////////
/*element: _returnIs:[exact=JSBool]*/
_returnIs(/*[null|exact=JSUInt31]*/ o) => o is int;

/*element: returnIs:[null]*/
returnIs() {
  _returnIs(null);
  _returnIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*element: returnIsOneInt:[exact=JSBool]*/
returnIsOneInt() => 1 is int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of an is `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*element: returnIsNullInt:[exact=JSBool]*/
returnIsNullInt() => null is int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is test.
////////////////////////////////////////////////////////////////////////////////
/*element: _returnNotIs:[exact=JSBool]*/
_returnNotIs(/*[null|exact=JSUInt31]*/ o) => o is! int;

/*element: returnNotIs:[null]*/
returnNotIs() {
  _returnNotIs(null);
  _returnNotIs(1);
}

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is `int` test known to be false.
////////////////////////////////////////////////////////////////////////////////
/*element: returnNotIsOneInt:[exact=JSBool]*/
returnNotIsOneInt() => 1 is! int;

////////////////////////////////////////////////////////////////////////////////
/// Return value of a negated is `int` test known to be true.
////////////////////////////////////////////////////////////////////////////////
/*element: returnNotIsNullInt:[exact=JSBool]*/
returnNotIsNullInt() => null is! int;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of booleans values.
////////////////////////////////////////////////////////////////////////////////

/*element: _returnLogicalAnd:[exact=JSBool]*/
_returnLogicalAnd(/*[exact=JSBool]*/ a, /*[exact=JSBool]*/ b) => a && b;

/*element: returnLogicalAnd:[null]*/
returnLogicalAnd() {
  _returnLogicalAnd(true, true);
  _returnLogicalAnd(false, false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `true` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnLogicalAndTrueTrue:[exact=JSBool]*/
returnLogicalAndTrueTrue() => true && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `false` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnLogicalAndFalseTrue:[exact=JSBool]*/
/// ignore: dead_code
returnLogicalAndFalseTrue() => false && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of `null` && `true`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnLogicalAndNullTrue:[exact=JSBool]*/
returnLogicalAndNullTrue() => null && true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of is test and use.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.field:Value mask: [true] type: [exact=JSBool]*/
  final bool field = true;
}

/*element: _returnLogicalAndIs:[exact=JSBool]*/
_returnLogicalAndIs(/*[null|exact=Class1]*/ o) {
  return o is Class1 && o. /*[exact=Class1]*/ field;
}

/*element: returnLogicalAndIs:[null]*/
returnLogicalAndIs() {
  _returnLogicalAndIs(new Class1());
  _returnLogicalAndIs(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of is-not test and use.
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:[exact=Class2]*/
class Class2 {
  /*element: Class2.field:Value mask: [true] type: [exact=JSBool]*/
  final bool field = true;
}

/*element: _returnLogicalAndIsNot:[exact=JSBool]*/
_returnLogicalAndIsNot(/*[null|exact=Class2]*/ o) {
  // TODO(johnniwinther): Use negative type knowledge to show that the receiver
  // is [null].
  return o is! Class2 && o. /*[null|exact=Class2]*/ field;
}

/*element: returnLogicalAndIsNot:[null]*/
returnLogicalAndIsNot() {
  _returnLogicalAndIsNot(new Class2());
  _returnLogicalAndIsNot(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of null test and use.
////////////////////////////////////////////////////////////////////////////////

/*element: Class3.:[exact=Class3]*/
class Class3 {
  /*element: Class3.field:Value mask: [true] type: [exact=JSBool]*/
  final bool field = true;
}

/*element: _returnLogicalAndNull:[exact=JSBool]*/
_returnLogicalAndNull(/*[null|exact=Class3]*/ o) {
  return o == null && o. /*[null]*/ field;
}

/*element: returnLogicalAndNull:[null]*/
returnLogicalAndNull() {
  _returnLogicalAndNull(new Class3());
  _returnLogicalAndNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical and of not null test and use.
////////////////////////////////////////////////////////////////////////////////

/*element: Class4.:[exact=Class4]*/
class Class4 {
  /*element: Class4.field:Value mask: [true] type: [exact=JSBool]*/
  final bool field = true;
}

/*element: _returnLogicalAndNotNull:[exact=JSBool]*/
_returnLogicalAndNotNull(/*[null|exact=Class4]*/ o) {
  return o != null && o. /*[exact=Class4]*/ field;
}

/*element: returnLogicalAndNotNull:[null]*/
returnLogicalAndNotNull() {
  _returnLogicalAndNotNull(new Class4());
  _returnLogicalAndNotNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of booleans values.
////////////////////////////////////////////////////////////////////////////////

/*element: _returnLogicalOr:[exact=JSBool]*/
_returnLogicalOr(/*[exact=JSBool]*/ a, /*[exact=JSBool]*/ b) => a || b;

/*element: returnLogicalOr:[null]*/
returnLogicalOr() {
  _returnLogicalOr(true, true);
  _returnLogicalOr(false, false);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `false` || `true`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnLogicalOrFalseTrue:[exact=JSBool]*/
returnLogicalOrFalseTrue() => false || true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `false` || `false`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnLogicalOrFalseFalse:[exact=JSBool]*/
returnLogicalOrFalseFalse() => false || false;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of `null` || `true`.
////////////////////////////////////////////////////////////////////////////////

/*element: returnLogicalOrNullTrue:[exact=JSBool]*/
returnLogicalOrNullTrue() => null || true;

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of is test or use.
////////////////////////////////////////////////////////////////////////////////

/*element: Class5.:[exact=Class5]*/
class Class5 {
  /*element: Class5.field:Value mask: [true] type: [exact=JSBool]*/
  final bool field = true;
}

/*element: _returnLogicalOrIs:[exact=JSBool]*/
_returnLogicalOrIs(/*[null|exact=Class5]*/ o) {
  // TODO(johnniwinther): Use negative type knowledge to show that the receiver
  // is [null].
  return o is Class5 || o. /*[null|exact=Class5]*/ field;
}

/*element: returnLogicalOrIs:[null]*/
returnLogicalOrIs() {
  _returnLogicalOrIs(new Class5());
  _returnLogicalOrIs(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of is-not test or use.
////////////////////////////////////////////////////////////////////////////////

/*element: Class6.:[exact=Class6]*/
class Class6 {
  /*element: Class6.field:Value mask: [true] type: [exact=JSBool]*/
  final bool field = true;
}

/*element: _returnLogicalOrIsNot:[exact=JSBool]*/
_returnLogicalOrIsNot(/*[null|exact=Class6]*/ o) {
  return o is! Class6 || o. /*[exact=Class6]*/ field;
}

/*element: returnLogicalOrIsNot:[null]*/
returnLogicalOrIsNot() {
  _returnLogicalOrIsNot(new Class6());
  _returnLogicalOrIsNot(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of null test or use.
////////////////////////////////////////////////////////////////////////////////

/*element: Class7.:[exact=Class7]*/
class Class7 {
  /*element: Class7.field:Value mask: [true] type: [exact=JSBool]*/
  final bool field = true;
}

/*element: _returnLogicalOrNull:[exact=JSBool]*/
_returnLogicalOrNull(/*[null|exact=Class7]*/ o) {
  return o == null || o. /*[exact=Class7]*/ field;
}

/*element: returnLogicalOrNull:[null]*/
returnLogicalOrNull() {
  _returnLogicalOrNull(new Class7());
  _returnLogicalOrNull(null);
}

////////////////////////////////////////////////////////////////////////////////
/// Return logical or of not null test or use.
////////////////////////////////////////////////////////////////////////////////

/*element: Class8.:[exact=Class8]*/
class Class8 {
  /*element: Class8.field:Value mask: [true] type: [exact=JSBool]*/
  final bool field = true;
}

/*element: _returnLogicalOrNotNull:[exact=JSBool]*/
_returnLogicalOrNotNull(/*[null|exact=Class8]*/ o) {
  return o != null || o. /*[null]*/ field;
}

/*element: returnLogicalOrNotNull:[null]*/
returnLogicalOrNotNull() {
  _returnLogicalOrNotNull(new Class8());
  _returnLogicalOrNotNull(null);
}
