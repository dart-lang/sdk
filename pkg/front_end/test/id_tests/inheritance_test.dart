// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;
import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, runTests;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:front_end/src/testing/id_testing_utils.dart';
import 'package:kernel/ast.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/inheritance/data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkersWithNnbd,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(
          const InheritanceDataComputer(), [cfeNonNullableOnlyConfig]));
}

class InheritanceDataComputer extends DataComputer<String> {
  const InheritanceDataComputer();

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(InternalCompilerResult compilerResult,
      Library library, Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new InheritanceDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  void computeClassData(InternalCompilerResult compilerResult, Class cls,
      Map<Id, ActualData<String>> actualMap,
      {bool verbose}) {
    new InheritanceDataExtractor(compilerResult, actualMap)
        .computeForClass(cls);
  }

  @override
  bool get supportsErrors => true;

  @override
  String computeErrorData(
      InternalCompilerResult compiler, Id id, List<FormattedMessage> errors) {
    return errorsToText(errors, useCodes: true);
  }

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();
}

class InheritanceDataExtractor extends CfeDataExtractor<String> {
  final ClassHierarchy _hierarchy;

  InheritanceDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<String>> actualMap)
      : _hierarchy = compilerResult.classHierarchy,
        super(compilerResult, actualMap);

  @override
  String computeLibraryValue(Id id, Library node) {
    return 'nnbd=${node.isNonNullableByDefault}';
  }

  @override
  String computeClassValue(Id id, Class node) {
    List<String> supertypes = <String>[];
    for (Class superclass in computeAllSuperclasses(node)) {
      Supertype supertype = _hierarchy.getClassAsInstanceOf(node, superclass);
      assert(supertype != null, "No instance of $superclass found for $node.");
      supertypes.add(
          supertypeToText(supertype, TypeRepresentation.implicitUndetermined));
    }
    supertypes.sort();
    return supertypes.join(',');
  }
}
