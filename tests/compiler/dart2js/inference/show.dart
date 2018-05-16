// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper program that shows the inferrer data on a dart program.

import 'package:args/args.dart';
import 'package:compiler/src/inferrer/inferrer_engine.dart';
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

  ComputeMemberDataFunction kernelFunction;
  if (results['side-effects']) {
    kernelFunction = computeMemberIrSideEffects;
  }
  if (results['callers']) {
    InferrerEngineImpl.retainDataForTesting = true;
    kernelFunction = computeMemberIrCallers;
  } else {
    InferrerEngineImpl.useSorterForTesting = true;
    kernelFunction = computeMemberIrTypeMasks;
  }
  await show(results, kernelFunction, options: [/*stopAfterTypeInference*/]);
}
