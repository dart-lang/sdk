// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class X {
  final int obj;
  X() : obj = 0;
  X.named() : obj = 0;
}

void main() {
  print((X.new)().obj);
  print((X.named)().obj);
}
