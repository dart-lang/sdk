// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

class C {
  Future<List<int>> m() async => []..add(await _m());
  Future<int> _m() async => 42;
}

main() async {
  Expect.equals((await new C().m()).first, 42);
}
