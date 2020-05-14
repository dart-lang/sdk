// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.5

import 'issue41180_lib.dart';

class D<Y> {
  C<Y> method() => new C<Y>(() => null);
}

void main() {
  foo(() => null);
  bar = () => null;
  new D<int>().method();
  findKey(new Map<String, String>('foo', 'bar'), 'bar');
}

void findKey(Map<String, dynamic> m, dynamic search) {
  print(m.entries
      .singleWhere((entry) => entry.value == search, orElse: () => null)
      ?.key);
}
