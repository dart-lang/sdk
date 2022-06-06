// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart_test.dart' as dart_test;
import 'generated_classes_test.dart' as generated_classes_test;
import 'json_test.dart' as json_test;
import 'meta_model_test.dart' as meta_model_test;

void main() {
  defineReflectiveSuite(() {
    dart_test.main();
    generated_classes_test.main();
    json_test.main();
    meta_model_test.main();
  }, name: 'lsp-tool');
}
