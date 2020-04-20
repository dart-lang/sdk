// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  new Class1(0);
  new Class1(0, 1);
  new Class2(0);
  new Class2(0, field2: 1);
}

class Class1 {
  /*member: Class1.field1:
   Class1.=?,
   initial=NullConstant
  */
  var field1;

  /*member: Class1.field2:
   Class1.=1:IntConstant(2),
   initial=NullConstant
  */
  var field2;

  /*member: Class1.field3:
   Class1.=2:IntConstant(3),
   initial=NullConstant
  */
  var field3;

  Class1(this.field1, [this.field2 = 2, this.field3 = 3]);
}

class Class2 {
  /*member: Class2.field1:
   Class2.=?,
   initial=NullConstant
  */
  var field1;

  /*member: Class2.field2:
   Class2.=field2:IntConstant(2),
   initial=NullConstant
  */
  var field2;

  /*member: Class2.field3:
   Class2.=field3:IntConstant(3),
   initial=NullConstant
  */
  var field3;

  Class2(this.field1, {this.field2 = 2, this.field3 = 3});
}
