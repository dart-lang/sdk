// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  Super._();
}

class Sub extends Super {
  Sub() : super();
  Sub.foo() : super.foo();
}

class Bad {
  Bad.foo() : this();
  Bad.bar() : this.baz();
}

class M {}

class MixinApplication extends Super with M {
  MixinApplication() : super();
  MixinApplication.foo() : super.foo();
}

main() {}
