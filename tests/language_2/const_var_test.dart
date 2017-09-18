// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// All things regarding constant variables.

library const_var;

import 'const_var_helper.dart' as foo;

const untypedTopLevel = 1;
const int typedTopLevel = 2;
const Map<String, String> genericTopLevel = const <String, String>{};

main() {
  const untypedLocal = 3;
  const int typedLocal = 4;
  const Map<String, String> genericLocal = const <String, String>{};
  const [];
  const {};
  const <int>[];
  const <String, int>{};
  const Foo();
  const Foo<int>();
  const foo.Foo();
  const foo.Foo<int>();
}

class Foo<E> {
  const Foo();
}
