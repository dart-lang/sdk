// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  int operator [](int index) => index;
  void operator []=(int index, int value) {}
}

main() {
  Class1? c1;
  c1?.[0];
  c1?.[0] = 1;

  c1?[0];
  c1?[0] = 1;

  c1 ? [0];
  c1 ? [0] = 1;
}
