// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "get_source_report_const_coverage_test.dart";

void testFunction() {
  const namedFoo = Foo.named3();
  const namedFoo2 = Foo.named3();
  const namedIdentical = identical(namedFoo, namedFoo2);
  print("namedIdentical: $namedIdentical");
}
