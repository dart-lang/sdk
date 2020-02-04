// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_suggestions_test.dart' as get_suggestions;
import 'list_token_details_test.dart' as list_token_details;

void main() {
  defineReflectiveSuite(() {
    get_suggestions.main();
    list_token_details.main();
  }, name: 'completion');
}
