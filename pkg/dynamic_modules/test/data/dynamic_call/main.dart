// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';
import 'shared/lib.dart';

void main() async {
  sharedA1 = A1();
  sharedA2 = A2();
  sharedA4 = A4();
  final result = await helper.load('entry1.dart');
  Expect.isTrue(result as bool);

  // Dynamic calls from host are always allowed as long as the selector was
  // retained for other reasons by AOT. This is regardless of whether the target
  // method was in the host or whether it was exposed as dynamically-callable.
  dynamic b7 = sharedB7;
  Expect.equals(1, b7.m15()); // unexposed, host target
  Expect.equals(4, b7.m16()); // unexposed, dynamic module target
  Expect.equals(1, b7.m17()); // exposed, host target
  Expect.equals(4, b7.m18()); // exposed, dynamic module target

  // Call a selector that is never declared in the host. AOT shouldn't optimize
  // it away, since it may refer to a selector defined by a dynamic module
  // later.
  dynamic b6 = sharedB6;
  void m14Case() => Expect.equals(14, b6.m14());
  m14Case();

  helper.done();
}
