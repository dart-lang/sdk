// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/ir/impact.dart';
import 'package:compiler/src/ir/runtime_type_analysis.dart';
import 'package:compiler/src/universe/feature.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    print('Testing computation of WorldImpact through ImpactData');
    print('==================================================================');
    await checkTests(dataDir, const ImpactDataComputer(),
        args: args, testedConfigs: allSpecConfigs);
  });
}

class Tags {
  static const String typeUse = 'type';
  static const String staticUse = 'static';
  static const String dynamicUse = 'dynamic';
  static const String constantUse = 'constant';
  static const String runtimeTypeUse = 'runtimeType';
}

class ImpactDataComputer extends DataComputer<Features> {
  const ImpactDataComputer();

  static const String wildcard = '%';

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose = false}) {
    KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
    WorldImpact impact = compiler.impactCache[member]!;
    ir.Member node = frontendStrategy.elementMap.getMemberNode(member);
    Features features = new Features();
    if (impact.typeUses.length > 50) {
      features.addElement(Tags.typeUse, wildcard);
    } else {
      for (TypeUse use in impact.typeUses) {
        features.addElement(Tags.typeUse, use.shortText);
      }
    }
    if (impact.staticUses.length > 50) {
      features.addElement(Tags.staticUse, wildcard);
    } else {
      for (StaticUse use in impact.staticUses) {
        features.addElement(Tags.staticUse, use.shortText);
      }
    }
    for (DynamicUse use in impact.dynamicUses) {
      features.addElement(Tags.dynamicUse, use.shortText);
    }
    for (ConstantUse use in impact.constantUses) {
      features.addElement(Tags.constantUse, use.shortText);
    }
    final impactData = frontendStrategy.elementMap.impactDataForTesting![node]!;
    impactData.apply(ImpactDataGoldener(frontendStrategy.elementMap, features));
    Id id = computeMemberId(node);
    ir.TreeNode nodeWithOffset = computeTreeNodeWithOffset(node)!;
    actualMap[id] = new ActualData<Features>(id, features,
        nodeWithOffset.location!.file, nodeWithOffset.fileOffset, member);
  }

  @override
  bool get testFrontend => true;

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter(wildcard: wildcard);
}

class ImpactDataGoldener implements ImpactRegistry {
  final KernelToElementMap elementMap;
  final Features features;

  ImpactDataGoldener(this.elementMap, this.features);

  @override
  void registerRuntimeTypeUse(RuntimeTypeUseKind kind, ir.DartType receiverType,
      ir.DartType? argumentType) {
    final runtimeTypeUse = RuntimeTypeUse(
        kind,
        elementMap.getDartType(receiverType),
        argumentType == null ? null : elementMap.getDartType(argumentType));
    features.addElement(Tags.runtimeTypeUse, runtimeTypeUse.shortText);
  }

  @override
  noSuchMethod(_) {}
}
