// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int get value => 42;

extension Ext on int {
  int plus1() => this + 1;
}

extension Ext2 on int {
  int plus2() => this + 2;
}
