// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

void main() async {
  final result = (await helper.load('entry1.dart')) as List;
  Expect.equals(1, result[0] as int);
  Expect.equals(1, result[1] as int);
  Expect.equals(52, (result[2] as int Function(int)).call(10));
  Expect.equals(53, (result[3] as int Function(int)).call(10));
  Expect.equals(52, (result[4] as int Function(int)).call(10));
  Expect.equals(53, (result[5] as int Function(int)).call(10));
  helper.done();
}
