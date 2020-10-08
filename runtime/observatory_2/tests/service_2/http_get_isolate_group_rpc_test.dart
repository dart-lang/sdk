// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'http_get_isolate_group_rpc_common.dart';
import 'test_helper.dart';

main(args) {
  runIsolateTests(args, tests,
      testeeBefore: testeeBefore,
      // the testee is responsible for starting the
      // web server.
      testeeControlsServer: true);
}
