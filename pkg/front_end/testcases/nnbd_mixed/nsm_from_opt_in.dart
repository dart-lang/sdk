// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'nsm_from_opt_in_lib.dart';

abstract class A2 implements A {
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

abstract class B2 extends A implements C2 {
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

abstract class C2 {
  int method(int i, {optional});
  T genericMethod1<T>(T t);
  T genericMethod2<T extends Object>(T t);
  T genericMethod3<T extends Object>(T t);
}

main() {}
