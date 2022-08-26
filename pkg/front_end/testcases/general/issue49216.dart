// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E {
  foo;

  const E([int x = 0, String y = "", num? z]);
  const E.named(int x, {String y = "", bool b = false, String? z, bool? t});
}

main() {}
