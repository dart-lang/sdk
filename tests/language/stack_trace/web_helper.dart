// (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

void configureStackFrameLimit() {
  // Different browsers have different limits on how many top frames
  // are captured in stack traces (e.g. Chrome's limit is 10).
  // We can configure that here manually, to ensure the tests pass
  // on all compiler+browser combinations.
  eval('''
    var globalState = (typeof window != "undefined") ? window
      : (typeof global != "undefined") ? global
      : (typeof self != "undefined") ? self : null;

    // By default, stack traces cutoff at 10 in Chrome.
    if (globalState.Error) {
      globalState.Error.stackTraceLimit = Infinity;
    }
''');
}

@JS()
external void eval(String code);
