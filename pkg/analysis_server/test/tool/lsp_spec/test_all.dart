// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'codegen_test.dart' as codegen;
import 'dart_test.dart' as dart;
import 'generated_classes_test.dart' as generated_classes;
import 'json_test.dart' as json;
import 'meta_model_test.dart' as meta_model;
import 'readme_test.dart' as readme;

void main() {
  defineReflectiveSuite(() {
    codegen.main();
    dart.main();
    generated_classes.main();
    json.main();
    meta_model.main();
    readme.main();
  }, name: 'lsp-tool');
}
