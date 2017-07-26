// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.closures_type_vars.suite;

import 'dart:async' show Future;
import 'package:testing/testing.dart' show Chain, runMe;
import '../closures/suite.dart' show ClosureConversionContext;

Future<ClosureConversionContext> createContext(
    Chain suite, Map<String, String> environment) async {
  environment["updateExpectations"] =
      const String.fromEnvironment("updateExpectations");
  return ClosureConversionContext.create(
      suite, environment, true /*strongMode*/);
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
