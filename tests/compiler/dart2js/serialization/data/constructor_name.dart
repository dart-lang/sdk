// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Class1 {
  var foo;
  Class1.foo();
}

// TODO(johnniwinther): Uncomment this when #34965 is fixed:
//class Class2 {
//  var bar;
//  factory Class2.bar() => null;
//}

main() {
  new Class1.foo().foo;
  //new Class2.bar().bar;
}
