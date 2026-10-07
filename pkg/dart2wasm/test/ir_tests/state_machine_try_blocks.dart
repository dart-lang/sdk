// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// printSourcePositions
// functionFilter=testStateMachineTryCatch
// tableFilter=NoMatch
// globalFilter=NoMatch
// typeFilter=NoMatch
// compilerOption=-O0

import 'dart:js_interop';

Iterable<int> testStateMachineTryCatch() sync* {
  try {
    yield 1;
    throw "dart error";
  } catch (e) {
    yield 2;
  } finally {
    yield 3;
  }
}

Iterable<int> testStateMachineTryCatchJs() sync* {
  try {
    yield 4;
  } on JSAny catch (e) {
    yield 5;
  }
}

void main() {
  print(testStateMachineTryCatch().toList());
  print(testStateMachineTryCatchJs().toList());
}
