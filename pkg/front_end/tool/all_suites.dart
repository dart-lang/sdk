// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:testing/src/chain.dart' show CreateContext;
import 'package:testing/src/run.dart' show runSuites;
import 'package:testing/src/run_tests.dart' show CommandLine;
import 'package:testing/src/test_root.dart' show TestRoot;
import 'package:testing/testing.dart';

import '../test/unit_test_suites.dart';

Future<Null> main(List<String> arguments) async {
  CommandLine cl = CommandLine.parse(arguments);
  Map<String, CreateContext> suiteMap = {};
  for (MapEntry<String, Suite> entry in suites.entries) {
    suiteMap[entry.key] = entry.value.createContext;
  }
  TestRoot testRoot =
      await TestRoot.fromUri(Uri.base.resolve('pkg/front_end/testing.json'));
  await runSuites(cl, testRoot, suiteMap);
}
