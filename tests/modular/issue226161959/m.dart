// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  String foo() => 'A';
}

mixin M on A {
  @override
  String foo() => 'M' + super.foo();
}
