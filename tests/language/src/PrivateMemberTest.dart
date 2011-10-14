// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('PrivateMemberLibA');

#import('PrivateMemberLibB.dart');

#source('PrivateMemberLibA.dart');

class Test extends B {
  test() {
    i = _private1;
    b = _private1;  /// 01: compile-time error
    i = _static1;
    b = _static1;  /// 02: compile-time error
    i = _fun1();
    b = _fun1();  /// 03: compile-time error
    _fun4(42);
    _fun4(true);  /// 04: compile-time error
  }
}

void main() {
  new Test().test();
}
