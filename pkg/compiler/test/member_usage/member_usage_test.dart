// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/universe/member_usage.dart';
import 'package:compiler/src/universe/resolution_world_builder.dart';
import 'package:compiler/src/util/enumset.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    print('------------------------------------------------------------------');
    print(' Test with enqueuer checks');
    print('------------------------------------------------------------------');
    await checkTests(dataDir, const ClosedWorldDataComputer(false),
        args: args, testedConfigs: allSpecConfigs);
    print('------------------------------------------------------------------');
    print(' Test without enqueuer checks');
    print('------------------------------------------------------------------');
    await checkTests(dataDir, const ClosedWorldDataComputer(true),
        args: args, testedConfigs: allSpecConfigs);
  });
}

class Tags {
  static const String init = 'init';
  static const String read = 'read';
  static const String write = 'write';
  static const String invoke = 'invoke';
}

class ClosedWorldDataComputer extends DataComputer<Features> {
  final bool skipEnqueuerCheck;

  const ClosedWorldDataComputer(this.skipEnqueuerCheck);

  @override
  void setup() {
    Enqueuer.skipEnqueuerCheckForTesting = skipEnqueuerCheck;
  }

  /// Compute a short textual representation of [access] on member.
  ///
  /// Dynamic access on instance members and static access on non-instance
  /// members is implicit, so we only annotate super access and static access
  /// not implied by dynamic or super access.
  String computeAccessText(MemberEntity member, EnumSet<Access> access,
      [String prefix]) {
    StringBuffer sb = new StringBuffer();
    String delimiter = '';
    if (prefix != null) {
      sb.write(prefix);
      delimiter = ':';
    }
    if (access.contains(Access.superAccess)) {
      sb.write(delimiter);
      sb.write('super');
    } else if (member.isInstanceMember &&
        access.contains(Access.staticAccess) &&
        !access.contains(Access.dynamicAccess)) {
      sb.write(delimiter);
      sb.write('static');
    }
    return sb.toString();
  }

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
    ResolutionWorldBuilderImpl resolutionWorldBuilder =
        compiler.resolutionWorldBuilderForTesting;
    ir.Member node = frontendStrategy.elementMap.getMemberNode(member);
    Features features = new Features();
    MemberUsage memberUsage =
        resolutionWorldBuilder.memberUsageForTesting[member];
    if (memberUsage != null) {
      if (member.isField && memberUsage.hasInit) {
        features.add(Tags.init);
      }
      if (memberUsage.hasRead) {
        features[Tags.read] = computeAccessText(member, memberUsage.reads);
      }
      if (memberUsage.hasWrite) {
        features[Tags.write] = computeAccessText(member, memberUsage.writes);
      }
      if (memberUsage.hasInvoke) {
        if (memberUsage is MethodUsage &&
            !memberUsage.parameterUsage.isFullyUsed) {
          features[Tags.invoke] = computeAccessText(member, memberUsage.invokes,
              memberUsage.invokedParameters.shortText);
        } else {
          features[Tags.invoke] =
              computeAccessText(member, memberUsage.invokes);
        }
      }
    }
    Id id = computeMemberId(node);
    ir.TreeNode nodeWithOffset = computeTreeNodeWithOffset(node);
    actualMap[id] = new ActualData<Features>(id, features,
        nodeWithOffset?.location?.file, nodeWithOffset?.fileOffset, member);
  }

  @override
  bool get testFrontend => true;

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}
