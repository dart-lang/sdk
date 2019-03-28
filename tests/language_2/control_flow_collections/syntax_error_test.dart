// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=control-flow-collections,spread-collections,constant-update-2018

void main() {
  // No then element.
  var _ = [if (true)]; //# 00: compile-time error

  // No then element with else.
  var _ = [if (true) else 0]; //# 01: compile-time error

  // No else element.
  var _ = [if (true) 0 else]; //# 02: compile-time error

  // Spread if.
  var _ = [...if (true) 0]; //# 03: compile-time error

  // Spread for.
  var _ = [...for (; false;) 0]; //# 04: compile-time error

  // Use if in map entry.
  var _ = {if (true) 1: 1: 2}; //# 05: compile-time error
  var _ = {1: if (true) 2: 2}; //# 06: compile-time error

  // Use for in map entry.
  var _ = {for (; false;) 1: 1: 2}; //# 07: compile-time error
  var _ = {1: for (; false;) 2: 2}; //# 08: compile-time error

  // Use for variable out of scope.
  var _ = [for (var i = 0; false;) 1, i]; //# 09: compile-time error

  // Use for-in variable out of scope.
  var _ = [for (var i in [1]; false;) 1, i]; //# 10: compile-time error

  // Use for variable in own initializer.
  var _ = [for (var i = i; false;) 1]; //# 11: compile-time error

  // Use for-in variable in own initializer.
  var _ = [for (var i in [i]) 1]; //# 12: compile-time error
}
