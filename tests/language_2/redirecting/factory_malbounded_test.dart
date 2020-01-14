// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {
  factory Foo() = Bar<T>;
  //              ^
  // [cfe] The type 'T' doesn't extend 'num'.
  //                  ^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  Foo.create() {}
}

class Bar<
    T
            extends num
    > extends Foo<T> {
  factory Bar() {
    return new Bar<T>.create();
  }

  Bar.create() : super.create() {}
}

main() {
  new Foo<String>();
  //  ^
  // [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Bar'.
}
