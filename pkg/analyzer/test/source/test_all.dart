// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'error_processor_test.dart' as error_processor_test;
import 'file_source_test.dart' as file_source;

main() {
  defineReflectiveSuite(() {
    error_processor_test.main();
    file_source.main();
  }, name: 'source');
}
