// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/expect.dart';

@JS()
external void eval(String code);

void doThrow() {
  eval('throw new Error();');
}

void foo() {
  doThrow();
}

void bar() {
  foo();
}

void main() {
  try {
    bar();
    Expect.fail('JS exception should be thrown and caught');
  } catch (e, s) {
    List<String> lines = s.toString().split('\n');

    // Chrome includes an 'Error' message at the start of each stack.
    if (lines[0].startsWith('Error')) {
      lines = lines.skip(1).toList();
    }

    // 'eval' frame is consistently at top of stack across all browsers.
    Expect.isTrue(lines[0].contains('eval'));
  }
}
