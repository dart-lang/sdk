// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../shared/shared.dart' as shared;
import 'package:expect/expect.dart';

@pragma('dyn-module:entry-point')
Object dynamicModuleEntrypoint() {
  final wrap = shared.wrap<List<int>, String>;
  final wrapped = wrap([20], 'foo');
  Expect.equals(20, wrapped.$1[0]);
  Expect.equals('foo', wrapped.$2);
  return shared.wrap<bool, int>;
}
