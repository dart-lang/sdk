// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a private library can be accessed from libraries in this special
// test folder.

import 'dart:_js_helper';

void main() {
  print(loadDeferredLibrary);
}
