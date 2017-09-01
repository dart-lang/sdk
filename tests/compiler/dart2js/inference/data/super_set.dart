// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  /*element: Super.field:Union of [[exact=JSUInt31], [exact=Sub]]*/
  var field = 42;
}

class Sub extends Super {
  /*element: Sub.method:[subclass=Closure]*/
  method() {
    // ignore: INVALID_ASSIGNMENT
    var a = super.field = new Sub();
    return a. /*[exact=Sub]*/ method;
  }
}

/*element: main:[null]*/
main() {
  new Sub(). /*invoke: [exact=Sub]*/ method();
}
