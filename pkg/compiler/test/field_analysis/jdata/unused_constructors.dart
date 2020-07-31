// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class1 {
  /*member: Class1.field:constant=IntConstant(87)*/
  final int field;

  Class1.constructor1({this.field = 42});
  Class1.constructor2({this.field = 87});
  Class1.constructor3({this.field = 123});
}

class Class2 {
  final int field;

  const Class2([this.field]);
}

main() {
  print(new Class1.constructor2().field);
  print(const Class2(42).field);
  print(new Class2().field);
}
