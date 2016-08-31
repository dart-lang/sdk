// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
    const a = 1;
    Expect.equals(1, a);
    Expect.equals(1, const A(a).a);
    Expect.equals(1, const [const A(a)][0].a);
}

class A {
    final a;
    const A(this.a);
}
