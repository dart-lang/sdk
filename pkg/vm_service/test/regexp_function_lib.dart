// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/expect.dart';
import 'common/test_helper.dart';

// Make sure these variables are not removed by the tree shaker.
@pragma('vm:entry-point')
late RegExp regex0;
@pragma('vm:entry-point')
late RegExp regex;

void script() {
  // Check the internal NUL doesn't trip up the name scrubbing in the vm.
  regex0 = RegExp('with internal \u{0} NUL');
  regex = RegExp(r'(\w+)');
  final str = 'Parse my string';
  final matches = regex.allMatches(str); // Run to generate bytecode.
  Expect.equals(matches.length, 3);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
