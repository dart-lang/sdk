// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  /*Super.field:[exact=JSUInt31]*/
  var field = 42;
}

class Sub extends Super {
  /*Sub.method:[exact=JSUInt31]*/
  method() => super.field;
}

/*main:[null]*/
main() {
  new Sub(). /*[exact=Sub]*/ method();
}
