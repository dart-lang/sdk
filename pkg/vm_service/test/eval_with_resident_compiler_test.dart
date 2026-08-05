// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'eval_lib.dart' as testee_lib;
import 'eval_test_common.dart';

void main([args = const <String>[]]) =>
    createHarness('eval_with_resident_compiler_lib.dart', args).run(
        testeeMain: testee_lib.main, launchTesteeWithDartRunResident: true);
