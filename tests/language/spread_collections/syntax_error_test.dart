// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  // Spread nothing.
  var _ = [...]; //# 00: syntax error
  var _ = [...?]; //# 01: syntax error
  var _ = [...,]; //# 02: syntax error

  // Use `...` in map entry.
  var _ = {"a": ...{}}; //# 03: syntax error
  var _ = {...{}: "b"}; //# 04: syntax error
  var _ = {"a": ...?{}}; //# 05: syntax error
  var _ = {...?{}: "b"}; //# 06: syntax error

  // Treats `...?` as single token.
  var _ = [... ?null]; //# 07: syntax error
  var _ = {1: 2, ... ?null}; //# 08: syntax error
}
