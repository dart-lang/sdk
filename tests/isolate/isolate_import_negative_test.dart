// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library IsolateImportNegativeTest;
// Ommiting the following import is an error:
// #import('dart:isolate');

void entry() {}

main() {
  spawnFunction(entry);
}

