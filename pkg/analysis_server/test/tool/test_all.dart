// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'lsp_spec/test_all.dart' as lsp_spec;

void main() {
  defineReflectiveSuite(() {
    lsp_spec.main();
  }, name: 'tool');
}
