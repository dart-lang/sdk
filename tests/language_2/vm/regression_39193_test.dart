// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=1

// Found by DartFuzzing: would assert during OSR:
// https://github.com/dart-lang/sdk/issues/39193

Map<int, Set<int>> var75 = {};

main() {
  try {} catch (e, st) {} finally {
    print('before');
    var75[42] = (false
        ? const {}
        : {for (int loc1 = 0; loc1 < 1; loc1++) (-9223372034707292161 >> 165)});
    print('after');
  }
}
