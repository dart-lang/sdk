// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class C {
  /*element: C.noSuchMethod:selectors=[Selector(call, foo, arity=0, types=2)]*/
  noSuchMethod(i) => i.typeArguments;
}

class D {
  /*element: D.foo:exp,needsArgs,selectors=[Selector(call, foo, arity=0, types=2)]*/
  foo<U, V>() => [U, V];
}

@NoInline()
test(dynamic x) {
  print(x.foo<int, String>());
}

main() {
  test(new C());
  test(new D());
}
