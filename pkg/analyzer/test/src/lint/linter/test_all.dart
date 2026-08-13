// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'linter_context_impl_test.dart' as linter_context_impl;

main() {
  defineReflectiveSuite(() {
    linter_context_impl.main();
  }, name: 'linter');
}
