// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_diagnostics_test.dart' as get_diagnostics_test;
import 'get_server_port_test.dart' as get_server_port_test;

main() {
  defineReflectiveSuite(() {
    get_diagnostics_test.main();
    get_server_port_test.main();
  }, name: 'diagnostics');
}
