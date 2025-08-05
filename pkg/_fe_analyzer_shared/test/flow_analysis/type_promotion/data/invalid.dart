// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method1(Unresolved? o) {
  int? a = o.foo;
  a;
}

method2(Unresolved? o) {
  int? a;
  a;
  a = o.foo;
  a;
}
