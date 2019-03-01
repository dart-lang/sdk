// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'list_literal_test.dart' as list_literal;
import 'map_literal_test.dart' as map_literal;
import 'set_literal_test.dart' as set_literal;

main() {
  defineReflectiveSuite(() {
    list_literal.main();
    map_literal.main();
    set_literal.main();
  }, name: 'type inference');
}
