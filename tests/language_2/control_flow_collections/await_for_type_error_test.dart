// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  () async {
    // Non-Stream type.
    int nonStream = 3;
    var _ = <int>[await for (var i in nonStream) 1]; //# 01: compile-time error
    var _ = <int, int>{await for (var i in nonStream) 1: 1}; //# 02: compile-time error
    var _ = <int>{await for (var i in nonStream) 1}; //# 03: compile-time error

    // Wrong element type.
    Stream<String> s = Stream.fromIterable(["s"]);
    var _ = <int>[await for (int i in s) 1]; //# 07: compile-time error
    var _ = <int, int>{await for (int i in s) 1: 1}; //# 08: compile-time error
    var _ = <int>{await for (int i in s) 1}; //# 09: compile-time error

    // Wrong body element type.
    var _ = <int>[await for (var i in s) "s"]; //# 10: compile-time error
    var _ = <int, int>{await for (var i in s) "s": 1}; //# 11: compile-time error
    var _ = <int, int>{await for (var i in s) 1: "s"}; //# 12: compile-time error
    var _ = <int>{await for (var i in s) "s"}; //# 13: compile-time error
  }();
}
