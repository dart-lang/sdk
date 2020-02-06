// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'nsm_from_opt_in_lib.dart';

abstract class B2 extends A implements C2 {
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

abstract class C2 {
  int method(int i, {optional});
}

main() {}
