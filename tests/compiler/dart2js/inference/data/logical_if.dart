// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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

/*element: Class1.:[exact=Class1]*/
class Class1 {}

/*element: _promotedIfThen:[null]*/
_promotedIfThen(/*Union of [[exact=Class1], [exact=JSUInt31]]*/ o) {
  if (o is Class1) {
    o. /*invoke: [exact=Class1]*/ toString();
  }
}

/*element: promotedIfThen:[null]*/
promotedIfThen() {
  _promotedIfThen(0);
  _promotedIfThen(new Class1());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with is-test
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:[exact=Class2]*/
class Class2 {}

/*element: _promotedIfThenElse:[null]*/
_promotedIfThenElse(/*Union of [[exact=Class2], [exact=JSUInt31]]*/ o) {
  if (o is Class2) {
    o. /*invoke: [exact=Class2]*/ toString();
  } else {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union of [[exact=Class2], [exact=JSUInt31]]*/ toString();
  }
}

/*element: promotedIfThenElse:[null]*/
promotedIfThenElse() {
  _promotedIfThenElse(0);
  _promotedIfThenElse(new Class2());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test
////////////////////////////////////////////////////////////////////////////////

/*element: Class3.:[exact=Class3]*/
class Class3 {}

/*element: _promotedNotIfThenElse:[null]*/
_promotedNotIfThenElse(/*Union of [[exact=Class3], [exact=JSUInt31]]*/ o) {
  if (o is! Class3) {
    o. /*invoke: Union of [[exact=Class3], [exact=JSUInt31]]*/ toString();
  } else {
    o. /*invoke: [exact=Class3]*/ toString();
  }
}

/*element: promotedNotIfThenElse:[null]*/
promotedNotIfThenElse() {
  _promotedNotIfThenElse(0);
  _promotedNotIfThenElse(new Class3());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with is-test in &&
////////////////////////////////////////////////////////////////////////////////

/*element: Class4.:[exact=Class4]*/
class Class4 {}

/*element: _promotedAndIfThen:[null]*/
_promotedAndIfThen(
    /*Union of [[exact=Class4], [exact=JSUInt31]]*/ o,
    /*[exact=JSBool]*/ c) {
  if (o is Class4 && c) {
    o. /*invoke: [exact=Class4]*/ toString();
  }
}

/*element: promotedAndIfThen:[null]*/
promotedAndIfThen() {
  _promotedAndIfThen(0, true);
  _promotedAndIfThen(new Class4(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with is-test in &&
////////////////////////////////////////////////////////////////////////////////

/*element: Class5.:[exact=Class5]*/
class Class5 {}

/*element: _promotedAndIfThenElse:[null]*/
_promotedAndIfThenElse(
    /*Union of [[exact=Class5], [exact=JSUInt31]]*/ o,
    /*[exact=JSBool]*/ c) {
  if (o is Class5 && c) {
    o. /*invoke: [exact=Class5]*/ toString();
  } else {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union of [[exact=Class5], [exact=JSUInt31]]*/ toString();
  }
}

/*element: promotedAndIfThenElse:[null]*/
promotedAndIfThenElse() {
  _promotedAndIfThenElse(0, true);
  _promotedAndIfThenElse(new Class5(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test in &&
////////////////////////////////////////////////////////////////////////////////

/*element: Class6.:[exact=Class6]*/
class Class6 {}

/*element: _promotedNotAndIfThenElse:[null]*/
_promotedNotAndIfThenElse(
    /*Union of [[exact=Class6], [exact=JSUInt31]]*/ o,
    /*[exact=JSBool]*/ c) {
  if (o is! Class6 && c) {
    o. /*invoke: Union of [[exact=Class6], [exact=JSUInt31]]*/ toString();
  } else {
    o. /*invoke: Union of [[exact=Class6], [exact=JSUInt31]]*/ toString();
  }
}

/*element: promotedNotAndIfThenElse:[null]*/
promotedNotAndIfThenElse() {
  _promotedNotAndIfThenElse(0, true);
  _promotedNotAndIfThenElse(new Class6(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with is-test in ||
////////////////////////////////////////////////////////////////////////////////

/*element: Class7.:[exact=Class7]*/
class Class7 {}

/*element: _promotedOrIfThen:[null]*/
_promotedOrIfThen(
    /*Union of [[exact=Class7], [exact=JSUInt31]]*/ o,
    /*[exact=JSBool]*/ c) {
  if (o is Class7 || c) {
    o. /*invoke: Union of [[exact=Class7], [exact=JSUInt31]]*/ toString();
  }
}

/*element: promotedOrIfThen:[null]*/
promotedOrIfThen() {
  _promotedOrIfThen(0, true);
  _promotedOrIfThen(new Class7(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with is-test in ||
////////////////////////////////////////////////////////////////////////////////

/*element: Class8.:[exact=Class8]*/
class Class8 {}

/*element: _promotedOrIfThenElse:[null]*/
_promotedOrIfThenElse(
    /*Union of [[exact=Class8], [exact=JSUInt31]]*/ o,
    /*[exact=JSBool]*/ c) {
  if (o is Class8 || c) {
    o. /*invoke: Union of [[exact=Class8], [exact=JSUInt31]]*/ toString();
  } else {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union of [[exact=Class8], [exact=JSUInt31]]*/ toString();
  }
}

/*element: promotedOrIfThenElse:[null]*/
promotedOrIfThenElse() {
  _promotedOrIfThenElse(0, true);
  _promotedOrIfThenElse(new Class8(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test in ||
////////////////////////////////////////////////////////////////////////////////

/*element: Class9.:[exact=Class9]*/
class Class9 {}

/*element: _promotedNotOrIfThenElse:[null]*/
_promotedNotOrIfThenElse(
    /*Union of [[exact=Class9], [exact=JSUInt31]]*/ o,
    /*[exact=JSBool]*/ c) {
  if (o is! Class9 || c) {
    o. /*invoke: Union of [[exact=Class9], [exact=JSUInt31]]*/ toString();
  } else {
    o. /*invoke: Union of [[exact=Class9], [exact=JSUInt31]]*/ toString();
  }
}

/*element: promotedNotOrIfThenElse:[null]*/
promotedNotOrIfThenElse() {
  _promotedNotOrIfThenElse(0, true);
  _promotedNotOrIfThenElse(new Class9(), false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with null-test
////////////////////////////////////////////////////////////////////////////////

/*element: _nullIfThen:[null]*/
_nullIfThen(/*[null|exact=JSUInt31]*/ o) {
  if (o == null) {
    o. /*invoke: [null]*/ toString();
  }
}

/*element: nullIfThen:[null]*/
nullIfThen() {
  _nullIfThen(0);
  _nullIfThen(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement null-test
////////////////////////////////////////////////////////////////////////////////

/*element: _nullIfThenElse:[null]*/
_nullIfThenElse(/*[null|exact=JSUInt31]*/ o) {
  if (o == null) {
    o. /*invoke: [null]*/ toString();
  } else {
    o. /*invoke: [exact=JSUInt31]*/ toString();
  }
}

/*element: nullIfThenElse:[null]*/
nullIfThenElse() {
  _nullIfThenElse(0);
  _nullIfThenElse(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with negated null-test
////////////////////////////////////////////////////////////////////////////////

/*element: _notNullIfThen:[null]*/
_notNullIfThen(/*[null|exact=JSUInt31]*/ o) {
  if (o != null) {
    o. /*invoke: [exact=JSUInt31]*/ toString();
  }
}

/*element: notNullIfThen:[null]*/
notNullIfThen() {
  _notNullIfThen(0);
  _notNullIfThen(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated null-test
////////////////////////////////////////////////////////////////////////////////

/*element: _notNullIfThenElse:[null]*/
_notNullIfThenElse(/*[null|exact=JSUInt31]*/ o) {
  if (o != null) {
    o. /*invoke: [exact=JSUInt31]*/ toString();
  } else {
    o. /*invoke: [null]*/ toString();
  }
}

/*element: notNullIfThenElse:[null]*/
notNullIfThenElse() {
  _notNullIfThenElse(0);
  _notNullIfThenElse(null);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*element: _nullAndIfThen:[null]*/
_nullAndIfThen(/*[null|exact=JSUInt31]*/ o, /*[exact=JSBool]*/ c) {
  if (o == null && c) {
    o. /*invoke: [null]*/ toString();
  }
}

/*element: nullAndIfThen:[null]*/
nullAndIfThen() {
  _nullAndIfThen(0, true);
  _nullAndIfThen(null, false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*element: _nullAndIfThenElse:[null]*/
_nullAndIfThenElse(/*[null|exact=JSUInt31]*/ o, /*[exact=JSBool]*/ c) {
  if (o == null && c) {
    o. /*invoke: [null]*/ toString();
  } else {
    o. /*invoke: [null|exact=JSUInt31]*/ toString();
  }
}

/*element: nullAndIfThenElse:[null]*/
nullAndIfThenElse() {
  _nullAndIfThenElse(0, true);
  _nullAndIfThenElse(null, false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with negated null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*element: _notNullAndIfThen:[null]*/
_notNullAndIfThen(/*[null|exact=JSUInt31]*/ o, /*[exact=JSBool]*/ c) {
  if (o != null && c) {
    o. /*invoke: [exact=JSUInt31]*/ toString();
  }
}

/*element: notNullAndIfThen:[null]*/
notNullAndIfThen() {
  _notNullAndIfThen(0, true);
  _notNullAndIfThen(null, false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated null-test in &&
////////////////////////////////////////////////////////////////////////////////

/*element: _notNullAndIfThenElse:[null]*/
_notNullAndIfThenElse(/*[null|exact=JSUInt31]*/ o, /*[exact=JSBool]*/ c) {
  if (o != null && c) {
    o. /*invoke: [exact=JSUInt31]*/ toString();
  } else {
    o. /*invoke: [null|exact=JSUInt31]*/ toString();
  }
}

/*element: notNullAndIfThenElse:[null]*/
notNullAndIfThenElse() {
  _notNullAndIfThenElse(0, true);
  _notNullAndIfThenElse(null, false);
}
