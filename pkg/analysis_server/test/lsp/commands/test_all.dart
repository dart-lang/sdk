// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'apply_code_action_test.dart' as apply_code_action;
import 'fix_all_in_workspace_test.dart' as fix_all_in_workspace;
import 'resolve_test.dart' as resolve;

void main() {
  defineReflectiveSuite(() {
    apply_code_action.main();
    fix_all_in_workspace.main();
    resolve.main();
  });
}
