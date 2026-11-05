// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SuperClass {
  const SuperClass();
}

class SubClass extends SuperClass {
  static const member = SubClass();
  const SubClass();
  bool test() => super == .member;
  bool testNotEqual() => super != .member;
}
