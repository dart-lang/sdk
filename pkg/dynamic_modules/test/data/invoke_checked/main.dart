// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart';

class MyChild extends Base {
  @override
  Tester foo(covariant Tester x) {
    return Tester(x.val + 1);
  }
}

/// A dynamic module is allowed to extend a class in the dynamic interface and
/// override its members.
void main() async {
  final c = (await helper.load('entry1.dart')) as Base;
  Expect.equals(3, c.foo(Tester(3)).val);
  helper.done();
}
