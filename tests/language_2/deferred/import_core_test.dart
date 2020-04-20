// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Nothing in the language spec explicitly prohibits a deferred import of
// 'dart:core'.  Make sure it doesn't lead to any strange behavior.

import "dart:core" deferred as core;

main() {
  core.loadLibrary().then((_) => null);
}
