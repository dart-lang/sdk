// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=set-literals,spread-collections

void main() {
  // Spread nothing.
  var _ = [...]; //# 00: compile-time error
  var _ = [...?]; //# 01: compile-time error
  var _ = [...,]; //# 02: compile-time error

  // Use `...` in map entry.
  var _ = {"a": ...{}}; //# 03: compile-time error
  var _ = {...{}: "b"}; //# 04: compile-time error
  var _ = {"a": ...?{}}; //# 05: compile-time error
  var _ = {...?{}: "b"}; //# 06: compile-time error

  // Treats `...?` as single token.
  var _ = [... ?null]; //# 07: compile-time error
  var _ = {1: 2, ... ?null}; //# 08: compile-time error
}
