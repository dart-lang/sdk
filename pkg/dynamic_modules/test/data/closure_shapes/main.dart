// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart';

/// A dynamic module is allowed to extend a class in the dynamic interface and
/// override its members.
void main() async {
  final c = (await helper.load('entry1.dart')) as int Function(int, int);
  Expect.equals(1, c1(0));
  Expect.equals(49, c(0, 0));
  helper.done();
}
