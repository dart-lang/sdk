// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that throws during destructuring have the correct stack trace.
// Regression test for https://github.com/dart-lang/sdk/issues/53519

import 'package:expect/expect.dart';

String destructure(Map<String, dynamic> map) {
  final {'hello': world, 'count': count} = map;
  return 'Hello $world, count: $count';
}

main() {
  try {
    destructure({
      'hello': 'world',
      // No count entry, so the destructuring fails.
    });
  } catch (e, s) {
    print(s);
    // Expect that the stack trace contains an entry for the destructure
    // function at line 11.
    Expect.isTrue(s.toString().contains(RegExp(r'destructure \(.*:11(:3)?\)')));
  }
}
