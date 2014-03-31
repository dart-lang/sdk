// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Whitebox integration/end-to-end test of Try Dart! site.
///
/// This test opens Try Dart! in an iframe.  When opened the first time, Try
/// Dart! will display a simple hello-world example, color tokens, compile the
/// example, and run the result.  We've instrumented Try Dart! to use
/// window.parent.postMessage when the running program prints anything. So this
/// test just waits for a "Hello, World!" message.
library trydart.end_to_end_test;

import 'dart:html';
import 'dart:async';

import 'package:async_helper/async_helper.dart';

void main() {
  asyncStart();
  window.onMessage.listen((MessageEvent e) {
    if (e.data == 'Hello, World!\n') {
      // Clear the DOM to work around a bug in test.dart.
      document.body.nodes.clear();

      // Clean up after ourselves.
      window.localStorage.clear();

      asyncSuccess(null);
    } else {
      window.console.dir(e.data);
    }
  });

  // Clearing localStorage makes Try Dart! think it is opening for the first
  // time.
  window.localStorage.clear();

  document.body.append(new IFrameElement()
      ..src = '/root_build/try_dartlang_org/index.html'
      ..style.width = '90vw'
      ..style.height = '90vh');
}
