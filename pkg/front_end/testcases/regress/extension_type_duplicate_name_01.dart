// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int DuplicateName = 42;

extension type DuplicateName._(int _x) {
  DuplicateName(this._x) {
    bar;
  }
  int get bar => 42;
}
