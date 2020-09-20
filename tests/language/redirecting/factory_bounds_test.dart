// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Bounds checking on redirecting factories.

class Foo<T> {}

class Baz<T> {}

class Foobar<T> implements Foo<T> {}

class Bar<
          T // A comment to prevent dartfmt from joining the lines.
          extends Foo<T>      //# 00: ok
          extends Baz<Foo<T>> //# 01: compile-time error
          extends Foobar<T>   //# 02: compile-time error
  > {
  Bar.named();
  factory Bar() = Qux<T>;
}

class Qux<
          T // A comment to prevent dartfmt from joining the lines.
          extends Foo<T> //# 00: continued
          extends Foo<T> //# 01: continued
          extends Foo<T> //# 02: continued
         > extends Bar<T> {
  Qux() : super.named();
}



class A<T extends int> {
  factory A() = B<
                  T // A comment to prevent dartfmt from joining the lines.
                  , int //# 03: compile-time error
                  , String //# 04: ok
                 >;
}

class B<T extends int
        , S extends String //# 03: continued
        , S extends String //# 04: continued
       > implements A<T> {}

void main() {
  new Bar<Never>();
  new A<int>();
}
