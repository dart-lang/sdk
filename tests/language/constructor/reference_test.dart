// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<X> {
  const Foo();
  const Foo.bar();
  const Foo.baz();
}

main() {
  new Foo();
  new Foo.bar();
  new Foo.bar.baz();
  //  ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  //          ^
  // [cfe] Method not found: 'Foo.bar.baz'.
  new Foo<int>();
  new Foo<int>.bar();
  new Foo<int>.bar.baz();
  //           ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected '(' after this.
  //               ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'baz' isn't defined for the class 'Foo<int>'.
  new Foo.bar<int>();
  //      ^
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
  //         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  new Foo.bar<int>.baz();
  //      ^
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
  //  ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  //               ^
  // [cfe] Method not found: 'Foo.bar.baz'.
  new Foo.bar.baz<int>();
  //  ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  //          ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
  //          ^
  // [cfe] Method not found: 'Foo.bar.baz'.

  const Foo();
  const Foo.bar();
  const Foo.bar.baz();
  //    ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  //            ^
  // [cfe] Method not found: 'Foo.bar.baz'.
  const Foo<int>();
  const Foo<int>.bar();
  const Foo<int>.bar.baz();
  //             ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected '(' after this.
  //                 ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'baz' isn't defined for the class 'Foo<int>'.
  const Foo.bar<int>();
  //        ^
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
  //           ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  const Foo.bar<int>.baz();
  //        ^
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
  //    ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  //                 ^
  // [cfe] Method not found: 'Foo.bar.baz'.
  const Foo.bar.baz<int>();
  //    ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
  //            ^
  // [cfe] Method not found: 'Foo.bar.baz'.

  Foo();
  Foo.bar();
  Foo.bar.baz();
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] Getter not found: 'bar'.
  Foo<int>();
  Foo<int>.bar();
  Foo<int>.bar.baz();
  //       ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected '(' after this.
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'baz' isn't defined for the class 'Foo<int>'.
  Foo.bar<int>();
  //  ^
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  Foo.bar<int>.baz();
  //  ^
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  //           ^
  // [cfe] Method not found: 'Foo.bar.baz'.
  Foo.bar.baz<int>();
  //  ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] Getter not found: 'bar'.
}
