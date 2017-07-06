// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'checker_test.dart' as checker_test;
import 'front_end_inference_test.dart' as front_end_inference_test;
import 'inferred_type_test.dart' as inferred_type_test;
import 'non_null_checker_test.dart' as non_null_checker_test;

main() {
  defineReflectiveSuite(() {
    checker_test.main();
    front_end_inference_test.main();
    inferred_type_test.main();
    non_null_checker_test.main();
  }, name: 'strong');
}
