// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E<X>(X it) {}

typedef F<Y> = E<Y>;

test(Function(F<int>) f1, Function(int) f2) => [f1, f2];
