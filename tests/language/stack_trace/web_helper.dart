// (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

void configureStackFrameLimit() {
  // Different browsers have different limits on how many top frames
  // are captured in stack traces (e.g. Chrome's limit is 10).
  // We can configure that here manually, to ensure the tests pass
  // on all compiler+browser combinations.
  jsWindow?.error.stackTraceLimit = 100;
}

@JS('window')
external JSWindow? get jsWindow;

@JS()
@staticInterop
class JSWindow {}

extension on JSWindow {
  @JS('Error')
  external JSError get error;
}

@JS()
@staticInterop
class JSError {}

extension on JSError {
  @JS('stackTraceLimit')
  external void set stackTraceLimit(int value);
}
