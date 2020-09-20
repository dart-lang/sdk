// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "data:,var%20x=#_a._b;var%20y=#a._b;var%20z=#_b;";

main() {
  print(x);
  print(x == #_a._b);
  print(y);
  print(y == #a._b);
  print(z);
  print(z == #_b);
}
