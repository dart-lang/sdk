// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fantasy_repo_test.dart' as fantasy_repo_test;
import 'fantasy_sub_package_test.dart' as fantasy_sub_package_test;
import 'fantasy_workspace_test.dart' as fantasy_workspace_test;

main() {
  defineReflectiveSuite(() {
    fantasy_repo_test.main();
    fantasy_sub_package_test.main();
    fantasy_workspace_test.main();
  });
}
