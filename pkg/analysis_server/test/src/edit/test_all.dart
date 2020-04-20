// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix/test_all.dart' as fix;
import 'nnbd_migration/test_all.dart' as nnbd_migration;
import 'preview/test_all.dart' as preview;

void main() {
  defineReflectiveSuite(() {
    fix.main();
    nnbd_migration.main();
    preview.main();
  }, name: 'edit');
}
