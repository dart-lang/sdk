// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'create_context_test.dart' as create_context_test;
import 'delete_context_test.dart' as delete_context_test;
import 'map_uri_test.dart' as map_uri_test;
import 'set_subscriptions_test.dart' as set_subscription_test;

main() {
  defineReflectiveSuite(() {
    create_context_test.main();
    delete_context_test.main();
    map_uri_test.main();
    set_subscription_test.main();
  }, name: 'execution');
}
