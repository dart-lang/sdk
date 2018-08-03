// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  missingSuperFieldAccess();
}

////////////////////////////////////////////////////////////////////////////////
// Access of missing super field.
////////////////////////////////////////////////////////////////////////////////

/*element: Super4.:[exact=Super4]*/
class Super4 {}

/*element: Sub4.:[exact=Sub4]*/
class Sub4 extends Super4 {
  /*element: Sub4.method:[empty]*/
  // ignore: UNDEFINED_SUPER_GETTER
  method() => super.field;
}

/*element: missingSuperFieldAccess:[null]*/
missingSuperFieldAccess() {
  new Sub4(). /*invoke: [exact=Sub4]*/ method();
}
