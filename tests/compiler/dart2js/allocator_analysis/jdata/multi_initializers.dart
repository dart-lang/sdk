// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  new Class1.a();
  new Class1.b();
}

class Class1 {
  var field1 = 0;
  var field2;
  var field3;

  /*element: Class1.field4:initial=IntConstant(4)*/
  var field4 = 4;

  var field5 = 5;

  Class1.a()
      : field1 = 1,
        field2 = 1,
        field3 = 3,
        field5 = 5;

  Class1.b()
      : field2 = 2,
        field3 = 3,
        field5 = 5;
}
