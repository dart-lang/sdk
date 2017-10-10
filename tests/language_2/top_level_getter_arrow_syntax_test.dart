// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

get getter => 42;

List<int> get lgetter => null;

bool get two_wrongs {
  return !true;
}

main() {
  Expect.equals(42, getter);
  Expect.equals(null, lgetter);
  Expect.equals(false, two_wrongs);
}
