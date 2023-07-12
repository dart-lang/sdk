// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

double foo(List<double> l, [bool flag = false]) {
  return flag ? l[0] * l[0] : 0;
}

void main() {
  foo([1.0].toList(), true);
  foo(List<double>.filled(1, 0.0));
  foo([]);
}
