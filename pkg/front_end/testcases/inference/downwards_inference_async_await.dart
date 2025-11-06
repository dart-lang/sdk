// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

Future main() async {
  dynamic d;
  List<int> l0 = await [/*info:DYNAMIC_CAST*/ d];
  List<int> l1 = await new Future.value([d]);
}
