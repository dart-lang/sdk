// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var l = [];
  l.add(1);
  Expect.equals(1, l.length);
  Expect.equals(1, l[0]);
}
