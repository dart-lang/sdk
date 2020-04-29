// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const int globalValue = 0;

void checkGlobalValue(int x) {
  Expect.equals(x, globalValue);
}

// Add symbols to the global scope
int fieldInGlobalScope = globalValue;
int get getterInGlobalScope => globalValue;
set setterInGlobalScope(int x) {
  checkGlobalValue(x);
}

int methodInGlobalScope() => globalValue;
