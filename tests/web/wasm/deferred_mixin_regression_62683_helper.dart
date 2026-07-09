// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '' deferred as D;

mixin FooMixin {
  Future<void> init() => D.loadLibrary();
  void access() => foo();
}

void foo() => print('foo');
