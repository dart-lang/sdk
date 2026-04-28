// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that require a fresh context to run, and can interfere with other
/// tests.
@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import 'refresh_common.dart';

void main() {
  final provider = TestSdkConfigurationProvider();
  tearDownAll(provider.dispose);

  testAll(provider: provider);
}
