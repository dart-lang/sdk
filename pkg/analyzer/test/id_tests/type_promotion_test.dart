// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) async {
  Directory dataDir = Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/flow_analysis/type_promotion/'
          'data'));
  await NullSafetyUnderstandingFlag.enableNullSafetyTypes(() {
    return runTests<DartType>(dataDir,
        args: args,
        createUriForFileName: createUriForFileName,
        onFailure: onFailure,
        runTest: runTestFor(
            const _TypePromotionDataComputer(), [analyzerNnbdConfig]));
  });
}

class _TypePromotionDataComputer extends DataComputer<DartType> {
  const _TypePromotionDataComputer();

  @override
  DataInterpreter<DartType> get dataValidator =>
      const _TypePromotionDataInterpreter();

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<DartType>> actualMap) {
    _TypePromotionDataExtractor(unit.declaredElement.source.uri, actualMap)
        .run(unit);
  }
}

class _TypePromotionDataExtractor extends AstDataExtractor<DartType> {
  _TypePromotionDataExtractor(Uri uri, Map<Id, ActualData<DartType>> actualMap)
      : super(uri, actualMap);

  @override
  DartType computeNodeValue(Id id, AstNode node) {
    if (node is SimpleIdentifier && node.inGetterContext()) {
      var element = node.staticElement;
      if (element is LocalVariableElement || element is ParameterElement) {
        TypeImpl promotedType = node.staticType;
        TypeImpl declaredType = (element as VariableElement).type;
        var isPromoted = promotedType != declaredType;
        if (isPromoted) {
          return promotedType;
        }
      }
    }
    return null;
  }
}

class _TypePromotionDataInterpreter implements DataInterpreter<DartType> {
  const _TypePromotionDataInterpreter();

  @override
  String getText(DartType actualData, [String indentation]) {
    if (actualData is TypeParameterTypeImpl) {
      var element = actualData.element;
      var promotedBound = actualData.promotedBound;
      if (promotedBound != null) {
        return '${element.name} & ${_typeToString(promotedBound)}';
      }
    }
    return _typeToString(actualData);
  }

  @override
  String isAsExpected(DartType actualData, String expectedData) {
    var actualDataText = getText(actualData);
    if (actualDataText == expectedData) {
      return null;
    } else {
      return 'Expected $expectedData, got $actualDataText';
    }
  }

  @override
  bool isEmpty(DartType actualData) => actualData == null;

  String _typeToString(DartType type) {
    return type.getDisplayString(withNullability: true);
  }
}
