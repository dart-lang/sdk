// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'access_concrete_nsm.dart';

mixin class SuperClass {
  void _inaccessibleMethod1() {}
  void accessibleMethod() {}
}

mixin class NoSuchMethodClass {
  dynamic noSuchMethod(Invocation invocation) => 42;
}
