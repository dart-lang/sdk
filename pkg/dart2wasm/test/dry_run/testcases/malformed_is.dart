// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

void main() {
  JSAny? jsValue;
  // DRY_RUN: 3,  Should not perform an `is` test on a JS value
  if (jsValue is String) {
    print(jsValue);
    // DRY_RUN: 3,  Should not perform an `is` test on a JS value
    // DRY_RUN: 4,  Should not perform an `is` test against a JS value type
  } else if (jsValue is JSArray) {
    print(jsValue);
  }

  Object? dartValue;
  if (dartValue is String) {
    print(dartValue);
    // DRY_RUN: 4,  Should not perform an `is` test against a JS value type
  } else if (dartValue is JSArray) {
    print(dartValue);
    // DRY_RUN: 5,  Should not perform an `is` test against a generic DartType with JS type arguments
  } else if (dartValue is List<JSString>) {
    print(dartValue);
    // DRY_RUN: 5,  Should not perform an `is` test against a generic DartType with JS type arguments
  } else if (dartValue is (JSString,)) {
    print(dartValue);
    // DRY_RUN: 5,  Should not perform an `is` test against a generic DartType with JS type arguments
  } else if (dartValue is List<(JSString,)>) {
    print(dartValue);
  }
}
