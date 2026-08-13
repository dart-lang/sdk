// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' show Base;

/// A dynamic module is allowed to extend a class in the dynamic interface and
/// override its members.
void main() async {
  Expect.equals(100, Base().method1(0));
  final o1 = (await helper.load('entry1.dart'));
  final o2 = (await helper.load('entry2.dart'));
  Expect.equals(1, o1);
  Expect.equals(3, o2);
  helper.done();
}
