// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that [Finalizer.attach] throws if object and token are the same object
// when assertions are enabled.

import 'package:expect/expect.dart';

void main() {
  assert(() {
    final finalizer = Finalizer((_) {});
    final o = Object();
    Expect.throws(() => finalizer.attach(o, o), (e) => e is AssertionError);
    return true;
  }());
}
