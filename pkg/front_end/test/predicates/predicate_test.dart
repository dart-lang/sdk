// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/testing/id_extractor.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
  await runTests<Features>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const PredicateDataComputer(), [
        const TestConfig(cfeMarker, 'cfe',
            explicitExperimentalFlags: const {
              ExperimentalFlag.nonNullable: true
            },
            targetFlags: const TargetFlags(
                forceLateLoweringsForTesting: LateLowering.all))
      ]));
}

class Tags {
  static const String lateField = 'lateField';
  static const String lateIsSetField = 'lateIsSetField';
  static const String lateFieldGetter = 'lateFieldGetter';
  static const String lateFieldSetter = 'lateFieldSetter';

  static const String lateLocal = 'lateLocal';
  static const String lateIsSetLocal = 'lateIsSetLocal';
  static const String lateLocalGetter = 'lateLocalGetter';
  static const String lateLocalSetter = 'lateLocalSetter';

  static const String extensionThis = 'extensionThis';
}

class PredicateDataComputer extends DataComputer<Features> {
  const PredicateDataComputer();

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    new PredicateDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<Features>> actualMap,
      {bool verbose}) {
    member.accept(new PredicateDataExtractor(compilerResult, actualMap));
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class PredicateDataExtractor extends CfeDataExtractor<Features> {
  Map<String, Features> featureMap = {};
  Map<String, NodeId> nodeIdMap = {};

  PredicateDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<Features>> actualMap)
      : super(compilerResult, actualMap);

  @override
  Features computeLibraryValue(Id id, Library node) {
    return null;
  }

  @override
  Features computeMemberValue(Id id, Member node) {
    if (node is Field) {
      Features features = new Features();
      if (isLateLoweredField(node)) {
        features.add(Tags.lateField);
      }
      if (isLateLoweredIsSetField(node)) {
        features.add(Tags.lateIsSetField);
      }
      return features;
    } else if (node is Procedure) {
      Features features = new Features();
      if (isLateLoweredFieldGetter(node)) {
        features.add(Tags.lateFieldGetter);
      }

      if (isLateLoweredFieldSetter(node)) {
        features.add(Tags.lateFieldSetter);
      }
      return features;
    }
    return null;
  }

  void visitProcedure(Procedure node) {
    super.visitProcedure(node);
    nodeIdMap.forEach((String name, NodeId id) {
      Features features = featureMap[name];
      if (features != null) {
        TreeNode nodeWithOffset = computeTreeNodeWithOffset(node);
        registerValue(
            nodeWithOffset.location.file, id.value, id, features, name);
      }
    });
    nodeIdMap.clear();
    featureMap.clear();
  }

  void visitVariableDeclaration(VariableDeclaration node) {
    String name;
    String tag;
    if (isLateLoweredLocal(node)) {
      name = extractLocalNameFromLateLoweredLocal(node.name);
      tag = Tags.lateLocal;
    } else if (isLateLoweredIsSetLocal(node)) {
      name = extractLocalNameFromLateLoweredIsSet(node.name);
      tag = Tags.lateIsSetLocal;
    } else if (isLateLoweredLocalGetter(node)) {
      name = extractLocalNameFromLateLoweredGetter(node.name);
      tag = Tags.lateLocalGetter;
    } else if (isLateLoweredLocalSetter(node)) {
      name = extractLocalNameFromLateLoweredSetter(node.name);
      tag = Tags.lateLocalSetter;
    } else if (isExtensionThis(node)) {
      name = extractLocalNameForExtensionThis(node.name);
      tag = Tags.extensionThis;
    } else if (node.name != null) {
      name = node.name;
    }
    if (name != null) {
      if (node.fileOffset != TreeNode.noOffset) {
        nodeIdMap[name] ??= new NodeId(node.fileOffset, IdKind.node);
      }
      if (tag != null) {
        Features features = featureMap[name] ??= new Features();
        features.add(tag);
      }
    }
    super.visitVariableDeclaration(node);
  }

  @override
  ActualData<Features> mergeData(
      ActualData<Features> value1, ActualData<Features> value2) {
    if ('${value1.value}' == '${value2.value}') {
      // The extension this parameter is seen twice in the extension method
      // and the corresponding tearoff. The features are identical, though, so
      // we just use the first.
      return value1;
    }
    return null;
  }
}
