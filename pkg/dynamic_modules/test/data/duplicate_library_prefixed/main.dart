// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

// Since the modules were compiled with different library uri prefixes
// (see vm.dart), they should load fine, even though they use the same
// library.
void main() async {
  final a1 = await helper.load('entry1.dart');
  final a2 = await helper.load('entry2.dart');
  Expect.notEquals(a1, a2);
  Expect.notEquals(a1.runtimeType, a2.runtimeType);
  helper.done();
}
