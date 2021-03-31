// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Type? _capturedTypeArgument;

X captureTypeArgument<X>() {
  _capturedTypeArgument = X;
  print("X: $X");
  throw "Error";
}

class A<X extends A<X>> {}
typedef C<X extends A<X>> = A<X>;

void topLevel1<X extends A<X>>(A<X> Function() g) => g();

void topLevel2<X extends C<X>>(C<X> Function() g) => g();

class Class {
  void instance1<X extends A<X>>(A<X> Function() g) => g();

  void instance2<X extends C<X>>(C<X> Function() g) => g();

  void test() {
    void local1<X extends A<X>>(A<X> Function() g) => g();
    void local2<X extends C<X>>(C<X> Function() g) => g();

    var f1 = local1;
    var f2 = local2;

    new A();
    new C();
    f1(() => captureTypeArgument());
    f2(() => captureTypeArgument());
    local1(() => captureTypeArgument());
    local2(() => captureTypeArgument());
    topLevel1(() => captureTypeArgument());
    topLevel2(() => captureTypeArgument());
    instance1(() => captureTypeArgument());
    instance2(() => captureTypeArgument());
  }
}

class Subclass extends Class {
  void test() {
    super.instance1(() => captureTypeArgument());
    super.instance2(() => captureTypeArgument());
  }
}

main() {}