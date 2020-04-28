// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/js_backend/field_analysis.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('kdata'));
    await checkTests(dataDir, const KAllocatorAnalysisDataComputer(),
        args: args, testedConfigs: allSpecConfigs);
  });
}

class Tags {
  static const String initialValue = 'initial';
  static const String complexity = 'complexity';
}

class KAllocatorAnalysisDataComputer extends DataComputer<Features> {
  const KAllocatorAnalysisDataComputer();

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    if (member.isField) {
      KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
      DartTypes dartTypes = frontendStrategy.commonElements.dartTypes;
      KFieldAnalysis allocatorAnalysis =
          frontendStrategy.fieldAnalysisForTesting;
      ir.Member node = frontendStrategy.elementMap.getMemberNode(member);
      Features features = new Features();
      if (member.isInstanceMember) {
        AllocatorData data =
            allocatorAnalysis.getAllocatorDataForTesting(member);
        if (data != null) {
          if (data.initialValue != null) {
            features[Tags.initialValue] =
                data.initialValue.toStructuredText(dartTypes);
          }
          data.initializers.forEach((constructor, value) {
            features['${constructor.enclosingClass.name}.${constructor.name}'] =
                value?.shortText(dartTypes);
          });
        }
      } else {
        StaticFieldData staticFieldData =
            allocatorAnalysis.getStaticFieldDataForTesting(member);
        if (staticFieldData.initialValue != null) {
          features[Tags.initialValue] =
              staticFieldData.initialValue.toStructuredText(dartTypes);
        }
        features[Tags.complexity] = staticFieldData.complexity.shortText;
      }
      Id id = computeMemberId(node);
      ir.TreeNode nodeWithOffset = computeTreeNodeWithOffset(node);
      actualMap[id] = new ActualData<Features>(id, features,
          nodeWithOffset?.location?.file, nodeWithOffset?.fileOffset, member);
    }
  }

  @override
  bool get testFrontend => true;

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}
