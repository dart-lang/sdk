// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library used by 'no_such_method_restriction_stack_trace_test.dart'

import 'no_such_method_restriction_stack_trace_lib2.dart';

class Nsm {
  @override
  noSuchMethod(Invocation invocation) {}
}

class Interface {
  void _privateMethod() {}
}

void callPrivateMethod(Interface x) {
  x._privateMethod();
}
