// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis/test_all.dart' as analysis;
import 'analytics/test_all.dart' as analytics;
import 'completion/test_all.dart' as completion;
import 'coverage_test.dart' as coverage_test;
import 'diagnostic/test_all.dart' as diagnostic;
import 'edit/test_all.dart' as edit;
import 'execution/test_all.dart' as execution;
import 'kythe/test_all.dart' as kythe;
import 'linter/test_all.dart' as linter;
import 'lsp_server/test_all.dart' as lsp_server;
import 'search/test_all.dart' as search;
import 'server/test_all.dart' as server;

void main() {
  defineReflectiveSuite(() {
    analysis.main();
    analytics.main();
    completion.main();
    coverage_test.main();
    diagnostic.main();
    edit.main();
    execution.main();
    kythe.main();
    linter.main();
    lsp_server.main();
    search.main();
    server.main();
  }, name: 'analysis_server_integration');
}
