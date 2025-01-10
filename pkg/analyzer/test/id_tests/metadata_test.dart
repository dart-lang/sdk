// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:_fe_analyzer_shared/src/testing/metadata_helper.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/summary2/macro_metadata.dart';
import 'package:analyzer/src/util/ast_data_extractor.dart';

import '../util/id_testing_helper.dart';

main(List<String> args) {
  Directory dataDir = Directory.fromUri(Platform.script
      .resolve('../../../_fe_analyzer_shared/test/metadata/data'));
  return runTests<String>(
    dataDir,
    args: args,
    createUriForFileName: createUriForFileName,
    onFailure: onFailure,
    runTest: runTestFor(const _MetadataDataComputer(), [analyzerDefaultConfig]),
    preserveWhitespaceInAnnotations: true,
  );
}

class _MetadataDataComputer extends DataComputer<String> {
  const _MetadataDataComputer();

  @override
  DataInterpreter<String> get dataValidator => const StringDataInterpreter();

  @override
  bool get supportsErrors => true;

  @override
  void computeUnitData(TestingData testingData, CompilationUnit unit,
      Map<Id, ActualData<String>> actualMap) {
    var unitUri = unit.declaredFragment!.source.uri;
    _MetadataDataExtractor(unitUri, actualMap).run(unit);
  }
}

class _MetadataDataExtractor extends AstDataExtractor<String> {
  final inheritance = InheritanceManager3();

  _MetadataDataExtractor(super.uri, super.actualMap);

  @override
  String? computeNodeValue(Id id, AstNode node) {
    if (node is Declaration) {
      var element = node.declaredFragment?.element;
      if (element case Annotatable annotatable) {
        List<String> list = [];
        for (var annotation in annotatable.metadata2.annotations) {
          if (annotation is ElementAnnotationImpl) {
            var unresolved =
                parseAnnotation(annotation, delayLookupForTesting: true);
            var resolved = parseAnnotation(annotation);
            list.addAll(
                expressionsToText(unresolved: unresolved, resolved: resolved));
          }
        }
        if (list.isNotEmpty) {
          return '\n${list.join('\n')}';
        }
      }
    }
    return null;
  }
}
