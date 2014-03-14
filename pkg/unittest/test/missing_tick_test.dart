// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

// TODO(gram): Convert to a shouldFail passing test.
main() {
  SimpleConfiguration config = unittestConfiguration;
  config.timeout = const Duration(seconds: 2);
  group('Broken', () {
    test('test that should time out', () {
      expectAsync(() {});
    });
  });
}
