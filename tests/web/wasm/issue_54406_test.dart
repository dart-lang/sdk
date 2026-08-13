// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests a compile-time crash when a `while` in an async function has a `let`
// expression introduced by CFE.

String? get pageSettings => "a";

void main() async {
  while (pageSettings?.length != 1) {
    await null;
  }
}
