// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'break_on_function_many_child_isolates_test.dart';

Future<void> main(List<String> args) async {
  await runIsolateBreakpointPauseTest(
    args,
    scriptName: 'break_on_function_child_isolate_test.dart',
    isolateCount: 1,
  );
}
