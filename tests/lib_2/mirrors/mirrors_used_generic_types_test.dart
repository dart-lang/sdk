// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library Test;

@MirrorsUsed(targets: const ["Test"])
import 'dart:mirrors';
import 'dart:async';

import 'package:expect/expect.dart';

class A {
  // Because of the `mirrors-used` annotation, the types `List` and `Future`
  // are not reflectable.
  // However, we still need to be able to create a Mirror for them, when we
  // create a mirror for `foo`. In particular, it must be able to create a
  // mirror, even though there are generic types.
  List<int> foo(Future<int> x) {
    return null;
  }
}

void main() {
  var m = reflect(new A()).type.instanceMembers[#foo];
  Expect.equals(#List, m.returnType.simpleName);
  Expect.equals(#Future, m.parameters[0].type.simpleName);
}
