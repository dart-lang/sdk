// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_rethrow_when_possible`

void bad1() {
  try {} catch (e) {
    throw e; // LINT
  }
}

void bad2() {
  try {} catch (e, stackTrace) {
    print(stackTrace);
    throw e; // LINT
  }
}

void good1() {
  try {} catch (e) {
    rethrow;
  }
}

void good2() {
  try {} catch (e) {
    throw new Exception(); // OK
  }
}

void good3() {
  try {} catch (e) {
    try {} catch (f) {
      throw e; // OK
    }
  }
}
