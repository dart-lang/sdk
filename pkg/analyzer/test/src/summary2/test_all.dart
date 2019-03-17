// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'ast_binary_writer_test.dart' as ast_binary_writer;

main() {
  defineReflectiveSuite(() {
    ast_binary_writer.main();
  }, name: 'summary2');
}
