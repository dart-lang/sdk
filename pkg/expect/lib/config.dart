// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Access to the runner configuration this test is running in.
///
/// Provides queries against and properties of the current configuration
/// that a test is being compiled and executed in.
///
/// This library is separate from `expect.dart` because it uses
/// `fromEnvironment` constants that cannot be precompiled,
/// and we precompile `expect.dart`.

library expect_config;

import 'package:smith/smith.dart';

final Configuration _configuration = Configuration.parse(
    const String.fromEnvironment("test_runner.configuration"),
    <String, dynamic>{});

bool get isDart2jsConfiguration {
  return _configuration.compiler == Compiler.dart2js;
}

bool get isDdcConfiguration {
  return _configuration.compiler == Compiler.dartdevk ||
      _configuration.compiler == Compiler.dartdevc;
}

bool get isVmAotConfiguration {
  return _configuration.compiler == Compiler.dartkp;
}
