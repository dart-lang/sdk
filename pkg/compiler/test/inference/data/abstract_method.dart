// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  abstractEquals();
}

////////////////////////////////////////////////////////////////////////////////
// Call abstract method implemented by superclass.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  operator ==(_);
}

/*member: abstractEquals:[exact=JSBool|powerset={I}{O}{N}]*/
abstractEquals() =>
    Class1() /*invoke: [exact=Class1|powerset={N}{O}{N}]*/ == Class1();
