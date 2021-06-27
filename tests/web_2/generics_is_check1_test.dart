// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class Hest<X> {}

main() {
  var x = new Hest<int>();
  Expect.isTrue(x is Hest<int>);
  Expect.isFalse(x is Hest<String>);
}
