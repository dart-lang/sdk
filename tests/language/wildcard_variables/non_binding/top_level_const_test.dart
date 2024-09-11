// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that top-level const variables are still binding.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

const _ = 100;

void main() {
  var _ = 1;
  int _ = 2;
  final _ = 3;
  late int _ = 4;
  const int _ = 5;

  Expect.equals(100, _);
}
