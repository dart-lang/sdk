// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous method signatures and return types for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

typedef Inv<T> = void Function<X extends T>();
typedef Cov<T> = T Function();
typedef Contra<T> = void Function(T);

class Covariant<out T> {}
class Contravariant<in T> {}
class Invariant<inout T> {}

class A<in T> {
  // TODO (kallentu): Come NNBD, change `T` to `T?`
  T method1() => null;
//^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //       ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  void method2(Contra<T> x) {}
  //           ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                     ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  Cov<T> method3() {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //            ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.
    return () => null;
  }

  void method4(Contra<Cov<T>> x) {}
  //           ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                          ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method5(Cov<Contra<T>> x) {}
  //           ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                          ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  Contra<Contra<T>> method6() => (Contra<T> x) {};
//^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                       ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  Cov<Cov<T>> method7() {
//^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                 ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.
    return () {
      return () => null;
    };
  }

  Inv<T> method8() => null;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //            ^
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position in the return type.

  void method9(Inv<T> x) {}
  //           ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                  ^
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  Covariant<T> method10() => null;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                   ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  void method11(Contravariant<T> x) {}
  //            ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                             ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  Invariant<T> method12() => null;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                   ^
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position in the return type.

  void method13(Invariant<T> x) {}
  //            ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                         ^
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method14(Contravariant<Covariant<T>> x) {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                        ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method15(Covariant<Contravariant<T>> x) {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                        ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  Contravariant<Contravariant<T>> method16() => Contravariant<Contravariant<T>>();
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                      ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  Covariant<Covariant<T>> method17() => Covariant<Covariant<T>>();
//^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                              ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  void method18<X extends T>() {}
  //            ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method19<X extends Cov<T>>() {}
  //            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method20<X extends Covariant<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method21({Contra<T> x}) {}
  //             ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                       ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method22({Contravariant<T> x}) {}
  //             ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                              ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method23({Covariant<T> x, Contravariant<T> y}) {}
  //                             ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                              ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method24<X extends Contra<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method25<X extends Contravariant<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.
}

mixin BMixin<in T> {
  // TODO (kallentu): Come NNBD, change `T` to `T?`
  T method1() => null;
//^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //       ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  void method2(Contra<T> x) {}
  //           ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                     ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  Cov<T> method3() {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //            ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.
    return () => null;
  }

  void method4(Contra<Cov<T>> x) {}
  //           ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                          ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method5(Cov<Contra<T>> x) {}
  //           ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                          ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  Contra<Contra<T>> method6() => (Contra<T> x) {};
//^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                       ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  Cov<Cov<T>> method7() {
//^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                 ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.
    return () {
      return () => null;
    };
  }

  Inv<T> method8() => null;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //            ^
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position in the return type.

  void method9(Inv<T> x) {}
  //           ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                  ^
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  Covariant<T> method10() => null;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                   ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  void method11(Contravariant<T> x) {}
  //            ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                             ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  Invariant<T> method12() => null;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                   ^
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position in the return type.

  void method13(Invariant<T> x) {}
  //            ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                         ^
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method14(Contravariant<Covariant<T>> x) {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                        ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method15(Covariant<Contravariant<T>> x) {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                        ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  Contravariant<Contravariant<T>> method16() => Contravariant<Contravariant<T>>();
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                      ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  Covariant<Covariant<T>> method17() => Covariant<Covariant<T>>();
//^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                              ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.

  void method18<X extends T>() {}
  //            ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method19<X extends Cov<T>>() {}
  //            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method20<X extends Covariant<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method21({Contra<T> x}) {}
  //             ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                       ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method22({Contravariant<T> x}) {}
  //             ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                              ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method23({Covariant<T> x, Contravariant<T> y}) {}
  //                             ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                              ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.

  void method24<X extends Contra<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.

  void method25<X extends Contravariant<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'in' type variable 'T' in an 'inout' position.
}

class B<in T> {
  void method1(A<T> x) {}
  //           ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.
  Contra<A<T>> method2() {
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                  ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position in the return type.
    return null;
  }
}

class C<T> {
  void method(T x) {}
}

class D<in T> extends C<void Function(T)> {
  @override
  void method(void Function(T) x) {}
  //          ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                           ^
  // [cfe] Can't use 'in' type variable 'T' in an 'out' position.
}
