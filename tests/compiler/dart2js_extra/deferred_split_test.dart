// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression for issue 23853: we used to incorrectly split and put a type in a
/// deferred hunk if the type was used explicitly in the deferred library and
/// was used only in a generic type in the main library.
library compiler.test.dart2js_extra.deferred_split_test;

import 'deferred_split_lib1.dart';
import 'deferred_split_lib2.dart' deferred as b;

class TypeLiteral<T> {
  Type get type => T;
}

main() {
  // This line failed with a runtime error prior to the fix:
  new TypeLiteral<A<Object>>().type;

  b.loadLibrary().then((_) => b.createA());
}
