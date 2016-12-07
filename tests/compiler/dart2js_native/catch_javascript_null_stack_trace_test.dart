// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Try throwing a javascript null, and getting a stack-trace from it.

main() {
  var savedException;
  try {
    try {
      JS('', '(function () {throw null;})()');
    } catch (e, st) {
      savedException = st;
      rethrow;
    }
  } catch (error, st) {
    // st will be empty, but should not throw on toString().
    Expect.equals(savedException.toString(), st.toString());
  }
}
