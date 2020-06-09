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
import 'package:compiler/src/js_model/js_world.dart';
import 'package:kernel/ast.dart' as ir;
import '../equivalence/id_equivalence.dart';
import '../equivalence/id_equivalence_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('jdata'));
    await checkTests(dataDir, const JAllocatorAnalysisDataComputer(),
        args: args, testedConfigs: allSpecConfigs);
  });
}

class Tags {
  static const String isInitializedInAllocator = 'allocator';
  static const String initialValue = 'initial';
  static const String constantValue = 'constant';
  static const String isEager = 'eager';
  static const String eagerCreationIndex = 'index';
  static const String isLazy = 'lazy';
  static const String isEffectivelyFinal = 'final';
  static const String isElided = 'elided';
}

class JAllocatorAnalysisDataComputer extends DataComputer<Features> {
  const JAllocatorAnalysisDataComputer();

  @override
  void computeMemberData(Compiler compiler, MemberEntity member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose: false}) {
    if (member.isField) {
      DartTypes dartTypes = compiler.frontendStrategy.commonElements.dartTypes;
      JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
      JFieldAnalysis fieldAnalysis = closedWorld.fieldAnalysis;
      ir.Member node = closedWorld.elementMap.getMemberDefinition(member).node;
      Features features = new Features();
      FieldAnalysisData fieldData = fieldAnalysis.getFieldData(member);
      if (fieldData.isElided && !fieldData.isEffectivelyConstant) {
        features.add(Tags.isElided);
      }
      if (fieldData.isInitializedInAllocator) {
        features.add(Tags.isInitializedInAllocator);
      }
      if (fieldData.isEffectivelyConstant) {
        features[Tags.constantValue] =
            fieldData.constantValue.toStructuredText(dartTypes);
      } else if (fieldData.initialValue != null) {
        features[Tags.initialValue] =
            fieldData.initialValue.toStructuredText(dartTypes);
      } else if (fieldData.isEager) {
        if (fieldData.eagerCreationIndex != null) {
          features[Tags.eagerCreationIndex] =
              fieldData.eagerCreationIndex.toString();
        }
        if (fieldData.eagerFieldDependenciesForTesting != null) {
          for (FieldEntity field
              in fieldData.eagerFieldDependenciesForTesting) {
            features.addElement(Tags.isEager, field.name);
          }
        } else {
          features.add(Tags.isEager);
        }
      }
      if (!member.isInstanceMember && fieldData.isLazy) {
        features.add(Tags.isLazy);
      }
      if (fieldData.isEffectivelyFinal && !fieldData.isEffectivelyConstant) {
        features.add(Tags.isEffectivelyFinal);
      }
      Id id = computeMemberId(node);
      ir.TreeNode nodeWithOffset = computeTreeNodeWithOffset(node);
      actualMap[id] = new ActualData<Features>(id, features,
          nodeWithOffset?.location?.file, nodeWithOffset?.fileOffset, member);
    }
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}
