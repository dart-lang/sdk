// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that a basic test still works when instructions are deduplicated.
// Test body comes from tests/corelib_2/apply2_test.dart, which is one of the
// tests that were failing when --dedup-instructions was broken in bare payload
// mode (precompiled + bare instructions).
//
// VMOptions=--dedup-instructions

import 'hello_world_test.dart' as other;

main() => other.main();
