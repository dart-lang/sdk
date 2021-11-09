// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that typeinference on arguments continues working after their order is
// changed.

// SharedOptions=--enable-experiment=named-arguments-anywhere

import "package:expect/expect.dart";

Type? argument = null;

void registerTypeArgument<X>() {
  argument = X;
}

void runAndCheckForTypeArgument(Type expectedArgument, void Function() functionToRun) {
  argument = null;
  functionToRun();
  Expect.equals(expectedArgument, argument);
}

class BGeneric<X> {
  const BGeneric();
}

void fooGeneric<X>(BGeneric<X> x, {required BGeneric<List<X>> y}) {
  registerTypeArgument<X>();
}

void fooFunction(int x, {required double Function(double) y}) {
  y(3.14);
}

X bar<X>(X x) {
  registerTypeArgument<X>();
  return x;
}

void fooFunctionGeneric<X>(int x, {required void Function(X) y}) {
  registerTypeArgument<X>();
}

void main() {
  runAndCheckForTypeArgument(dynamic, () {
      fooGeneric(const BGeneric(), y: const BGeneric());
  });
  runAndCheckForTypeArgument(dynamic, () {
      fooGeneric(y: const BGeneric(), const BGeneric());
  });
  runAndCheckForTypeArgument(int, () {
      fooGeneric(const BGeneric<int>(), y: const BGeneric<List<int>>());
  });
  runAndCheckForTypeArgument(String, () {
      fooGeneric(y: const BGeneric<List<String>>(), const BGeneric<String>());
  });

  runAndCheckForTypeArgument(double, () {
      fooFunction(42, y: bar);
  });
  runAndCheckForTypeArgument(double, () {
      fooFunction(y: bar, 42);
  });

  runAndCheckForTypeArgument(String, () {
      fooFunctionGeneric(42, y: (String x) {});
  });
  runAndCheckForTypeArgument(num, () {
      fooFunctionGeneric(y: (num x) {}, 42);
  });
}
