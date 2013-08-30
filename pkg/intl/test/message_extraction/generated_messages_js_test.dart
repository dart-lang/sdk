// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is intended to be run when compiled to Javascript, though it will
// also work if run from the VM, it just won't test anything different from
// message_extraction_test. It runs the generated code without going through
// the message extraction or translation, which can't be done in JS. This tells
// us if the generated code works in JS.

library generated_messages_js_test.dart;

import 'package:unittest/unittest.dart';
import 'sample_with_messages.dart' as sample;
import 'print_to_list.dart';
import 'verify_messages.dart';

main() {
  test("Test generated code running in JS", () =>
    sample.main().then((_) => verifyResult(lines)));
}
