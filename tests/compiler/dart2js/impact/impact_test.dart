// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/util.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/universe/feature.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/util/features.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(dataDir, const ImpactDataComputer(),
        args: args, testOmit: false, testFrontend: true);
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

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    KernelFrontEndStrategy frontendStrategy = compiler.frontendStrategy;
    WorldImpact impact = compiler.impactCache[member];
    ir.Member node = frontendStrategy.elementMap.getMemberNode(member);
    Features features = new Features();
    if (impact.typeUses.length > 50) {
      features.addElement(Tags.typeUse, '*');
    } else {
      for (TypeUse use in impact.typeUses) {
        features.addElement(Tags.typeUse, use.shortText);
      }
    }
    if (impact.staticUses.length > 50) {
      features.addElement(Tags.staticUse, '*');
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
    if (impact is TransformedWorldImpact &&
        impact.worldImpact is ResolutionImpact) {
      ResolutionImpact resolutionImpact = impact.worldImpact;
      for (RuntimeTypeUse use in resolutionImpact.runtimeTypeUses) {
        features.addElement(Tags.runtimeTypeUse, use.shortText);
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
