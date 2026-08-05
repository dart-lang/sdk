// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

class S<T> {
  num? n;
  T? t;
  String constrName;
  S({this.n, this.t}) : constrName = 'S';
  S.named({this.t, this.n}) : constrName = 'S.named';
}

class C<T> extends S<T> {
  C.constr1(String s, {super.t});
  C.constr2(int i, String s, {super.n}) : super();
  C.constr3(int i, String s, {super.n, super.t}) : super.named() {
    debugger();
  }
}

class R<T> {
  final dynamic f1;
  dynamic v1;
  num i1;
  T t1;
  R(this.f1, this.v1, this.i1, this.t1);
}

class B<T> extends R<T> {
  B(super.f1, super.v1, super.i1, super.t1) {
    debugger();
  }
}

void testMain() {
  debugger();
  C.constr3(1, 'abc', n: 3.14, t: 42);
  B('a', 3.14, 2.718, 42);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
