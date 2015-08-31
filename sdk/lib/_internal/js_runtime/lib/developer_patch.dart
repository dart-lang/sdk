// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:developer library.

import 'dart:_js_helper' show patch;
import 'dart:_foreign_helper' show JS;

@patch
@ForceInline()
bool debugger({bool when: true, String message}) {
  if (when) {
    JS('', 'debugger');
  }
  return when;
}

@patch
Object inspect(Object object) {
  return object;
}

@patch
log(String message,
    {DateTime time,
     int sequenceNumber,
     int level: 0,
     String name: '',
     Zone zone,
     Object error,
     StackTrace stackTrace}) {
  // TODO.
}
