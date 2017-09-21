// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  simpleIfThen();
  simpleIfThenElse();
  promotedIfThen();
  promotedIfThenElse();
  promotedNotIfThenElse();
  nullIfThen();
  nullIfThenElse();
  notNullIfThen();
  notNullIfThenElse();
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement
////////////////////////////////////////////////////////////////////////////////

/*element: _simpleIfThen:[null|exact=JSUInt31]*/
_simpleIfThen(/*[exact=JSBool]*/ c) {
  if (c) return 1;
  return null;
}

/*element: simpleIfThen:[null]*/
simpleIfThen() {
  _simpleIfThen(true);
  _simpleIfThen(false);
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement
////////////////////////////////////////////////////////////////////////////////

/*element: _simpleIfThenElse:[null|exact=JSUInt31]*/
_simpleIfThenElse(/*[exact=JSBool]*/ c) {
  if (c)
    return 1;
  else
    return null;
}

/*element: simpleIfThenElse:[null]*/
simpleIfThenElse() {
  _simpleIfThenElse(true);
  _simpleIfThenElse(false);
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
