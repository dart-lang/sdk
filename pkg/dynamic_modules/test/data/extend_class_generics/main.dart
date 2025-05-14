// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' show Base, SuperBase;

/// A dynamic module is allowed to extend a class in the dynamic interface and
/// override its members.
void main() async {
  final o = (await helper.load('entry1.dart')) as Base;
  if (o is SuperBase<num, String>) {
    Expect.equals(3, o.method1());
  } else {
    Expect.fail('Missed type check');
  }
  helper.done();
}
