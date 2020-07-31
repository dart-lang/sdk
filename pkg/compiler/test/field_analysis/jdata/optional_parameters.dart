// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  var c1a = new Class1a(0);
  new Class1a(0, 1);
  c1a.field1 = null;
  c1a.field2 = null;
  c1a.field3 = null;
  print(c1a.field1);
  print(c1a.field2);
  print(c1a.field3);

  var c1b = new Class1b(0);
  new Class1b(0, 1);
  print(c1b.field1);
  print(c1b.field2);
  print(c1b.field3);

  var c2a = new Class2a(0);
  new Class2a(0, field2: 1);
  c2a.field1 = null;
  c2a.field2 = null;
  c2a.field3 = null;
  print(c2a.field1);
  print(c2a.field2);
  print(c2a.field3);

  var c2b = new Class2b(0);
  new Class2b(0, field2: 1);
  print(c2b.field1);
  print(c2b.field2);
  print(c2b.field3);
}

class Class1a {
  /*member: Class1a.field1:*/
  var field1;

  /*member: Class1a.field2:*/
  var field2;

  /*member: Class1a.field3:allocator,initial=IntConstant(3)*/
  var field3;

  Class1a(this.field1, [this.field2 = 2, this.field3 = 3]);
}

class Class1b {
  /*member: Class1b.field1:*/
  var field1;

  /*member: Class1b.field2:*/
  var field2;

  /*member: Class1b.field3:constant=IntConstant(3)*/
  var field3;

  Class1b(this.field1, [this.field2 = 2, this.field3 = 3]);
}

class Class2a {
  /*member: Class2a.field1:*/
  var field1;

  /*member: Class2a.field2:*/
  var field2;

  /*member: Class2a.field3:allocator,initial=IntConstant(3)*/
  var field3;

  Class2a(this.field1, {this.field2 = 2, this.field3 = 3});
}

class Class2b {
  /*member: Class2b.field1:*/
  var field1;

  /*member: Class2b.field2:*/
  var field2;

  /*member: Class2b.field3:constant=IntConstant(3)*/
  var field3;

  Class2b(this.field1, {this.field2 = 2, this.field3 = 3});
}
