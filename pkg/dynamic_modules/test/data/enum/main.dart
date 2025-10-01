// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

void main() async {
  final result = await helper.load('entry1.dart') as List;
  final r0 = result[0] as Enum;
  final r1 = result[1] as int;
  final r2 = result[2] as String;
  final r3 = result[3] as Enum;
  Expect.equals('e2', r0.name);
  Expect.equals('Foo.e2', r0.toString());
  Expect.equals(1, r0.index);
  Expect.equals(0, r1);
  Expect.equals('Foo.e3', r2);
  Expect.equals('e1', r3.name);
  Expect.equals('E1', r3.toString());
  Expect.equals(0, r3.index);
  helper.done();
}
