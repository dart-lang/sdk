// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

num calculate(Map values) {
  final result = max(0, values['value']);
  return result * 0.5;
}

void main() {
  throws(() => calculate(jsonDecode('{"value":0.25}')));
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Missing exception.';
}
