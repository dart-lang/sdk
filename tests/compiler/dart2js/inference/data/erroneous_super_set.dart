// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  missingSuperFieldUpdate();
}

////////////////////////////////////////////////////////////////////////////////
// Update of missing super field.
////////////////////////////////////////////////////////////////////////////////

/*element: Super4.:[exact=Super4]*/
class Super4 {}

/*element: Sub4.:[exact=Sub4]*/
class Sub4 extends Super4 {
  /*element: Sub4.method:[empty]*/
  method() {
    // ignore: UNDEFINED_SUPER_SETTER
    var a = super.field = new Sub4();
    return a. /*[empty]*/ method;
  }
}

/*element: missingSuperFieldUpdate:[null]*/
missingSuperFieldUpdate() {
  new Sub4(). /*invoke: [exact=Sub4]*/ method();
}
