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

import 'package:async_helper/async_helper.dart' show
    asyncTest;

import 'sandbox.dart' show
    appendIFrame,
    listener;

void main() => asyncTest(() {
  listener.start();

  // Disable analytics for testing.
  document.cookie = 'org-trydart-AutomatedTest=true;path=/';

  // Clearing localStorage makes Try Dart! think it is opening for the first
  // time.
  window.localStorage.clear();

  IFrameElement iframe =
      appendIFrame('/root_build/try_dartlang_org/index.html', document.body)
          ..style.width = '90vw'
          ..style.height = '90vh';

  return listener.expect('Hello, World!\n').then((_) {
    // Remove the iframe to work around a bug in test.dart.
    iframe.remove();

    // Clean up after ourselves.
    window.localStorage.clear();
  });
});
