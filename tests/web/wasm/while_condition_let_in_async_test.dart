// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() async {
  var x, i = 0;

  while (i++ < 5) {
    x ??= 0;
    x++;
  }
}
