// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import "package:expect/expect.dart";

Type? capturedTypeArgument;
Type typeOf<X>() => X;

X captureTypeArgument<X>() {
  capturedTypeArgument = X;
  throw "";
}

typedef check = void Function<T>();

void main() {
  void f(check Function<T>() g) => g();
  try {
    f(<T>() => captureTypeArgument());
  } catch (e) {}
  Expect.equals(typeOf<void Function<T>()>(), capturedTypeArgument);
}
