// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';
import 'reload_sources_test_common.dart' show reloadSourcesTests, testeeMain;

void main([args = const <String>[]]) => runIsolateTests(
      args,
      reloadSourcesTests,
      'reload_sources_with_resident_compiler_test.dart',
      testeeConcurrent: testeeMain,
      shouldTesteeBeLaunchedWithDartRunResident: true,
    );
