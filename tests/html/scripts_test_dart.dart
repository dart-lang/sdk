// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ScriptsTestDart;
import 'dart:html';
import 'dart:async';

main() {
  window.postMessage('squid', '*');
  window.postMessage('tiger', '*');  // Unexpected message OK.
  new Timer(new Duration(seconds: 1), () {
    window.postMessage('squid', '*');  // Duplicate message OK.
    window.postMessage('sea urchin', '*');
  });
}
