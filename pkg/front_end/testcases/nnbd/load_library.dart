// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math" deferred as math;

main() {
  var v1 = math.loadLibrary();
  v1.then((_) {});
  var v2 = math.loadLibrary;
  v2().then((_) {});
}
