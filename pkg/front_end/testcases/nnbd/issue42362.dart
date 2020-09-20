// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int i;

  A.constructor1([this.i]); // error

  A.constructor2({this.i}); // error

  A.constructor3([int i]) // error
      : this.i = i; // ok

  A.constructor4({int i}) // error
      : this.i = i; // ok

  A.constructor5([int? i]) // ok
      : this.i = i; // error

  A.constructor6({int? i}) // ok
      : this.i = i; // error

  A.constructor7({required int i}) // ok
      : this.i = i; // ok

  external A.constructor8([int i]); // ok

  external A.constructor9({int i}); // ok

  factory A.factory3([int i]) = A.constructor3; // ok

  factory A.factory4({int i}) = A.constructor4; // ok

  factory A.factory5([int? i]) = A.constructor5; // ok

  factory A.factory6({int? i}) = A.constructor6; // ok

  factory A.factory7({required int i}) = A.constructor7; // ok

  factory A.factory8([int i]) => new A.constructor3(); // error

  factory A.factory9({int i}) => new A.constructor4(); // error

  method3([int i]) {} // error

  method4({int i}) {} // error

  method5([int? i]) {} // ok

  method6({int? i}) {} // ok

  method7({required int i}) {} // ok

  external method8([int i]); // ok

  external method9({int i}); // ok
}

abstract class B {
  var i = 42;

  method3([int i]); // ok

  method4({int i}); // ok

  method5([int? i]); // ok

  method6({int? i}); // ok

  method7({required int i}); // ok
}

class C implements B {
  var i;

  C.constructor1([this.i]); // error

  C.constructor2({this.i}); // error

  C.constructor3([int i]) : this.i = i; // error

  C.constructor4({int i}) : this.i = i; // error

  C.constructor5([int? i]) : this.i = i; // error

  C.constructor6({int? i}) : this.i = i; // error

  C.constructor7({required int i}) // ok
      : this.i = i; // ok

  factory C.factory3([int i]) = C.constructor3; // ok

  factory C.factory4({int i}) = C.constructor4; // ok

  factory C.factory5([int? i]) = C.constructor5; // ok

  factory C.factory6({int? i}) = C.constructor6; // ok

  factory C.factory7({required int i}) = C.constructor7; // ok

  factory C.factory8([int i]) => new C.constructor3(); // error

  factory C.factory9({int i}) => new C.constructor4(); // error

  method3([i]) {} // error

  method4({i}) {} // error

  method5([i]) {} // ok

  method6({i}) {} // ok

  method7({required i}) {} // ok
}

void main() {}
