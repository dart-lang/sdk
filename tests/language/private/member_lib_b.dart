// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library PrivateMemberLibB;

import 'member_test.dart';

class B extends A {
  bool _instanceField = false;
  static bool _staticField = false;
  bool _fun1(bool b) {
    return true;
  }

  void _fun2() {}
}
