// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.
// @dart=2.9
x.y = 42;
x.z = true;
void foo() {
  if (x != null) {}
  if (null != x) {}
}

main() {}
