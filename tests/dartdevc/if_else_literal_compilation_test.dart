// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show JS;

import 'package:expect/expect.dart';

void main() async {
  var count = 0;
  if (JS<bool>('!', 'false')) {
    // Should be eliminated from the output based on the condition above.
    JS('', 'syntax error here!');
  }
  count++;
  if (JS<bool>('!', 'true')) {
    count++;
  } else {
    // Should be eliminated from the output based on the condition above.
    JS('', 'syntax error here!');
  }
  if (JS<bool>('!', 'false')) {
    // Should be eliminated from the output based on the condition above.
    JS('', 'syntax error here!');
  } else {
    count++;
  }
  if (!JS<bool>('!', 'true')) {
    // Should be eliminated from the output based on the condition above.
    JS('', 'syntax error here!');
  }
  count++;
  if (!JS<bool>('!', 'false')) {
    count++;
  } else {
    // Should be eliminated from the output based on the condition above.
    JS('', 'syntax error here!');
  }
  if (!JS<bool>('!', 'true')) {
    // Should be eliminated from the output based on the condition above.
    JS('', 'syntax error here!');
  } else {
    count++;
  }

  JS<bool>('!', 'true') ? count++ : JS('', 'syntax error here!');
  JS<bool>('!', 'false') ? JS('', 'syntax error here!') : count++;
  !JS<bool>('!', 'true') ? JS('', 'syntax error here!') : count++;
  !JS<bool>('!', 'false') ? count++ : JS('', 'syntax error here!');

  // All expected branches are evaluated, and none of the syntax errors where
  // compiled at all.
  Expect.equals(10, count);
}
