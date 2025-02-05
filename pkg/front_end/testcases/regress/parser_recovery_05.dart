// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo() {
  for(int x in [1, 2, 3])
    final <int> f = [42];
}

bar() {
  for(int x in [1, 2, 3])
    var y = a<int, void>?.c = 42;
}
