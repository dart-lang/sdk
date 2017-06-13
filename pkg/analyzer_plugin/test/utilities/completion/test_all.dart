// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'inherited_reference_contributor_test.dart'
    as inherited_reference_contributor_test;
import 'type_member_contributor_test.dart' as type_member_contributor_test;

main() {
  defineReflectiveSuite(() {
    inherited_reference_contributor_test.main();
    type_member_contributor_test.main();
  }, name: 'subscriptions');
}
