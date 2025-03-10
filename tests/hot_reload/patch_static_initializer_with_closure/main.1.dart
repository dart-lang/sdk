// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/174ce4005f34bc860d1a4189ff21292b0796c94b/runtime/vm/isolate_reload_test.cc#L6091

dynamic field = (_, __) => 'Not executed';

Future<void> main() async {
  dynamic f = field;
  Expect.equals('ab', f('b'));
  await hotReload();

  dynamic g = field;
  Expect.equals('ac', g('c'));
}

/** DIFF **/
/*
 // Adapted from:
 // https://github.com/dart-lang/sdk/blob/174ce4005f34bc860d1a4189ff21292b0796c94b/runtime/vm/isolate_reload_test.cc#L6091
 
-dynamic field = (a) => 'a$a';
+dynamic field = (_, __) => 'Not executed';
 
 Future<void> main() async {
   dynamic f = field;
*/
