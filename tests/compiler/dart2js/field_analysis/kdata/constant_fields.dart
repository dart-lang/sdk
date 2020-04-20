// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  print(const Class1().field1);
  print(const Class2(field2: true).field2);
  print(const Class3().field3);
  print(const Class3(field3: true).field3);
}

class Class1 {
  /*member: Class1.field1:Class1.=field1:BoolConstant(false),initial=NullConstant*/
  final bool field1;

  const Class1({this.field1: false});
}

class Class2 {
  /*member: Class2.field2:Class2.=field2:BoolConstant(false),initial=NullConstant*/
  final bool field2;

  const Class2({this.field2: false});
}

class Class3 {
  /*member: Class3.field3:Class3.=field3:BoolConstant(false),initial=NullConstant*/
  final bool field3;

  const Class3({this.field3: false});
}
