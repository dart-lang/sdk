// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper program that shows the rti data on a dart program.

import 'package:args/args.dart';
import 'package:compiler/src/js_backend/runtime_types.dart';
import '../equivalence/id_equivalence_helper.dart';
import '../equivalence/show_helper.dart';
import 'rti_emission_test.dart';
import 'rti_need_test.dart';

main(List<String> args) async {
  cacheRtiDataForTesting = true;
  ArgParser argParser = createArgParser();
  argParser.addFlag('need', defaultsTo: true);
  argParser.addFlag('emission');
  ArgResults results = argParser.parse(args);

  ComputeMemberDataFunction computeAstData;
  ComputeMemberDataFunction computeKernelData;
  ComputeClassDataFunction computeAstClassData;
  ComputeClassDataFunction computeKernelClassData;
  if (results['emission']) {
    computeAstData = computeAstRtiMemberEmission;
    computeKernelData = computeKernelRtiMemberEmission;
    computeAstClassData = computeAstRtiClassEmission;
    computeKernelClassData = computeKernelRtiClassEmission;
  } else {
    computeAstData = computeAstRtiMemberNeed;
    computeKernelData = computeKernelRtiMemberNeed;
    computeAstClassData = computeAstRtiClassNeed;
    computeKernelClassData = computeKernelRtiClassNeed;
  }

  await show(results, computeAstData, computeKernelData,
      computeAstClassData: computeAstClassData,
      computeKernelClassData: computeKernelClassData);
}
