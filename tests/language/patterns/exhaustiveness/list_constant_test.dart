// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

// An empty constant list (not empty list pattern) is not treated as covering
// empty lists when it comes to exhaustiveness.

void main() {
  var result = switch ([1, 2, 3]) {
    //         ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
    //                 ^
    // [cfe] The type 'List<int>' is not exhaustively matched by the switch cases since it doesn't match '[]'.
    const [] => 'empty constant',
    [_, ...] => 'non-empty'
  };
}
