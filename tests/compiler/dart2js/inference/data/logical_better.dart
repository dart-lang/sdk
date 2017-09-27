// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  promotedNotNotIfThen();
  promotedNotIfThenElse();
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then statement with doubly negated is-test
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {}

/*element: _promotedNotNotIfThen:[null]*/
_promotedNotNotIfThen(/*Union of [[exact=Class1], [exact=JSUInt31]]*/ o) {
  if (!(o is! Class1)) {
    o. /*invoke: [exact=Class1]*/ toString();
  }
}

/*element: promotedNotNotIfThen:[null]*/
promotedNotNotIfThen() {
  _promotedNotNotIfThen(0);
  _promotedNotNotIfThen(new Class1());
}

////////////////////////////////////////////////////////////////////////////////
// Test if-then-else statement with negated is-test in parentheses
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:[exact=Class2]*/
class Class2 {}

/*element: _promotedNotIfThenElse:[null]*/
_promotedNotIfThenElse(/*Union of [[exact=Class2], [exact=JSUInt31]]*/ o) {
  if (!(o is Class2)) {
    // TODO(johnniwinther): Use negative type knowledge to show that the
    // receiver must be [exact=JSUInt31].
    o. /*invoke: Union of [[exact=Class2], [exact=JSUInt31]]*/ toString();
  } else {
    o. /*invoke: [exact=Class2]*/ toString();
  }
}

/*element: promotedNotIfThenElse:[null]*/
promotedNotIfThenElse() {
  _promotedNotIfThenElse(0);
  _promotedNotIfThenElse(new Class2());
}
