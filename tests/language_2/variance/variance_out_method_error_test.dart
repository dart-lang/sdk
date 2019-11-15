// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous method signatures and return types for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

typedef Inv<T> = void Function<X extends T>();
typedef Cov<T> = T Function();
typedef Contra<T> = void Function(T);

class Covariant<out T> {}
class Contravariant<in T> {}
class Invariant<inout T> {}

class A<out T> {
  void method1(T x) {}
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //             ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method2(Cov<T> x) {}
  //           ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                  ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Contra<T> method3() => (T val) {};
//^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //               ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  void method4(Cov<Cov<T>> x) {}
  //           ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                       ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Contra<Cov<T>> method5() => (Cov<T> method) {};
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                    ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  Cov<Contra<T>> method6() {
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                    ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.
    return () {
      return (T x) {};
    };
  }

  void method7(Contra<Contra<T>> x) {}
  //           ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                             ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Inv<T> method8() => null;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //            ^
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position in the return type.

  void method9(Inv<T> x) {}
  //           ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                  ^
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  Contravariant<T> method10() => null;
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                       ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  void method11(Covariant<T> x) {}
  //            ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                         ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Invariant<T> method12() => null;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                   ^
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position in the return type.

  void method13(Invariant<T> x) {}
  //            ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                         ^
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method14(Covariant<Covariant<T>> x) {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                    ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method15(Contravariant<Contravariant<T>> x) {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                            ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Contravariant<Covariant<T>> method16() => Contravariant<Covariant<T>>();
//^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                  ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  Covariant<Contravariant<T>> method17() => Covariant<Contravariant<T>>();
//^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                  ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  void method18<X extends Contra<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method19<X extends Contravariant<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method20({T x}) {}
  //             ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //               ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method21({Cov<T> x}) {}
  //             ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                    ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method22({Covariant<T> x}) {}
  //             ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                          ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method23({Covariant<T> x, Contravariant<T> y}) {}
  //             ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                          ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method24<X extends T>() {}
  //            ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method25<X extends Contra<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method26<X extends Contravariant<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.
}

mixin BMixin<out T> {
  void method1(T x) {}
  //           ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //             ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method2(Cov<T> x) {}
  //           ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                  ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Contra<T> method3() => (T val) {};
//^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //               ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  void method4(Cov<Cov<T>> x) {}
  //           ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                       ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Contra<Cov<T>> method5() => (Cov<T> method) {};
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                    ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  Cov<Contra<T>> method6() {
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                    ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.
    return () {
      return (T x) {};
    };
  }

  void method7(Contra<Contra<T>> x) {}
  //           ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                             ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Inv<T> method8() => null;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //            ^
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position in the return type.

  void method9(Inv<T> x) {}
  //           ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                  ^
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  Contravariant<T> method10() => null;
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                       ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  void method11(Covariant<T> x) {}
  //            ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                         ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Invariant<T> method12() => null;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                   ^
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position in the return type.

  void method13(Invariant<T> x) {}
  //            ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                         ^
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method14(Covariant<Covariant<T>> x) {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                    ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method15(Contravariant<Contravariant<T>> x) {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                            ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  Contravariant<Covariant<T>> method16() => Contravariant<Covariant<T>>();
//^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                  ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  Covariant<Contravariant<T>> method17() => Covariant<Contravariant<T>>();
//^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                                  ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.

  void method18<X extends Contra<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method19<X extends Contravariant<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method20({T x}) {}
  //             ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //               ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method21({Cov<T> x}) {}
  //             ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                    ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method22({Covariant<T> x}) {}
  //             ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                          ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method23({Covariant<T> x, Contravariant<T> y}) {}
  //             ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                          ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.

  void method24<X extends T>() {}
  //            ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method25<X extends Contra<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.

  void method26<X extends Contravariant<T>>() {}
  //            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  // [cfe] Can't use 'out' type variable 'T' in an 'inout' position.
}

class B<out T> {
  void method1(Cov<A<T>> x) {}
  //           ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                     ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
  Contra<A<T>> method2() {
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //                  ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position in the return type.
    return null;
  }
}

class C<T> {
  void method(T x) {}
}

class D<out T> extends C<T> {
  @override
  void method(T x) {}
  //          ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_TYPE_PARAMETER_VARIANCE_POSITION
  //            ^
  // [cfe] Can't use 'out' type variable 'T' in an 'in' position.
}
