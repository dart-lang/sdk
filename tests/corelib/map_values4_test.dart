// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart2js had a bug where the type information was not set correctly if the
// generic type of the map was not directly used (but only indirectly through
// map.values).

main() {
  var map1 = <int, String>{1: "42", 2: "499"};
  Expect.isTrue(map1.values is Iterable<String>);
  Expect.isFalse(map1.values is Iterable<bool>);
}
