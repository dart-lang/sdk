// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {}

/*member: _promotedIfThen:[null|powerset=1]*/
_promotedIfThen(
  /*Union([exact=Class1|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
) {
  if (o is Class1) {
    o. /*invoke: [exact=Class1|powerset=0]*/ toString();
  }
}

/*member: promotedIfThen:[null|powerset=1]*/
promotedIfThen() {
  _promotedIfThen(0);
  _promotedIfThen(new Class1());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with is-test
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset=0]*/
class Class2 {}

/*member: _promotedIfThenElse:[null|powerset=1]*/
_promotedIfThenElse(
  /*Union([exact=Class2|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
) {
  if (o is Class2) {
    o. /*invoke: [exact=Class2|powerset=0]*/ toString();
  } else {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union([exact=Class2|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  }
}

/*member: promotedIfThenElse:[null|powerset=1]*/
promotedIfThenElse() {
  _promotedIfThenElse(0);
  _promotedIfThenElse(new Class2());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset=0]*/
class Class3 {}

/*member: _promotedNotIfThenElse:[null|powerset=1]*/
_promotedNotIfThenElse(
  /*Union([exact=Class3|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
) {
  if (o is! Class3) {
    o. /*invoke: Union([exact=Class3|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  } else {
    o. /*invoke: [exact=Class3|powerset=0]*/ toString();
  }
}

/*member: promotedNotIfThenElse:[null|powerset=1]*/
promotedNotIfThenElse() {
  _promotedNotIfThenElse(0);
  _promotedNotIfThenElse(new Class3());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with is-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: Class4.:[exact=Class4|powerset=0]*/
class Class4 {}

/*member: _promotedAndIfThen:[null|powerset=1]*/
_promotedAndIfThen(
  /*Union([exact=Class4|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o is Class4 && c) {
    o. /*invoke: [exact=Class4|powerset=0]*/ toString();
  }
}

