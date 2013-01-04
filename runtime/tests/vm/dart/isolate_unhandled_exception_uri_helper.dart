// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_unhandled_exception_uri_helper;

import 'dart:isolate';

// Isolate script that throws an uncaught exception, which is caught by an
// uncaught exception handler.

void main() {
  port.receive((message, replyTo) {
    if (message == 'throw exception') {
      replyTo.call('throwing exception');
      throw new RuntimeError('ignore this exception');
    }
    replyTo.call('hello');
    port.close();
  });
}

bool _unhandledExceptionCallback(IsolateUnhandledException e) {
  return e.source.message == 'ignore this exception';
}
