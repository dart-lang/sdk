// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

import 'dart:html';
import 'dart:isolate';

main() {
  port.receive((msg, replyTo) {
    if (msg != 'check') {
      replyTo.send('wrong msg: $msg');
    }
    replyTo.send('${window.location}');
    port.close();
  });
}
