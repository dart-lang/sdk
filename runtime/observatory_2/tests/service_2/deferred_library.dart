// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_library;

int value = 0;

int decValue(int amount) {
  value -= amount;
  return amount;
}

void deferredTest() {
  decValue(decValue(1)); // line 15

  decValue(decValue(1)); // line 17
}
