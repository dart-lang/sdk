// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverTest_Kernel);
  });
}

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

@reflectiveTest
class AnalysisDriverTest_Kernel extends AnalysisDriverTest {
  @override
  bool get previewDart2 => true;

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_addFile_shouldRefresh() async {
    await super.test_addFile_shouldRefresh();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_asyncChangesDuringAnalysis_getErrors() async {
    await super.test_asyncChangesDuringAnalysis_getErrors();
//    @7: Expected a class body, but got ''.
//    null
//    #0      Listener.handleUnrecoverableError (package:front_end/src/fasta/parser/listener.dart:1179:5)
//    #1      Parser.reportUnrecoverableErrorWithToken (package:front_end/src/fasta/parser/parser.dart:5709:23)
//    #2      Parser.skipClassBody (package:front_end/src/fasta/parser/parser.dart:3149:14)
//    #3      TopLevelParser.parseClassBody (package:front_end/src/fasta/parser/top_level_parser.dart:18:58)
//    #4      Parser.parseClass (package:front_end/src/fasta/parser/parser.dart:1381:13)
//    #5      Parser.parseClassOrNamedMixinApplication (package:front_end/src/fasta/parser/parser.dart:1342:14)
//    #6      Parser.parseTopLevelKeywordDeclaration (package:front_end/src/fasta/parser/parser.dart:438:14)
//    #7      Parser.parseTopLevelDeclarationImpl (package:front_end/src/fasta/parser/parser.dart:365:14)
//    #8      Parser.parseUnit (package:front_end/src/fasta/parser/parser.dart:308:15)
//    #9      computeUnlinkedUnit (package:front_end/src/incremental/unlinked_unit.dart:25:32)
//    #10     FileState.refresh (package:front_end/src/incremental/file_state.dart:208:23)
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_asyncChangesDuringAnalysis_resultsStream() async {
    await super.test_asyncChangesDuringAnalysis_resultsStream();
//    @7: Expected a class body, but got ''.
//    null
//    #0      Listener.handleUnrecoverableError (package:front_end/src/fasta/parser/listener.dart:1179:5)
//    #1      Parser.reportUnrecoverableErrorWithToken (package:front_end/src/fasta/parser/parser.dart:5709:23)
//    #2      Parser.skipClassBody (package:front_end/src/fasta/parser/parser.dart:3149:14)
//    #3      TopLevelParser.parseClassBody (package:front_end/src/fasta/parser/top_level_parser.dart:18:58)
//    #4      Parser.parseClass (package:front_end/src/fasta/parser/parser.dart:1381:13)
//    #5      Parser.parseClassOrNamedMixinApplication (package:front_end/src/fasta/parser/parser.dart:1342:14)
//    #6      Parser.parseTopLevelKeywordDeclaration (package:front_end/src/fasta/parser/parser.dart:438:14)
//    #7      Parser.parseTopLevelDeclarationImpl (package:front_end/src/fasta/parser/parser.dart:365:14)
//    #8      Parser.parseUnit (package:front_end/src/fasta/parser/parser.dart:308:15)
//    #9      computeUnlinkedUnit (package:front_end/src/incremental/unlinked_unit.dart:25:32)
//    #10     FileState.refresh (package:front_end/src/incremental/file_state.dart:208:23)
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_changeFile_selfConsistent() async {
    await super.test_changeFile_selfConsistent();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_const_annotation_withArgs() async {
    await super.test_const_annotation_withArgs();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_const_circular_reference() async {
    await super.test_const_circular_reference();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_const_dependency_sameUnit() async {
    await super.test_const_dependency_sameUnit();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_const_externalConstFactory() async {
    await super.test_const_externalConstFactory();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_const_implicitSuperConstructorInvocation() async {
    await super.test_const_implicitSuperConstructorInvocation();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_errors_uriDoesNotExist_export() async {
    await super.test_errors_uriDoesNotExist_export();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_errors_uriDoesNotExist_import() async {
    await super.test_errors_uriDoesNotExist_import();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_errors_uriDoesNotExist_import_deferred() async {
    await super.test_errors_uriDoesNotExist_import_deferred();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_errors_uriDoesNotExist_part() async {
    await super.test_errors_uriDoesNotExist_part();
  }

  @override
  test_externalSummaries() {
    // Skipped by design.
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getErrors() async {
    await super.test_getErrors();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getIndex() async {
    await super.test_getIndex();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_constants_defaultParameterValue_localFunction() async {
    await super.test_getResult_constants_defaultParameterValue_localFunction();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_errors() async {
    await super.test_getResult_errors();
  }

  test_getResult_hasResolution_localVariable() async {
    String content = r'''
void main() {
  var v = 42;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, isEmpty);

    FunctionDeclaration main = result.unit.declarations[0];
    expect(main.element, isNotNull);
    expect(main.name.staticElement, isNotNull);
    expect(main.name.staticType.toString(), '() → void');

    BlockFunctionBody body = main.functionExpression.body;
    VariableDeclarationStatement statement = body.block.statements[0];
    VariableDeclaration vNode = statement.variables.variables[0];
    expect(vNode.name.staticType.toString(), 'int');
    expect(vNode.initializer.staticType.toString(), 'int');

    VariableElement vElement = vNode.name.staticElement;
    expect(vElement, isNotNull);
    expect(vElement.type, isNotNull);
    expect(vElement.type.toString(), 'int');
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_importLibrary_thenRemoveIt() async {
    await super.test_getResult_importLibrary_thenRemoveIt();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalid_annotation_functionAsConstructor() async {
    await super.test_getResult_invalid_annotation_functionAsConstructor();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalidUri() async {
    await super.test_getResult_invalidUri();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalidUri_exports_dart() async {
    await super.test_getResult_invalidUri_exports_dart();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalidUri_imports_dart() async {
    await super.test_getResult_invalidUri_imports_dart();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalidUri_metadata() async {
    await super.test_getResult_invalidUri_metadata();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_mix_fileAndPackageUris() async {
    await super.test_getResult_mix_fileAndPackageUris();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31409')
  @override
  test_getResult_nameConflict_local() async {
    await super.test_getResult_nameConflict_local();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31409')
  @override
  test_getResult_nameConflict_local_typeInference() async {
    await super.test_getResult_nameConflict_local_typeInference();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_selfConsistent() async {
    await super.test_getResult_selfConsistent();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  @override
  test_part_getResult_noLibrary() async {
    await super.test_part_getResult_noLibrary();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  @override
  test_part_getUnitElement_noLibrary() async {
    fail('This test fails even with @failingTest');
    await super.test_part_getUnitElement_noLibrary();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  @override
  test_part_results_afterLibrary() async {
    await super.test_part_results_afterLibrary();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  @override
  test_part_results_noLibrary() async {
    await super.test_part_results_noLibrary();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_removeFile_invalidate_importers() async {
    await super.test_removeFile_invalidate_importers();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_results_order() async {
    await super.test_results_order();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
