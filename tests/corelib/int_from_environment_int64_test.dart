// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Df=-9223372036854775808 -Dg=9223372036854775807

import "package:expect/expect.dart";

main() {
  Expect.equals(-9223372036854775808, const int.fromEnvironment('f'));
  Expect.equals(9223372036854775807, const int.fromEnvironment('g'));
}
