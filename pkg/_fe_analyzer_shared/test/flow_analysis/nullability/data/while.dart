// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void eqNull(int? x) {
  while (x == null) {
    x;
  }
  /*nonNullable*/
  x;
}

void notEqNull(int? x) {
  while (x != null) {
    /*nonNullable*/
    x;
  }
  x;
}
