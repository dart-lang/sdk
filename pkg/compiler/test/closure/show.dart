// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Helper program that shows the closure data on a dart program.

import 'package:args/args.dart';
import '../equivalence/show_helper.dart';
import 'closure_test.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addFlag('inference', defaultsTo: true);
  argParser.addFlag('side-effects', defaultsTo: false);
  argParser.addFlag('callers', defaultsTo: false);
  ArgResults results = argParser.parse(args);

  await show(results, const ClosureDataComputer());
}
