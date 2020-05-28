// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  var c = new Class1.a();
  c.field3a = null;
  c.field4a = null;
  c.field5a = null;
  new Class1.b();

  print(c.field1);
  print(c.field2);
  print(c.field3a);
  print(c.field3b);
  print(c.field4a);
  print(c.field4b);
  print(c.field5a);
  print(c.field5b);
}

class Class1 {
  var field1 = 0;
  var field2;

  /*member: Class1.field3a:allocator,initial=IntConstant(3)*/
  var field3a;

  /*member: Class1.field3b:constant=IntConstant(3)*/
  var field3b;

  /*member: Class1.field4a:allocator,initial=IntConstant(4)*/
  var field4a = 4;

  /*member: Class1.field4b:constant=IntConstant(4)*/
  var field4b = 4;

  /*member: Class1.field5a:allocator,initial=IntConstant(5)*/
  var field5a = 5;

  /*member: Class1.field5b:constant=IntConstant(5)*/
  var field5b = 5;

  Class1.a()
      : field1 = 1,
        field2 = 1,
        field3a = 3,
        field3b = 3,
        field5a = 5,
        field5b = 5;

  Class1.b()
      : field2 = 2,
        field3a = 3,
        field3b = 3,
        field5a = 5,
        field5b = 5;
}
