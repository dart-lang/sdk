// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10

// Found by DartFuzzing: would assert during OSR:
// https://github.com/dart-lang/sdk/issues/39071

main() {
  var x = [
    [for (int i = 0; i < 20; ++i) i]
  ];
}
