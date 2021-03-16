// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'libb.dart' deferred as libb;
import 'libc.dart';

main() async {
  var f = () => libb.C1();
  Expect.isTrue(f is C2 Function());
  Expect.isTrue(f is C3 Function());
  await libb.loadLibrary();
}
