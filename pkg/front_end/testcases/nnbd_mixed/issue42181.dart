// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue42181_lib.dart';

int? f1(int x) => x;

void test() {
  F f = null; // Static error
  f = f1; // No error
}

main() {}
