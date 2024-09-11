// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

class B {
  final int x;
  const B(this.x);
}

// Similar to `isolated_shared`, constant canonicalization distinguishes
// two constnats, even if they are created from a common library that was
// not part of the original application.
main() async {
  final c1 = (await helper.load('entry1.dart'));
  final c2 = (await helper.load('entry2.dart'));

  Expect.identical(c1, c2);
  helper.done();
}
