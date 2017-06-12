// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'change_builder/test_all.dart' as change_builder;
import 'completion/test_all.dart' as completion;
import 'navigation/test_all.dart' as navigation;
import 'string_utilities_test.dart' as string_utilities;
import 'visitors/test_all.dart' as visitors;

main() {
  defineReflectiveSuite(() {
    change_builder.main();
    completion.main();
    navigation.main();
    string_utilities.main();
    visitors.main();
  }, name: 'utilities');
}
