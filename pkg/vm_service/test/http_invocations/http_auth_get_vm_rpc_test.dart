// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/service_test_common.dart';
import 'http_auth_get_vm_rpc_lib.dart' as testee_lib;
import 'http_get_vm_rpc_common.dart';

void main([args = const <String>[]]) {
  final harness = IsolateTestHarness(
    'http_auth_get_vm_rpc_lib.dart',
    args,
  );
  for (final test in httpGetVmRpcTests) {
    harness.addCustomTest(test);
  }
  harness.run(testeeMain: testee_lib.main, useAuthToken: true);
}
