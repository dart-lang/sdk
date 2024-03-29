// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  for (final value in [const [], const {}.values]) {
    final other = List.from(value);
    Expect.equals(other.length, value.length);
    for (final entry in value) {
      other.contains(entry);
    }
  }
}
