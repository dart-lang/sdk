// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/js_backend/allocator_analysis.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/util/features.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('kdata'));
    await checkTests(dataDir, const KAllocatorAnalysisDataComputer(),
        args: args, testOmit: false, testFrontend: true);
  });
}

class Tags {
  static const String initialValue = 'initial';
}

class KAllocatorAnalysisDataComputer extends DataComputer<Features> {
  const KAllocatorAnalysisDataComputer();

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    if (member.isField) {
      KernelFrontEndStrategy frontendStrategy = compiler.frontendStrategy;
      KAllocatorAnalysis allocatorAnalysis =
          compiler.backend.allocatorResolutionAnalysisForTesting;
      ir.Member node = frontendStrategy.elementMap.getMemberNode(member);
      ConstantValue initialValue =
          allocatorAnalysis.getFixedInitializerForTesting(member);
      Features features = new Features();
      if (initialValue != null) {
        features[Tags.initialValue] = initialValue.toStructuredText();
      }
      Id id = computeEntityId(node);
      actualMap[id] = new ActualData<Features>(
          id, features, computeSourceSpanFromTreeNode(node), member);
    }
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}
