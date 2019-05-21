// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that 'if' in const collections is not enabled without the experimental
// constant-update-2018 flag.

// SharedOptions=--enable-experiment=control-flow-collections,no-constant-update-2018

void main() {
  // If cannot be used in a const collection.
  const _ = [if (true) 1]; //# 00: compile-time error
  const _ = [if (false) 1 else 2]; //# 01: compile-time error
  const _ = {if (true) 1}; //# 02: compile-time error
  const _ = {if (false) 1 else 2}; //# 03: compile-time error
  const _ = {if (true) 1: 1}; //# 04: compile-time error
  const _ = {if (false) 1: 1 else 2: 2}; //# 05: compile-time error
}
