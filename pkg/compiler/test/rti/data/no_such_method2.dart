// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

class C {
  /*member: C.noSuchMethod:needsArgs,selectors=[Selector(call, call, arity=0, types=2),Selector(call, foo, arity=0, types=2)]*/
  noSuchMethod(i) => i.typeArguments;
}

class D {
  /*member: D.foo:exp,needsArgs,selectors=[Selector(call, foo, arity=0, types=2)]*/
  foo<U, V>() => [U, V];
}

@pragma('dart2js:noInline')
test(dynamic x) {
  makeLive(x.foo<int, String>());
}

main() {
  test(new C());
  test(new D());
}
