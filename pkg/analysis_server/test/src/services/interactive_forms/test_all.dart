// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'interactive_forms_test.dart' as interactive_forms;

void main() {
  defineReflectiveSuite(() {
    interactive_forms.main();
  }, name: 'interactive_forms');
}
