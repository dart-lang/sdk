// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

void main() {
  JSAny? jsValue;
  if (jsValue.isA<JSString>()) {
    print(jsValue);
  } else if (jsValue.isA<JSArray>()) {
    print(jsValue);
  }
}
