// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int getter = 42;
int setter = 42;

extension on int {
  get getter => 42;
  set setter(_) {}

  method() {
    getter = getter;
    setter = setter;
  }
}
