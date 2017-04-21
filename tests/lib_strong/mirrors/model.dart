// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.model;

var accessorA;

var accessorB;

var accessorC;

var fieldC;

class A {
  var field;
  instanceMethod(x) => 'A:instanceMethod($x)';
  get accessor => 'A:get accessor';
  set accessor(x) {
    accessorA = x;
  }

  aMethod() => 'aMethod';
}

class B extends A {
  get field => 'B:get field';
  instanceMethod(x) => 'B:instanceMethod($x)';
  get accessor => 'B:get accessor';
  set accessor(x) {
    accessorB = x;
  }

  bMethod() => 'bMethod';
}

class C extends B {
  set field(x) {
    fieldC = x;
  }

  instanceMethod(x) => 'C:instanceMethod($x)';
  get accessor => 'C:get accessor';
  set accessor(x) {
    accessorC = x;
  }

  cMethod() => 'cMethod';
}
