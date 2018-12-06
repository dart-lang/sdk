// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_catches_without_on_clauses`

void bad() {
  try {}
  catch (e) { // LINT
    // ignore
  }
}

void good() {
  try {}
  on Exception catch (e) { // OK
    // ignore
  }
}
