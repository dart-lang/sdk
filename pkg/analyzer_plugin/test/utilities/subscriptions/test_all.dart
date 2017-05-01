// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'subscription_manager_test.dart' as subscription_manager_test;

main() {
  defineReflectiveSuite(() {
    subscription_manager_test.main();
  }, name: 'subscriptions');
}
