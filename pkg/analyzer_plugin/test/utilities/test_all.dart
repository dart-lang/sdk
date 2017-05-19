// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analyzer_converter_test.dart' as analyzer_converter_test;
import 'range_factory_test.dart' as range_factory_test;
import 'subscriptions/test_all.dart' as subscriptions;

main() {
  defineReflectiveSuite(() {
    analyzer_converter_test.main();
    range_factory_test.main();
    subscriptions.main();
  }, name: 'utilities');
}
