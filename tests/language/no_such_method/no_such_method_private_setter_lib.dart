// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bar {
  int _x = -1;
}

void baz(Bar bar) {
  (bar as dynamic)._x = "Sixtyfour"; //# 01: runtime error
}
