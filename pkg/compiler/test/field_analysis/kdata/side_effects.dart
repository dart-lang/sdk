// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  new Class1();
}

method1() => 1;

class Class1 {
  var field1 = method1();
  var field2 = throw 'foo';
  var field3 = method1();

  Class1() : field3 = null;
}
