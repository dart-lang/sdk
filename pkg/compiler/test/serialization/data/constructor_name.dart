// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  var foo;
  Class1.foo();
}

class Class2 {
  var bar;
  factory Class2.bar() => Class2._();
  Class2._();
}

main() {
  Class1.foo().foo;
  Class2.bar().bar;
}
