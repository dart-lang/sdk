// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_widget_description_test.dart' as get_widget_description;
import 'set_property_value_test.dart' as set_property_value;

void main() {
  defineReflectiveSuite(() {
    get_widget_description.main();
    set_property_value.main();
  });
}
