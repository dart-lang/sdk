// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart';

/// A dynamic module can override a method declared in a mixin.
void main() async {
  final objs = (await helper.load('entry1.dart')) as List<A>;
  final o1 = objs[0];
  Expect.equals('DynA1.foo, super: M2.foo', o1.foo());
  Expect.equals('M2.bar', o1.bar());
  final o2 = objs[1];
  Expect.equals('M2.foo', o2.foo());
  Expect.equals('M3.bar', o2.bar());
  helper.done();
}
