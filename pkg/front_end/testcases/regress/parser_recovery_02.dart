// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo() {
  if(true)
    final <int> f = [42];
}

bar() {
  if(true)
    var y = a<int, void>?.c = 42;
}
