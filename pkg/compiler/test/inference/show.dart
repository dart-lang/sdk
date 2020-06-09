// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Helper program that shows the inferrer data on a dart program.

import 'package:args/args.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../equivalence/show_helper.dart';
import 'inference_test_helper.dart';
import 'side_effects_test.dart';
import 'callers_test.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  argParser.addFlag('inference', defaultsTo: true);
  argParser.addFlag('side-effects', defaultsTo: false);
  argParser.addFlag('callers', defaultsTo: false);
  ArgResults results = argParser.parse(args);

  DataComputer<String> dataComputer;
  if (results['side-effects']) {
    dataComputer = const SideEffectsDataComputer();
  }
  if (results['callers']) {
    dataComputer = const CallersDataComputer();
  } else {
    dataComputer = const TypeMaskDataComputer();
  }
  await show<String>(results, dataComputer,
      options: [/*stopAfterTypeInference*/]);
}
