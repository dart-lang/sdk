// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(targets: "lib")
import "dart:mirrors";

import "package:expect/expect.dart";

typedef void FooFunction(int a, double b);

bar(int a) {}

main() {
  TypedefMirror tm = reflectType(FooFunction);
  FunctionTypeMirror ftm = tm.referent;
  Expect.equals(const Symbol('void'), ftm.returnType.simpleName);
  Expect.equals(#int, ftm.parameters[0].type.simpleName);
  Expect.equals(#double, ftm.parameters[1].type.simpleName);
  ClosureMirror cm = reflect(bar);
  ftm = cm.type;
  Expect.equals(#dynamic, ftm.returnType.simpleName);
  Expect.equals(#int, ftm.parameters[0].type.simpleName);
}
