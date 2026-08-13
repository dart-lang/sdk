// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

error() {
  for (late int i = 0; i < 10; ++i) {
    print(i);
  }
  for (late int i in <int>[]) {
    print(i);
  }
}

main() {}
