// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

main() {
  int c = new DateTime.now().millisecondsSinceEpoch;
  for (int i = 0; i < 100; i++) {
    print(i++);
  }
  for (int i = 0; i < 100; c < 42 ? throw "fisk" : i++) {
    print(i++);
  }
}
