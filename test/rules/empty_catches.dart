// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N empty_catches`

void foo() {
  try {
    throw new Exception();
  } catch (_) { } //OK

  try {
    throw new Exception();
  } catch (e) { } //LINT

  try {
    throw new Exception();
  } catch (e) {
    // Nothing.
  } //OK!

  try {
    throw new Exception();
  } catch (e) {
    print(e);
  } //OK

}
