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
            experimentalFlags: const {ExperimentalFlag.nonNullable: true},
            targetFlags: const TargetFlags(forceLateLoweringForTesting: true))
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
}
