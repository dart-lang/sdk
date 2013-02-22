// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of IsolateNatives.computeThisScript().

import 'dart:_isolate_helper';

main() {
  String script = IsolateNatives.computeThisScript();

  // This is somewhat brittle and relies on an implementation detail
  // of our test runner, but I can think of no other way to test this.
  // -- ahe
  if (!script.endsWith('/out.js')) {
    throw 'Unexpected script: "$script"';
  }
}
