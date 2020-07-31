// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  // For cannot be used in a const collection.
  const _ = [for (var i in []) 1]; //# 00: compile-time error
  const _ = {for (var i in []) 1: 1}; //# 01: compile-time error
  const _ = {for (var i in []) 1}; //# 02: compile-time error

  const _ = [for (; false;) 1]; //# 03: compile-time error
  const _ = {for (; false;) 1: 1}; //# 04: compile-time error
  const _ = {for (; false;) 1}; //# 05: compile-time error

  () async {
    const _ = <int>[await for (var i in []) 1]; //# 06: compile-time error
    const _ = <int, int>{await for (var i in []) 1: 1}; //# 07: compile-time error
    const _ = <int>{await for (var i in []) 1}; //# 08: compile-time error
  }();
}
