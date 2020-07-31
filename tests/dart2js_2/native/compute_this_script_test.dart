// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test of _computeThisScript().

import 'dart:_js_helper' show thisScript;

main() {
  // This is somewhat brittle and relies on an implementation detail
  // of our test runner, but I can think of no other way to test this.
  // -- ahe
  if (!thisScript.endsWith('/compute_this_script_test.js')) {
    throw 'Unexpected script: "$thisScript"';
  }
}
