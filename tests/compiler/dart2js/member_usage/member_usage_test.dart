// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/universe/member_usage.dart';
import 'package:compiler/src/universe/resolution_world_builder.dart';
import 'package:compiler/src/util/features.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const ClosedWorldDataComputer(),
        args: args, testOmit: false, testFrontend: true);
  });
}

class Tags {
  static const String read = 'read';
  static const String write = 'write';
  static const String invoke = 'invoke';
}

class ClosedWorldDataComputer extends DataComputer<Features> {
  const ClosedWorldDataComputer();

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    KernelFrontEndStrategy frontendStrategy = compiler.frontendStrategy;
    ResolutionWorldBuilderImpl resolutionWorldBuilder =
        compiler.resolutionWorldBuilder;
    ir.Member node = frontendStrategy.elementMap.getMemberNode(member);
    Features features = new Features();
    MemberUsage memberUsage =
        resolutionWorldBuilder.memberUsageForTesting[member];
    if (memberUsage != null) {
      if (memberUsage.hasRead) {
        features.add(Tags.read);
      }
      if (memberUsage.hasWrite) {
        features.add(Tags.write);
      }
      if (memberUsage.isFullyInvoked) {
        features.add(Tags.invoke);
      } else if (memberUsage.hasInvoke) {
        features[Tags.invoke] = memberUsage.invokedParameters.shortText;
      }
    }
    Id id = computeEntityId(node);
    actualMap[id] = new ActualData<Features>(
        id, features, computeSourceSpanFromTreeNode(node), member);
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}
