// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that typechecks on const objects with typedefs work.

import "package:expect/expect.dart";

typedef String Int2String(int x);

class A {
  final Int2String f;
  const A(this.f);
}

String foo(int x) => "str";

const a = const A(foo);

main() {
  Expect.equals("str", a.f(499));
}
