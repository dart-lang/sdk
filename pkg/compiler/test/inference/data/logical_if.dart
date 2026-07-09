// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  promotedIfThen();
  promotedIfThenElse();
  promotedNotIfThenElse();
  promotedAndIfThen();
  promotedAndIfThenElse();
  promotedNotAndIfThenElse();
  promotedOrIfThen();
  promotedOrIfThenElse();
  promotedNotOrIfThenElse();
  promotedNotNotIfThen();
  promotedParenNotIfThenElse();

  nullIfThen();
  nullIfThenElse();
  notNullIfThen();
  notNullIfThenElse();
  nullAndIfThen();
  nullAndIfThenElse();
  notNullAndIfThen();
  notNullAndIfThenElse();
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with is-test
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {}

/*member: _promotedIfThen:[null|powerset={null}]*/
_promotedIfThen(
  /*Union([exact=Class1|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
) {
  if (o is Class1) {
    o. /*invoke: [exact=Class1|powerset={N}{O}{N}]*/ toString();
  }
}

/*member: promotedIfThen:[null|powerset={null}]*/
promotedIfThen() {
  _promotedIfThen(0);
  _promotedIfThen(new Class1());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with is-test
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
class Class2 {}

/*member: _promotedIfThenElse:[null|powerset={null}]*/
_promotedIfThenElse(
  /*Union([exact=Class2|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
) {
  if (o is Class2) {
    o. /*invoke: [exact=Class2|powerset={N}{O}{N}]*/ toString();
  } else {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union([exact=Class2|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  }
}

/*member: promotedIfThenElse:[null|powerset={null}]*/
promotedIfThenElse() {
  _promotedIfThenElse(0);
  _promotedIfThenElse(new Class2());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
class Class3 {}

/*member: _promotedNotIfThenElse:[null|powerset={null}]*/
_promotedNotIfThenElse(
  /*Union([exact=Class3|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
) {
  if (o is! Class3) {
    o. /*invoke: Union([exact=Class3|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  } else {
    o. /*invoke: [exact=Class3|powerset={N}{O}{N}]*/ toString();
  }
}

/*member: promotedNotIfThenElse:[null|powerset={null}]*/
promotedNotIfThenElse() {
  _promotedNotIfThenElse(0);
  _promotedNotIfThenElse(new Class3());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with is-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset={N}{O}{N}]*/
class Class4 {}

/*member: _promotedAndIfThen:[null|powerset={null}]*/
_promotedAndIfThen(
  /*Union([exact=Class4|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o is Class4 && c) {
    o. /*invoke: [exact=Class4|powerset={N}{O}{N}]*/ toString();
  }
}

/*member: promotedAndIfThen:[null|powerset={null}]*/
promotedAndIfThen() {
  _promotedAndIfThen(0, true);
  _promotedAndIfThen(new Class4(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with is-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5|powerset={N}{O}{N}]*/
class Class5 {}

/*member: _promotedAndIfThenElse:[null|powerset={null}]*/
_promotedAndIfThenElse(
  /*Union([exact=Class5|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o is Class5 && c) {
    o. /*invoke: [exact=Class5|powerset={N}{O}{N}]*/ toString();
  } else {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union([exact=Class5|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  }
}

/*member: promotedAndIfThenElse:[null|powerset={null}]*/
promotedAndIfThenElse() {
  _promotedAndIfThenElse(0, true);
  _promotedAndIfThenElse(new Class5(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: Class6.:[exact=Class6|powerset={N}{O}{N}]*/
class Class6 {}

/*member: _promotedNotAndIfThenElse:[null|powerset={null}]*/
_promotedNotAndIfThenElse(
  /*Union([exact=Class6|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o is! Class6 && c) {
    o. /*invoke: Union([exact=Class6|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  } else {
    o. /*invoke: Union([exact=Class6|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  }
}

/*member: promotedNotAndIfThenElse:[null|powerset={null}]*/
promotedNotAndIfThenElse() {
  _promotedNotAndIfThenElse(0, true);
  _promotedNotAndIfThenElse(new Class6(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with is-test in ||
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7|powerset={N}{O}{N}]*/
class Class7 {}

/*member: _promotedOrIfThen:[null|powerset={null}]*/
_promotedOrIfThen(
  /*Union([exact=Class7|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o is Class7 || c) {
    o. /*invoke: Union([exact=Class7|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  }
}

/*member: promotedOrIfThen:[null|powerset={null}]*/
promotedOrIfThen() {
  _promotedOrIfThen(0, true);
  _promotedOrIfThen(new Class7(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with is-test in ||
////////////////////////////////////////////////////////////////////////////////

/*member: Class8.:[exact=Class8|powerset={N}{O}{N}]*/
class Class8 {}

/*member: _promotedOrIfThenElse:[null|powerset={null}]*/
_promotedOrIfThenElse(
  /*Union([exact=Class8|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o is Class8 || c) {
    o. /*invoke: Union([exact=Class8|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  } else {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union([exact=Class8|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  }
}

/*member: promotedOrIfThenElse:[null|powerset={null}]*/
promotedOrIfThenElse() {
  _promotedOrIfThenElse(0, true);
  _promotedOrIfThenElse(new Class8(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test in ||
////////////////////////////////////////////////////////////////////////////////

/*member: Class9.:[exact=Class9|powerset={N}{O}{N}]*/
class Class9 {}

/*member: _promotedNotOrIfThenElse:[null|powerset={null}]*/
_promotedNotOrIfThenElse(
  /*Union([exact=Class9|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o is! Class9 || c) {
    o. /*invoke: Union([exact=Class9|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  } else {
    o. /*invoke: [exact=Class9|powerset={N}{O}{N}]*/ toString();
  }
}

/*member: promotedNotOrIfThenElse:[null|powerset={null}]*/
promotedNotOrIfThenElse() {
  _promotedNotOrIfThenElse(0, true);
  _promotedNotOrIfThenElse(new Class9(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with doubly negated is-test
////////////////////////////////////////////////////////////////////////////////

/*member: Class10.:[exact=Class10|powerset={N}{O}{N}]*/
class Class10 {}

/*member: _promotedNotNotIfThen:[null|powerset={null}]*/
_promotedNotNotIfThen(
  /*Union([exact=Class10|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
) {
  if (!(o is! Class10)) {
    o
        .
        /*invoke: [exact=Class10|powerset={N}{O}{N}]*/
        toString();
  }
}

/*member: promotedNotNotIfThen:[null|powerset={null}]*/
promotedNotNotIfThen() {
  _promotedNotNotIfThen(0);
  _promotedNotNotIfThen(new Class10());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test in parentheses
////////////////////////////////////////////////////////////////////////////////

/*member: Class11.:[exact=Class11|powerset={N}{O}{N}]*/
class Class11 {}

/*member: _promotedParenNotIfThenElse:[null|powerset={null}]*/
_promotedParenNotIfThenElse(
  /*Union([exact=Class11|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ o,
) {
  if (!(o is Class11)) {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union([exact=Class11|powerset={N}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {IN}{O}{N})*/ toString();
  } else {
    o
        .
        /*invoke: [exact=Class11|powerset={N}{O}{N}]*/
        toString();
  }
}

/*member: promotedParenNotIfThenElse:[null|powerset={null}]*/
promotedParenNotIfThenElse() {
  _promotedParenNotIfThenElse(0);
  _promotedParenNotIfThenElse(new Class11());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with null-test
////////////////////////////////////////////////////////////////////////////////

/*member: _nullIfThen:[null|powerset={null}]*/
_nullIfThen(/*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o) {
  if (o == null) {
    o. /*invoke: [null|powerset={null}]*/ toString();
  }
}

/*member: nullIfThen:[null|powerset={null}]*/
nullIfThen() {
  _nullIfThen(0);
  _nullIfThen(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement null-test
////////////////////////////////////////////////////////////////////////////////

/*member: _nullIfThenElse:[null|powerset={null}]*/
_nullIfThenElse(/*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o) {
  if (o == null) {
    o. /*invoke: [null|powerset={null}]*/ toString();
  } else {
    o. /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ toString();
  }
}

/*member: nullIfThenElse:[null|powerset={null}]*/
nullIfThenElse() {
  _nullIfThenElse(0);
  _nullIfThenElse(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with negated null-test
////////////////////////////////////////////////////////////////////////////////

/*member: _notNullIfThen:[null|powerset={null}]*/
_notNullIfThen(/*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o) {
  if (o != null) {
    o. /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ toString();
  }
}

/*member: notNullIfThen:[null|powerset={null}]*/
notNullIfThen() {
  _notNullIfThen(0);
  _notNullIfThen(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated null-test
////////////////////////////////////////////////////////////////////////////////

/*member: _notNullIfThenElse:[null|powerset={null}]*/
_notNullIfThenElse(/*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o) {
  if (o != null) {
    o. /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ toString();
  } else {
    o. /*invoke: [null|powerset={null}]*/ toString();
  }
}

/*member: notNullIfThenElse:[null|powerset={null}]*/
notNullIfThenElse() {
  _notNullIfThenElse(0);
  _notNullIfThenElse(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: _nullAndIfThen:[null|powerset={null}]*/
_nullAndIfThen(
  /*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o == null && c) {
    o. /*invoke: [null|powerset={null}]*/ toString();
  }
}

/*member: nullAndIfThen:[null|powerset={null}]*/
nullAndIfThen() {
  _nullAndIfThen(0, true);
  _nullAndIfThen(null, false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: _nullAndIfThenElse:[null|powerset={null}]*/
_nullAndIfThenElse(
  /*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o == null && c) {
    o. /*invoke: [null|powerset={null}]*/ toString();
  } else {
    o. /*invoke: [null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ toString();
  }
}

/*member: nullAndIfThenElse:[null|powerset={null}]*/
nullAndIfThenElse() {
  _nullAndIfThenElse(0, true);
  _nullAndIfThenElse(null, false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with negated null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: _notNullAndIfThen:[null|powerset={null}]*/
_notNullAndIfThen(
  /*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o != null && c) {
    o. /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ toString();
  }
}

/*member: notNullAndIfThen:[null|powerset={null}]*/
notNullAndIfThen() {
  _notNullAndIfThen(0, true);
  _notNullAndIfThen(null, false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: _notNullAndIfThenElse:[null|powerset={null}]*/
_notNullAndIfThenElse(
  /*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ o,
  /*[exact=JSBool|powerset={I}{O}{N}]*/ c,
) {
  if (o != null && c) {
    o. /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ toString();
  } else {
    o. /*invoke: [null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ toString();
  }
}

/*member: notNullAndIfThenElse:[null|powerset={null}]*/
notNullAndIfThenElse() {
  _notNullAndIfThenElse(0, true);
  _notNullAndIfThenElse(null, false);
}
