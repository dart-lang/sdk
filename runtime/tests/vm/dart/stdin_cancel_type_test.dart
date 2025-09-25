// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that asking closed stdin for its type doesn't crash.
// The crash was reported on https://github.com/dart-lang/sdk/issues/61571.

import 'dart:io';

void main() async {
  stdin.listen((_) {}).cancel();
  stdin.hasTerminal;
}
