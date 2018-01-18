// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_js_helper' show patch;

@patch
void _waitForEvent(int timeoutMillis) {
  throw new UnsupportedError("waitForEvent");
}
