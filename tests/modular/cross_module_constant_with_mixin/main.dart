// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'b.dart';

main() {
  var bInst = B();
  Expect.equals(2.71, bInst.d);
  Expect.equals('default', bInst.doStringy('DEFAULT'));
}
