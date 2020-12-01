// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "const_constructor_coverage_lib1.dart";
import "const_constructor_coverage_lib2.dart";

const Foo foo1 = const Foo();
const Foo foo2 = const Foo.named1();
const Foo foo3 = const Foo.named2();
const Foo foo4 = const Foo.named3();

main() {
  print(foo1);
}

// This file in itself should mark the following as const-constructor-covered:
// * "Foo", "Foo.named1", "Foo.named2" and "Foo.named3" from constant-evaluating
//   the const fields.

// Notice, that combined these 3 files should have coverage for:
// * "Foo", "Foo.named1", "Foo.named2", "Foo.named3",
// * "Bar", "Bar.named1", "Bar.named2", "Bar.named3",
// * "Baz", "Baz.named1", "Baz.named4", "Baz.named5", "Baz.named6"
// but NOT have any coverage for
// * "Bar.named4",
// * "Baz.named2" and "Baz.named3".