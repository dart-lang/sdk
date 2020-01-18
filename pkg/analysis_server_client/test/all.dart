// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'live_test.dart' as live_test;
import 'server_test.dart' as server_test;

void main() {
  server_test.main();
  live_test.main();
}
