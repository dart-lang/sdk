// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart_fix_prompt_manager_test.dart' as dart_fix_prompt_manager;
import 'preferences_test.dart' as preferences;
import 'survey_manager_test.dart' as survey_manager;

void main() {
  defineReflectiveSuite(() {
    dart_fix_prompt_manager.main();
    preferences.main();
    survey_manager.main();
  }, name: 'user_prompts');
}
