// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that malformed types used in extends, implements, and with clauses
// cause compile-time errors.

class A<T> {}

class C
    extends Unresolved
    //      ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.EXTENDS_NON_CLASS
    // [cfe] Type 'Unresolved' not found.
    {
}

class C1
    extends A<Unresolved>
    //        ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
    // [cfe] Type 'Unresolved' not found.
    {
}

class C2
//    ^
// [cfe] The type 'Unresolved' can't be mixed in.
    extends Object with Unresolved
    //                  ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
    // [cfe] Type 'Unresolved' not found.
    {
}

class C3
    extends Object with A<Unresolved>
    //                    ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
    // [cfe] Type 'Unresolved' not found.
    {
}

class C4
    implements Unresolved
    //         ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
    // [cfe] Type 'Unresolved' not found.
    {
}

class C5
    implements A<Unresolved>
    //           ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
    // [cfe] Type 'Unresolved' not found.
    {
}

class C6<A>
    extends A<int>
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.EXTENDS_NON_CLASS
    // [cfe] Can't use type arguments with type variable 'A'.
    //      ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
    {
}

class C7<A>
    extends A<Unresolved>
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.EXTENDS_NON_CLASS
    // [cfe] Can't use type arguments with type variable 'A'.
    //      ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
    //        ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
    // [cfe] Type 'Unresolved' not found.
    {
}

class C8<A>
//    ^
// [cfe] The type 'A<int>' can't be mixed in.
    extends Object with A<int>
    //                  ^
    // [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
    // [cfe] Can't use type arguments with type variable 'A'.
    //                  ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
    {
}

class C9<A>
//    ^
// [cfe] The type 'A<Unresolved>' can't be mixed in.
    extends Object with A<Unresolved>
    //                  ^
    // [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
    // [cfe] Can't use type arguments with type variable 'A'.
    //                  ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
    //                    ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
    // [cfe] Type 'Unresolved' not found.
    {
}

class C10<A>
    implements A<int>
    //         ^
    // [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
    // [cfe] Can't use type arguments with type variable 'A'.
    //         ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
    {
}

class C11<A>
    implements A<Unresolved>
    //         ^
    // [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_NON_CLASS
    // [cfe] Can't use type arguments with type variable 'A'.
    //         ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
    //           ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
    // [cfe] Type 'Unresolved' not found.
    {
}

void main() {
  new C();
  new C1();
  new C2();
  new C3();
  new C4();
  new C5();
  new C6<Object>();
  new C7<Object>();
  new C8<Object>();
  new C9<Object>();
  new C10<Object>();
  new C11<Object>();
}
