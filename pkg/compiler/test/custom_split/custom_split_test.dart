// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io' hide Link;
import 'package:async_helper/async_helper.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../deferred_loading/deferred_loading_test_helper.dart';

///  Add in options to pass to the compiler like
/// `Flags.disableTypeInference` or `Flags.disableInlining`
const List<String> compilerOptions = const [];

const List<String> tests = [
  'diamond',
  'diamond_and',
  'diamond_fuse',
  'two_step',
  'two_branch',
];

Map<String, List<String>> createPerTestOptions() {
  Map<String, List<String>> perTestOptions = {};
  for (var test in tests) {
    Uri dir = Platform.script.resolve('data/$test/constraints.json');
    perTestOptions['$test'] = ['--read-program-split=$dir'];
  }
  return perTestOptions;
}

/// Compute the [OutputUnit]s for all source files involved in the test, and
/// ensure that the compiler is correctly calculating what is used and what is
/// not. We expect all test entry points to be in the `data` directory and any
/// or all supporting libraries to be in the `libs` folder, starting with the
/// same name as the original file in `data`.
main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const OutputUnitDataComputer(),
        options: compilerOptions,
        perTestOptions: createPerTestOptions(),
        args: args, setUpFunction: () {
      importPrefixes.clear();
    }, testedConfigs: allSpecConfigs);
  });
}
