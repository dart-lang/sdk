// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'configuration.dart';
import 'test_suite.dart';

class VMTestSuite extends CCTestSuite {
  VMTestSuite(Configuration configuration)
      : super(
            configuration, "vm", "run_vm_tests", ["runtime/tests/vm/vm.status"],
            testPrefix: 'cc/');
}
