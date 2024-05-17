// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests multiple local wildcard variable declarations.

// SharedOptions=--enable-experiment=wildcard-variables

void main() {
  var _ = 1;
  int _ = 2;
  final _ = 3;

  var i = 2, _ = 2;
  i = i + 1;

  int _;
  final _;
}
