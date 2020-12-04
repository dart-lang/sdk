// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "const_constructor_coverage_lib1.dart";

class Baz {
  final Bar bar;
  const /*x*/ Baz() : bar = null;
  const /*x*/ Baz.named1() : bar = null;
  const Baz.named2() : bar = null;
  const Baz.named3() : bar = const Bar.named3();
  const /*x*/ Baz.named4() : bar = null;
  const /*x*/ Baz.named5() : bar = null;
  const /*x*/ Baz.named6() : bar = null;
}

const Baz baz = const Baz.named4();
const Foo foo = const Foo.named2();
const Bar bar = const Bar.named2();

// This file in itself should mark the following as const-constructor-covered:
// * "Bar.named3" from evaluating field initializers (done unconditionally).
// * "Baz.named4", "Foo.named2" and "Bar.named2" from constant-evaluating the
//   const fields.
