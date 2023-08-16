// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'handle_test.dart' as handle_test;

void main() {
  defineReflectiveSuite(() {
    handle_test.main();
  }, name: 'lsp');
}
