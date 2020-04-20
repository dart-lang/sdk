// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Check that we hoist instructions in a loop condition, even if that
// condition involves control flow.

import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST = '''
var a = [1];

main() {
  dynamic count = int.parse('42') == 42 ? 42 : null;
  for (int i = 0; i < count && i < a[0]; i++) {
    print(i);
  }
  a.removeLast();
  // Ensure we don't try to generate a bailout method based on a check
  // of [count].
  count.removeLast();
}
''';

main() {
  runTest() async {
    await compileAndMatch(TEST, 'main',
        new RegExp('if \\(typeof count !== "number"\\)(.|\\n)*while'));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
