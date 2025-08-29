// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class ClassWithCall {
  ClassWithCall call();
  int method();
}

class Class {
  ClassWithCall get classWithCall => /*Never*/ throw /*int!*/ 42;

  int method() =>
      /*ClassWithCall!*/
      classWithCall
          /*invoke: ClassWithCall!*/
          ()
          . /*invoke: int!*/ method();
}

abstract class GenericClassWithCall<T> {
  T call();
  T method();
}

class GenericClass<S, T extends GenericClassWithCall<S>> {
  GenericClassWithCall<T> get classWithCall => /*Never*/ throw /*int!*/ 42;

  S method() =>
      /*GenericClassWithCall<T!>!*/
      classWithCall /*invoke: T!*/ (). /*invoke: S%*/ method();
}

main() {
  new /*GenericClass<String!,GenericClassWithCall<String!>!>!*/ GenericClass<
        String,
        GenericClassWithCall<String>
      >
      /*<String!,GenericClassWithCall<String!>!>*/
      ()
      . /*GenericClassWithCall<GenericClassWithCall<String!>!>!*/ classWithCall
      /*invoke: GenericClassWithCall<String!>!*/
      ()
      . /*invoke: String!*/ method();
}
