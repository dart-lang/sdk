// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This isn't a common use-case, but we want to make sure scheduled_test doesn't
// step on unittest's toes too much.
import 'dart:async';

import 'package:scheduled_test/scheduled_test.dart' as scheduled_test;
import 'package:unittest/unittest.dart' as unittest;

void main() {
  scheduled_test.test('scheduled_test throws', () {
    scheduled_test.expect(new Future.error('foo'),
        scheduled_test.throwsA('foo'));
  });

  unittest.test('unittest throws', () {
    // We test a future matcher because scheduled_test modifies some of
    // unittest's asynchrony infrastructure.
    unittest.expect(new Future.error('foo'), unittest.throwsA('foo'));
  });
}