/*member: promotedAndIfThen:[null|powerset=1]*/
promotedAndIfThen() {
  _promotedAndIfThen(0, true);
  _promotedAndIfThen(new Class4(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with is-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5|powerset=0]*/
class Class5 {}

/*member: _promotedAndIfThenElse:[null|powerset=1]*/
_promotedAndIfThenElse(
  /*Union([exact=Class5|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o is Class5 && c) {
    o. /*invoke: [exact=Class5|powerset=0]*/ toString();
  } else {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union([exact=Class5|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  }
}

/*member: promotedAndIfThenElse:[null|powerset=1]*/
promotedAndIfThenElse() {
  _promotedAndIfThenElse(0, true);
  _promotedAndIfThenElse(new Class5(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: Class6.:[exact=Class6|powerset=0]*/
class Class6 {}

/*member: _promotedNotAndIfThenElse:[null|powerset=1]*/
_promotedNotAndIfThenElse(
  /*Union([exact=Class6|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o is! Class6 && c) {
    o. /*invoke: Union([exact=Class6|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  } else {
    o. /*invoke: Union([exact=Class6|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  }
}

/*member: promotedNotAndIfThenElse:[null|powerset=1]*/
promotedNotAndIfThenElse() {
  _promotedNotAndIfThenElse(0, true);
  _promotedNotAndIfThenElse(new Class6(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with is-test in ||
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7|powerset=0]*/
class Class7 {}

/*member: _promotedOrIfThen:[null|powerset=1]*/
_promotedOrIfThen(
  /*Union([exact=Class7|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o is Class7 || c) {
    o. /*invoke: Union([exact=Class7|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  }
}

/*member: promotedOrIfThen:[null|powerset=1]*/
promotedOrIfThen() {
  _promotedOrIfThen(0, true);
  _promotedOrIfThen(new Class7(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with is-test in ||
////////////////////////////////////////////////////////////////////////////////

/*member: Class8.:[exact=Class8|powerset=0]*/
class Class8 {}

/*member: _promotedOrIfThenElse:[null|powerset=1]*/
_promotedOrIfThenElse(
  /*Union([exact=Class8|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o is Class8 || c) {
    o. /*invoke: Union([exact=Class8|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  } else {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union([exact=Class8|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  }
}

/*member: promotedOrIfThenElse:[null|powerset=1]*/
promotedOrIfThenElse() {
  _promotedOrIfThenElse(0, true);
  _promotedOrIfThenElse(new Class8(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test in ||
////////////////////////////////////////////////////////////////////////////////

/*member: Class9.:[exact=Class9|powerset=0]*/
class Class9 {}

/*member: _promotedNotOrIfThenElse:[null|powerset=1]*/
_promotedNotOrIfThenElse(
  /*Union([exact=Class9|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o is! Class9 || c) {
    o. /*invoke: Union([exact=Class9|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  } else {
    o. /*invoke: [exact=Class9|powerset=0]*/ toString();
  }
}

/*member: promotedNotOrIfThenElse:[null|powerset=1]*/
promotedNotOrIfThenElse() {
  _promotedNotOrIfThenElse(0, true);
  _promotedNotOrIfThenElse(new Class9(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with doubly negated is-test
////////////////////////////////////////////////////////////////////////////////

/*member: Class10.:[exact=Class10|powerset=0]*/
class Class10 {}

/*member: _promotedNotNotIfThen:[null|powerset=1]*/
_promotedNotNotIfThen(
  /*Union([exact=Class10|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
) {
  if (!(o is! Class10)) {
    o
        .
        /*invoke: [exact=Class10|powerset=0]*/
        toString();
  }
}

/*member: promotedNotNotIfThen:[null|powerset=1]*/
promotedNotNotIfThen() {
  _promotedNotNotIfThen(0);
  _promotedNotNotIfThen(new Class10());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test in parentheses
////////////////////////////////////////////////////////////////////////////////

/*member: Class11.:[exact=Class11|powerset=0]*/
class Class11 {}

/*member: _promotedParenNotIfThenElse:[null|powerset=1]*/
_promotedParenNotIfThenElse(
  /*Union([exact=Class11|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ o,
) {
  if (!(o is Class11)) {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union([exact=Class11|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ toString();
  } else {
    o
        .
        /*invoke: [exact=Class11|powerset=0]*/
        toString();
  }
}

/*member: promotedParenNotIfThenElse:[null|powerset=1]*/
promotedParenNotIfThenElse() {
  _promotedParenNotIfThenElse(0);
  _promotedParenNotIfThenElse(new Class11());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with null-test
////////////////////////////////////////////////////////////////////////////////

/*member: _nullIfThen:[null|powerset=1]*/
_nullIfThen(/*[null|exact=JSUInt31|powerset=1]*/ o) {
  if (o == null) {
    o. /*invoke: [null|powerset=1]*/ toString();
  }
}

/*member: nullIfThen:[null|powerset=1]*/
nullIfThen() {
  _nullIfThen(0);
  _nullIfThen(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement null-test
////////////////////////////////////////////////////////////////////////////////

/*member: _nullIfThenElse:[null|powerset=1]*/
_nullIfThenElse(/*[null|exact=JSUInt31|powerset=1]*/ o) {
  if (o == null) {
    o. /*invoke: [null|powerset=1]*/ toString();
  } else {
    o. /*invoke: [exact=JSUInt31|powerset=0]*/ toString();
  }
}

/*member: nullIfThenElse:[null|powerset=1]*/
nullIfThenElse() {
  _nullIfThenElse(0);
  _nullIfThenElse(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with negated null-test
////////////////////////////////////////////////////////////////////////////////

/*member: _notNullIfThen:[null|powerset=1]*/
_notNullIfThen(/*[null|exact=JSUInt31|powerset=1]*/ o) {
  if (o != null) {
    o. /*invoke: [exact=JSUInt31|powerset=0]*/ toString();
  }
}

/*member: notNullIfThen:[null|powerset=1]*/
notNullIfThen() {
  _notNullIfThen(0);
  _notNullIfThen(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated null-test
////////////////////////////////////////////////////////////////////////////////

/*member: _notNullIfThenElse:[null|powerset=1]*/
_notNullIfThenElse(/*[null|exact=JSUInt31|powerset=1]*/ o) {
  if (o != null) {
    o. /*invoke: [exact=JSUInt31|powerset=0]*/ toString();
  } else {
    o. /*invoke: [null|powerset=1]*/ toString();
  }
}

/*member: notNullIfThenElse:[null|powerset=1]*/
notNullIfThenElse() {
  _notNullIfThenElse(0);
  _notNullIfThenElse(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: _nullAndIfThen:[null|powerset=1]*/
_nullAndIfThen(
  /*[null|exact=JSUInt31|powerset=1]*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o == null && c) {
    o. /*invoke: [null|powerset=1]*/ toString();
  }
}

/*member: nullAndIfThen:[null|powerset=1]*/
nullAndIfThen() {
  _nullAndIfThen(0, true);
  _nullAndIfThen(null, false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: _nullAndIfThenElse:[null|powerset=1]*/
_nullAndIfThenElse(
  /*[null|exact=JSUInt31|powerset=1]*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o == null && c) {
    o. /*invoke: [null|powerset=1]*/ toString();
  } else {
    o. /*invoke: [null|exact=JSUInt31|powerset=1]*/ toString();
  }
}

/*member: nullAndIfThenElse:[null|powerset=1]*/
nullAndIfThenElse() {
  _nullAndIfThenElse(0, true);
  _nullAndIfThenElse(null, false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with negated null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: _notNullAndIfThen:[null|powerset=1]*/
_notNullAndIfThen(
  /*[null|exact=JSUInt31|powerset=1]*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o != null && c) {
    o. /*invoke: [exact=JSUInt31|powerset=0]*/ toString();
  }
}

/*member: notNullAndIfThen:[null|powerset=1]*/
notNullAndIfThen() {
  _notNullAndIfThen(0, true);
  _notNullAndIfThen(null, false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*member: _notNullAndIfThenElse:[null|powerset=1]*/
_notNullAndIfThenElse(
  /*[null|exact=JSUInt31|powerset=1]*/ o,
  /*[exact=JSBool|powerset=0]*/ c,
) {
  if (o != null && c) {
    o. /*invoke: [exact=JSUInt31|powerset=0]*/ toString();
  } else {
    o. /*invoke: [null|exact=JSUInt31|powerset=1]*/ toString();
  }
}

/*member: notNullAndIfThenElse:[null|powerset=1]*/
notNullAndIfThenElse() {
  _notNullAndIfThenElse(0, true);
  _notNullAndIfThenElse(null, false);
}
