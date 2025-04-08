// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'shared/shared.dart';

import 'package:expect/expect.dart';

// Constants with a constructor body can be used from dynamic modules.
void main() async {
  final c1 = (await helper.load('entry1.dart'));
  final c2 = (await helper.load('entry2.dart'));

  Expect.identical((c1 as B).x, 2);
  Expect.identical(c1, c2);
  helper.done();
}
