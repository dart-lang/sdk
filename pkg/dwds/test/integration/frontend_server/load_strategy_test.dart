// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds_test_common/integration/load_strategy.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import '../fixtures/frontend_server_context.dart';

void main() {
  final provider = TestSdkConfigurationProvider();
  tearDownAll(provider.dispose);

  group('Frontend Server |', () {
    testAll(provider: provider, contextFactory: FrontendServerTestContext.new);
  });
}
