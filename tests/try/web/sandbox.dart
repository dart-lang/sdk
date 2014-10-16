// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper library that creates an iframe sandbox that can be used to load
/// code.
library trydart.test.sandbox;

import 'dart:html';
import 'dart:async';

// TODO(ahe): Remove this import if issue 17936 is fixed.
import 'dart:js' as hack;

import 'package:expect/expect.dart' show
    Expect;

final Listener listener = new Listener();

void onError(String message, String filename, int lineno, [int colno, error]) {
  if (filename != null && filename != "" && lineno != 0) {
    if (colno != null && colno != 0) {
      message = '$filename:$lineno:$colno $message';
    } else {
      message = '$filename:$lineno: $message';
    }
  }
  if (error != null) {
    // See:
    // https://mikewest.org/2013/08/debugging-runtime-errors-with-window-onerror
    var stack = error['stack'];
    if (stack != null) {
      message += '\n$stack';
    }
  }
  message = "Error occurred in iframe: $message";

  // Synchronous, easier to read when running the browser manually.
  window.console.log(message);

  new Future(() {
    // Browsers ignore errors throw in event listeners (or from
    // window.onerror).
    throw message;
  });
}

void installErrorHandlerOn(IFrameElement iframe) {
  // This method uses dart:js to install an error event handler on the content
  // window of [iframe]. This is a workaround for http://dartbug.com/17936.
  var iframeProxy = new hack.JsObject.fromBrowserObject(iframe);
  var contentWindowProxy = iframeProxy['contentWindow'];
  if (contentWindowProxy == null) {
    print('No contentWindow in iframe');
    throw 'No contentWindow in iframe';
  }

  // Note: we have two options, use "iframe.contentWindow.onerror = ..." or
  // "iframe.contentWindow.addEventListener('error', ...)".  The former seems
  // to provide more details on both Chrome and Firefox (which provides no
  // information at all in error events).
  contentWindowProxy['onerror'] = onError;
}

void onIframeLoaded(Event event) {
  installErrorHandlerOn(event.target);
}

IFrameElement appendIFrame(String src, Element element) {
  IFrameElement iframe = new IFrameElement()
      ..src = src
      ..onLoad.listen(onIframeLoaded);
  element.append(iframe);
  // Install an error handler both on the new iframe element, and when it has
  // fired the load event.  That seems to matter according to some sources on
  // stackoverflow.
  installErrorHandlerOn(iframe);
  return iframe;
}

class Listener {
  Completer completer;

  String expectedMessage;

  void onMessage(MessageEvent e) {
    String message = e.data;
    if (expectedMessage == message) {
      completer.complete();
    } else {
      switch (message) {
        case 'dart-calling-main':
        case 'dart-main-done':
        case 'unittest-suite-done':
        case 'unittest-suite-fail':
        case 'unittest-suite-success':
        case 'unittest-suite-wait-for-done':
          break;

        default:
          completer.completeError('Unexpected message: "$message".');
      }
    }
  }

  Future expect(data) {
    if (data is String) {
      Expect.isTrue(completer == null || completer.isCompleted);
      expectedMessage = data;
      completer = new Completer();
      return completer.future;
    } else if (data is Iterable) {
      return Future.forEach(data, expect);
    } else {
      throw 'Unexpected data type: ${data.runtimeType}.';
    }
  }

  void start() {
    window.onMessage.listen(onMessage);
  }
}
