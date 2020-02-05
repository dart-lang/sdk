// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'src/filesystem_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FantasyWorkspaceTest);
  });
}

@reflectiveTest
class FantasyWorkspaceTest extends FilesystemTestBase {}
