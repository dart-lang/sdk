// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';
import 'package:front_end/src/testing/id.dart' show ActualData, Id;
import 'package:front_end/src/testing/id_testing.dart';
import 'package:test/test.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = new Directory.fromUri(Platform.script
      .resolve('../../../front_end/test/flow_analysis/nullability/data'));
  await runTests(dataDir,
      args: args,
      supportedMarkers: sharedMarkers,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest:
          runTestFor(const _NullabilityDataComputer(), [analyzerNnbdConfig]));
}

class FlowTestBase {
  FlowAnalysisResult flowResult;

  /// Resolve the given [code] and track nullability in the unit.
  Future<void> trackCode(String code) async {
    if (await checkTests(
        code,
        const _NullabilityDataComputer(),
        FeatureSet.forTesting(
            sdkVersion: '2.2.2', additionalFeatures: [Feature.non_nullable]))) {
      fail('Failure(s)');
    }
  }
}

class _NullabilityDataComputer extends DataComputer<String> {
  const _NullabilityDataComputer();

  @override
  DataInterpreter<String> get dataValidator =>
      const _NullabilityDataInterpreter();

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<String>> actualMap) {
    _NullabilityDataExtractor(unit.declaredElement.source.uri, actualMap,
            unit.declaredElement.context.typeSystem)
        .run(unit);
  }
}

class _NullabilityDataExtractor extends AstDataExtractor<String> {
  final TypeSystem _typeSystem;

  _NullabilityDataExtractor(
      Uri uri, Map<Id, ActualData<String>> actualMap, this._typeSystem)
      : super(uri, actualMap);

  @override
  String computeNodeValue(Id id, AstNode node) {
    if (node is SimpleIdentifier && node.inGetterContext()) {
      var element = node.staticElement;
      if (element is LocalVariableElement || element is ParameterElement) {
        TypeImpl promotedType = node.staticType;
        TypeImpl declaredType = (element as VariableElement).type;
        var isPromoted = promotedType != declaredType;
        if (isPromoted &&
            _typeSystem.isNullable(declaredType) &&
            !_typeSystem.isNullable(promotedType)) {
          return 'nonNullable';
        }
      }
    }
    return null;
  }
}

class _NullabilityDataInterpreter implements DataInterpreter<String> {
  const _NullabilityDataInterpreter();

  @override
  String getText(String actualData) => actualData;

  @override
  String isAsExpected(String actualData, String expectedData) {
    if (actualData == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualData';
    }
  }

  @override
  bool isEmpty(String actualData) => actualData.isEmpty;
}
