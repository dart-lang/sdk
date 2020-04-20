// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

void f(bool b, Object x) {
  b ? ((x is String) || (throw 1)) : ((x is String) || (throw 2));
  x.length;
}

void main() {}
