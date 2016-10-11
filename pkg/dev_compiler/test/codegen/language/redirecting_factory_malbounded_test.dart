// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> extends Bar<T> {

  factory Foo() = Bar;

  Foo.create() : super.create() { }
}

class Bar<T
            extends num  /// 01: static type warning, dynamic type error
                       > {
  factory Bar() {
    return new Foo<T>.create();
  }

  Bar.create() { }
}

main() {
  new Foo<String>();
}
