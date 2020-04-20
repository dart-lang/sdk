// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

void f(Object x) {
  try {
    if (x is! String) return;
    x.length;
  } catch (_) {
    if (x is! String) return;
    x.length;
  }
  x.length;
}

void g() {}

void main() {}
