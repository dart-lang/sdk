// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the greatest lower bound between two types is
// calculated correctly, in case one of them is a FutureOr.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/
import 'dart:async';

class Foo {}

// -----------------------------------------------------------------------------

// Tests rule GLB(FutureOr<A>, B) == GLB(A, B).
void func1<T extends Foo>(T t) {
  // Here and in the test cases below 'context' provides the typing context via
  // the type of its parameter.  The context is imposed onto the return type of
  // 'expr' that is a type-parameter type.  It leads to evaluation of GLB of the
  // typing context and the bound of the type parameter.  The computed GLB is
  // inserted as both the type argument and the return type of 'expr' by the
  // type inference.
  void context(FutureOr<T> x) {}
  S expr<S extends Foo>() =>
      /*cfe.<bottom>*/ /*cfe:nnbd.Never*/
      throw /*cfe.int*/ /*cfe:nnbd.int!*/ 42;

  // Type of the expression is GLB(FutureOr<T>, Foo) = T.
  /*invoke: void*/ context(
      /*cfe.invoke: T*/ /*cfe:nnbd.invoke: T!*/ expr
          /*cfe.<T>*/
          /*cfe:nnbd.<T!>*/ ());
}

// -----------------------------------------------------------------------------

// Tests rule GLB(FutureOr<A>, Future<B>) == Future<GLB(A, B)>.
void func2<T extends Foo>() {
  void context(FutureOr<T> x) {}
  S expr<S extends Future<Foo>>() =>
      /*cfe.<bottom>*/ /*cfe:nnbd.Never*/
      throw /*cfe.int*/ /*cfe:nnbd.int!*/ 42;

  // Type of the expression is GLB(FutureOr<T>, Future<Foo>) = Future<T>.
  /*invoke: void*/ context(
      /*cfe.invoke: Future<T>*/
      /*cfe:nnbd.invoke: Future<T!>!*/ expr
          /*cfe.<Future<T>>*/
          /*cfe:nnbd.<Future<T!>!>*/ ());
}

// -----------------------------------------------------------------------------

// Tests rule GLB(A, FutureOr<B>) == GLB(B, A).
void func3<T extends Foo>() {
  void context(T x) {}
  S expr<S extends FutureOr<Foo>>() =>
      /*cfe.<bottom>*/ /*cfe:nnbd.Never*/
      throw /*cfe.int*/ /*cfe:nnbd.int!*/ 42;

  // Type of the expression is GLB(T, FutureOr<Foo>) = T.
  /*invoke: void*/ context(
      /*cfe.invoke: T*/ /*cfe:nnbd.invoke: T!*/ expr
          /*cfe.<T>*/
          /*cfe:nnbd.<T!>*/ ());
}

// -----------------------------------------------------------------------------

// Tests rule GLB(Future<A>, FutureOr<B>) == Future<GLB(B, A)>.
void func4<T extends Foo>() {
  void context(Future<T> x) {}
  S expr<S extends FutureOr<Foo>>() =>
      /*cfe.<bottom>*/ /*cfe:nnbd.Never*/
      throw /*cfe.int*/ /*cfe:nnbd.int!*/ 42;

  // Type of the expression is GLB(Future<T>, FutureOr<Foo>) = Future<T>.
  /*invoke: void*/ context(
      /*cfe.invoke: Future<T>*/
      /*cfe:nnbd.invoke: Future<T!>!*/ expr
          /*cfe.<Future<T>>*/
          /*cfe:nnbd.<Future<T!>!>*/ ());
}

// -----------------------------------------------------------------------------

// Tests rule GLB(FutureOr<A>, FutureOr<B>) == FutureOr<GLB(A, B)> in the
// non-trivial case when neither A <: B, nor B <: A.
void func5<T extends Foo>() {
  void context(FutureOr<FutureOr<T>> x) {}
  S expr<S extends FutureOr<Future<Foo>>>() =>
      /*cfe.<bottom>*/ /*cfe:nnbd.Never*/
      throw /*cfe.int*/ /*cfe:nnbd.int!*/ 42;

  // Type of the expression is GLB(FutureOr<FutureOr<T>>, FutureOr<Future<Foo>>)
  // = FutureOr<Future<T>>.
  /*invoke: void*/ context(
      /*cfe.invoke: FutureOr<Future<T>>*/
      /*cfe:nnbd.invoke: FutureOr<Future<T!>!>!*/ expr
          /*cfe.<FutureOr<Future<T>>>*/
          /*cfe:nnbd.<FutureOr<Future<T!>!>!>*/ ());
}

// -----------------------------------------------------------------------------

main() {}
