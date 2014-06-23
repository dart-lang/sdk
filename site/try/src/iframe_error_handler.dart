// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.iframe_error_handler;

// TODO(ahe): Remove this import if issue 17936 is fixed.
import 'dart:js' as hack;

import 'dart:html' show
    Event,
    IFrameElement,
    window;

import 'dart:async' show
    Stream,
    StreamController;

class ErrorMessage {
  final String message;
  final String filename;
  final num lineno;
  final num colno;
  final String stack;

  ErrorMessage(
      this.message, this.filename, this.lineno, this.colno, this.stack);

  String toString() {
    String result = filename == null ? '' : filename;
    if (lineno != null && lineno != 0 && !lineno.isNaN) {
      result += ':$lineno';
    }
    if (colno != null && colno != 0 && !colno.isNaN) {
      result += ':$colno';
    }
    if (message != null && !message.isEmpty) {
      if (!result.isEmpty) {
        result += ': ';
      }
      result += message;
    }
    if (stack != null && !stack.isEmpty) {
      if (!result.isEmpty) {
        result += '\n';
      }
      result += stack;
    }
    return result;
  }
}

Stream<ErrorMessage> errorStream(IFrameElement iframe) {
  StreamController<ErrorMessage> controller =
      new StreamController<ErrorMessage>();
  void onError(
      String message,
      String filename,
      int lineno,
      [int colno,
       error]) {
    // See:
    // https://mikewest.org/2013/08/debugging-runtime-errors-with-window-onerror
    String stack;
    if (error != null) {
      var jsStack = error['stack'];
      if (jsStack != null) {
        stack = hack.context.callMethod('String', [jsStack]);
      }
    }
    controller.add(new ErrorMessage(message, filename, lineno, colno, stack));
  }

  void installErrorHandler() {
    // This method uses dart:js to install an error event handler on the content
    // window of [iframe]. This is a workaround for http://dartbug.com/17936.
    var iframeProxy = new hack.JsObject.fromBrowserObject(iframe);
    var contentWindowProxy = iframeProxy['contentWindow'];
    if (contentWindowProxy == null) {
      String message =
          'No contentWindow, call this method *after* adding iframe to'
          ' document.';
      window.console.error(message);
      throw message;
    }

    // Note: we have two options, use "iframe.contentWindow.onerror = ..." or
    // "iframe.contentWindow.addEventListener('error', ...)".  The former seems
    // to provide more details on both Chrome and Firefox (which provides no
    // information at all in error events).
    contentWindowProxy['onerror'] = onError;
  }
  iframe.onLoad.listen((Event event) => installErrorHandler());
  installErrorHandler();
  return controller.stream;
}
