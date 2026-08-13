// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analyzer_status_test.dart' as analyzer_status;
import 'diagnostic_test.dart' as diagnostic;
import 'dtd_test.dart' as dtd;
import 'initialization_test.dart' as initialization;
import 'server_test.dart' as server;
import 'workspace_analysis_complete_test.dart' as workspace_analysis_complete;

void main() {
  defineReflectiveSuite(() {
    analyzer_status.main();
    diagnostic.main();
    dtd.main();
    initialization.main();
    server.main();
    workspace_analysis_complete.main();
  }, name: 'lsp integration');
}
