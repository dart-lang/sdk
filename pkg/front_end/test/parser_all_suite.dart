// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:testing/testing.dart' show Chain, ChainContext, runMe;

import 'parser_suite.dart';

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new ContextChecksOnly(suite.name);
}
