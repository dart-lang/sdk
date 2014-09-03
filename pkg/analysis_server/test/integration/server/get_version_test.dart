// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.server.get.version;


import '../../reflective_tests.dart';

import '../integration_tests.dart';

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_getVersion() {
    return sendServerGetVersion();
  }
}

main() {
  runReflectiveTests(Test);
}
