// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for http://dartbug.com/62664.

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

void testTypeParameterForwardingStub() {
  final PBox<Object> object = PSub();
  object.foo<List<int>>(<int>[1]);
  if (checkedParameters) {
    Expect.throws<TypeError>(() => object.foo<List<Object>>(<Object>['a']));
  }
}

abstract class PBox<T> {
  void foo<H extends List<T>>(H a);
}

class PBase {
  void foo<H extends List<int>>(List<int> a) =>
      print('PBase.foo<$H>(${1 + a[0]})');
}

class PSub extends PBase implements PBox<int> {}

void main() {
  testTypeParameterForwardingStub();
}
