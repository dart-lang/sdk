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

// TODO(ahe): Remove this import if issue 17936 is fixed.
import 'dart:js' as hack;

import 'package:async_helper/async_helper.dart';

void installErrorHandlerOn(IFrameElement iframe) {
  // This method uses dart:js to install an error event handler on the content
  // window of [iframe]. This is a workaround for http://dartbug.com/17936.
  var iframeProxy = new hack.JsObject.fromBrowserObject(iframe);
  var contentWindowProxy = iframeProxy['contentWindow'];
  if (contentWindowProxy == null) {
    print('No contentWindow in iframe');
    throw 'No contentWindow in iframe';
  }
  contentWindowProxy.callMethod('addEventListener', ['error', (eventProxy) {
    String filename = eventProxy['filename'];
    int lineno = eventProxy['lineno'];
    String message = eventProxy['message'];
    print("Error occurred in iframe: $message");
    new Future(() {
      // Chrome seems to not call window.onerror when you throw in response to
      // an error event. So we throw the error in a future.
      throw 'Error from iframe: $filename:$lineno: $message';
    });
  }]);
}

void onIframeLoaded(Event event) {
  installErrorHandlerOn(event.target);
}

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

  IFrameElement iframe = new IFrameElement()
      ..src = '/root_build/try_dartlang_org/index.html'
      ..style.width = '90vw'
      ..style.height = '90vh'
      ..onLoad.listen(onIframeLoaded);
  document.body.append(iframe);
  // Install an error handler both on the new iframe element, and when it has
  // fired the load event.  That seems to matter according to some sources on
  // stackoverflow.
  installErrorHandlerOn(iframe);
}
