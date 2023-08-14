// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that JS number subtyping semantics are respected for numbers nested in
// const-like record literals.

import 'package:expect/expect.dart';

@pragma('dart2js:never-inline')
bool test<T>(dynamic x) => x is T;

void main() {
  Expect.isTrue(1 is double);
  Expect.isTrue(test<double>(1));

  Expect.isTrue((1,) is (double,));
  Expect.isTrue(test<(double,)>((1,)));
}
