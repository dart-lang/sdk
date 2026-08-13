// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  var map = <String, dynamic>{"a": null};
  var castMap = map.cast<String, Object>();
  // Should return `null`, not throw.
  Expect.isNull(castMap.remove("b"));
  Expect.isNull(castMap.remove("a"));
}
