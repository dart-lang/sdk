// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

enum E { A }

main() {
  Expect.isTrue(E.values == const <E>[E.A]);
  Expect.isTrue(E.values == const [E.A]);
}
