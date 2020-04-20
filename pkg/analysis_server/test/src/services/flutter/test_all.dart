// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'container_properties_test.dart' as container_properties;
import 'widget_descriptions_test.dart' as widget_descriptions;

void main() {
  defineReflectiveSuite(() {
    container_properties.main();
    widget_descriptions.main();
  }, name: 'flutter');
}
