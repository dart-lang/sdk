// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extension declaration that can be imported by the test.

class L0 {}

class L1 implements L0 {}

class L2 implements L1 {}

class L3 implements L2 {}

class L4 implements L3 {}

class L5 implements L4 {}

class L6 implements L5 {}

extension EL0 on L0 {
  String get name => "EL0";
}

extension EL1 on L1 {
  String get name => "EL1";
}

extension EL2 on L2 {
  String get name => "EL2";
}

extension EL3 on L3 {
  String get name => "EL3";
}

extension EL4 on L4 {
  String get name => "EL4";
}

extension EL5 on L5 {
  String get name => "EL5";
}

extension EL6 on L6 {
  String get name => "EL6";
}

extension EL6B on L6 {
  String get name => "EL6B";
}
