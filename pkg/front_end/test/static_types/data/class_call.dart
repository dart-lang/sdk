// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe.library: nnbd=false*/
/*cfe:nnbd.library: nnbd=true*/

abstract class ClassWithCall {
  ClassWithCall call();
  int method();
}

class Class {
  ClassWithCall get classWithCall =>
      /*cfe.<bottom>*/ /*cfe:nnbd.Never*/
      throw /*cfe.int*/ /*cfe:nnbd.int!*/ 42;

  int method() =>
      /*cfe.ClassWithCall*/
      /*cfe:nnbd.ClassWithCall!*/
      classWithCall
              /*cfe.invoke: ClassWithCall*/
              /*cfe:nnbd.invoke: ClassWithCall!*/
              ()
          . /*cfe.invoke: int*/
          /*cfe:nnbd.invoke: int!*/
          method();
}

abstract class GenericClassWithCall<T> {
  T call();
  T method();
}

class GenericClass<S, T extends GenericClassWithCall<S>> {
  GenericClassWithCall<T> get classWithCall =>
      /*cfe.<bottom>*/ /*cfe:nnbd.Never*/
      throw /*cfe.int*/ /*cfe:nnbd.int!*/ 42;

  S method() =>
      /*cfe.GenericClassWithCall<T>*/
      /*cfe:nnbd.GenericClassWithCall<T!>!*/
      classWithCall /*cfe.invoke: T*/ /*cfe:nnbd.invoke: T!*/ ()
          . /*cfe.invoke: S*/ /*cfe:nnbd.invoke: S%*/ method();
}

main() {
  new /*cfe.GenericClass<String,GenericClassWithCall<String>>*/
      /*cfe:nnbd.GenericClass<String!,GenericClassWithCall<String!>!>!*/
      GenericClass<String, GenericClassWithCall<String>>
          /*cfe.<String,GenericClassWithCall<String>>*/
          /*cfe:nnbd.<String!,GenericClassWithCall<String!>!>*/ ()
      . /*cfe.GenericClassWithCall<GenericClassWithCall<String>>*/
      /*cfe:nnbd.GenericClassWithCall<GenericClassWithCall<String!>!>!*/
      classWithCall
      /*cfe.invoke: GenericClassWithCall<String>*/
      /*cfe:nnbd.invoke: GenericClassWithCall<String!>!*/
      ()
      . /*cfe.invoke: String*/ /*cfe:nnbd.invoke: String!*/ method();
}
