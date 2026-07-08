// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=covarianceCheckMain
// functionFilter=as Callable
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=-O0

class Callable<U> {}

class Fields<T> {
  final Callable<void Function(T)> contravariantUse =
      Callable<void Function(T)>();
}

void main() {
  covarianceCheckMain();
}

void covarianceCheckMain() {
  Fields<num> fields = Fields<int>();
  // This getter access statically returns Callable<void Function(num)>,
  // but at runtime returns Callable<void Function(int)>.
  // This triggers a covariance check (AsExpression) on the return value.
  fields.contravariantUse;
}
