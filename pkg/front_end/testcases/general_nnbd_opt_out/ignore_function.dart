// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import "dart:core" as core;

class A implements core.Function {
  // No error here: core.Function is ignored.
  operator ==(other) => false;
}

class B implements Function {
  // Error here Object.== and Function.== disagree on the type of other.
  operator ==(other) => false;
}

class Function {
  core.bool operator ==(core.Object other) => false;
}

main() {}
