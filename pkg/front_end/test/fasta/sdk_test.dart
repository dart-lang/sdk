// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.sdk_test;

import 'testing/suite.dart';

Future<FastaContext> createContext(
    Chain suite, Map<String, String> environment) async {
  environment[ENABLE_FULL_COMPILE] = "";
  environment["skipVm"] ??= "true";
  environment["onlyCrashes"] ??= "true";
  environment["ignoreExpectations"] ??= "true";
  return FastaContext.create(suite, environment);
}

main([List<String> arguments = const []]) => runMe(arguments, createContext);
