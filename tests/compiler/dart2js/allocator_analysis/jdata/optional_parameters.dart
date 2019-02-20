// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  new Class1(0);
  new Class1(0, 1);
  new Class2(0);
  new Class2(0, field2: 1);
}

class Class1 {
  var field1;
  var field2;
  var field3;

  Class1(this.field1, [this.field2 = 2, this.field3 = 3]);
}

class Class2 {
  var field1;
  var field2;
  var field3;

  Class2(this.field1, {this.field2 = 2, this.field3 = 3});
}
