// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo() {
  for(int i = 0; i < 10; i++)
    final <int> f = [42];
}

bar() {
  for(int i = 0; i < 10; i++)
    var y = a<int, void>?.c = 42;
}
