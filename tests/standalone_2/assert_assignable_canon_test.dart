// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable-inlining-annotations --optimization-counter-threshold=10 --no-background-compilation

const AlwaysInline = "AlwaysInline";
const NeverInline = "NeverInline";

abstract class A<T extends A<T>> {
  @AlwaysInline
  f(x) => new R<T>(x);
}

class B extends A<B> {}

class R<T> {
  @AlwaysInline
  R(T field);
}

class C extends B {}

class D extends C {}

// f will be inlined and T=B will be forwarded to AssertAssignable in the
// R. However B will be wrapped in the TypeRef which breaks runtime TypeCheck
// function (Instance::IsInstanceOf does not work for TypeRefs).
@NeverInline
f(o) => new B().f(o);

main() {
  final o = new D();
  for (var i = 0; i < 10; i++) {
    f(o);
  }
}
