// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void foo([int _]) {}

void main() {
  void bar([int _]) {}
  void bar1([int _, int _]) {}
  void bar2([int _, int _ = 2]) {}
  void bar3([int _ = 2, int _]) {}
  void bar4([int x = 2, int? _, int _]) {}
}
