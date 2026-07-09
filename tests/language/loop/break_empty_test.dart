// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

bool isCalled = false;

void callOnce() {
  Expect.isFalse(isCalled);
  isCalled = true;
}

void main() {
  final items = <String>[];
  for (final item in items) {
    print('Processing item: $item');
    break;
  }
  callOnce();
}
