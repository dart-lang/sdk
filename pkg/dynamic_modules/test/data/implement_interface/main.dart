// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' show Base;

/// A dynamic module can implement an exposed class.
main() async {
  final o = (await helper.load('entry1.dart')) as Base;
  Expect.equals(3, o.method1());
  Expect.equals(4, o.method2());
  helper.done();
}
