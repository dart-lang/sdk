// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
}
class Class2 {}

extension DuplicateExtensionName on Class1 {
  uniqueMethod1() {}
  duplicateMethodName2() => 1;
}

extension DuplicateExtensionName on Class2 {
  uniqueMethod2() {}
  duplicateMethodName2() => 2;
}

extension UniqueExtensionName on Class1 {
  duplicateMethodName1() => 1;
  duplicateMethodName1() => 2;
}

main() {
  var c1 = new Class1();
  c1.uniqueMethod1();
}

errors() {
  var c2 = new Class2();
  c2.uniqueMethod2();
}