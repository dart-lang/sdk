// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib1.dart';
import 'lib2.dart' deferred as c;

/*member: main:OutputUnit(main, {})*/
main() async {
  await c.loadLibrary();
  c.createA();
  doCast(<dynamic>[1, 2]);
}
