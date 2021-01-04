// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "const_constructor_coverage_lib2.dart";

class Foo {
  final Bar bar;
  const /*x*/ Foo() : bar = const Bar();
  const /*x*/ Foo.named1() : bar = const Bar.named1();
  const /*x*/ Foo.named2() : bar = const Bar.named1();
  const /*x*/ Foo.named3() : bar = const Bar.named1();
}

class Bar {
  final Baz baz;
  const /*x*/ Bar() : baz = const Baz();
  const /*x*/ Bar.named1() : baz = const Baz.named1();
  const /*x*/ Bar.named2() : baz = const Baz.named1();
  const /*x*/ Bar.named3() : baz = const Baz.named1();
  const Bar.named4(int i)
      : baz = i > 0 ? const Baz.named5() : const Baz.named6();
}

const Foo foo = const Foo.named3();

// This file in itself should mark the following as const-constructor-covered:
// * "Bar", "Bar.named1", "Baz", "Baz.named1", "Baz.named5" and "Baz.named6"
//   from evaluating field initializers (done unconditionally).
// * "Foo.named3" from constant-evaluating the const field.
