// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart/test_all.dart' as dart;
import 'filtering/test_all.dart' as filtering;
import 'yaml/test_all.dart' as yaml;

void main() {
  defineReflectiveSuite(() {
    dart.main();
    filtering.main();
    yaml.main();
  }, name: 'completion');
}
