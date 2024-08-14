// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void foo() {
  var x = <int>[1, 2, 3]; // OK
  var y = <int, int>[1, 2, 3]; // Error
}