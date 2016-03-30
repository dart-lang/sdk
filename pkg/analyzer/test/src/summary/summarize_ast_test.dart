// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summarize_ast_test;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'summary_common.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(LinkedSummarizeAstSpecTest);
}

@reflectiveTest
class LinkedSummarizeAstSpecTest extends LinkedSummarizeAstTest {
  @override
  bool get strongMode => false;

  @override
  test_bottom_reference_shared() {
    // TODO(paulberry): fix.
  }

  @override
  test_closure_executable_with_bottom_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_closure_executable_with_imported_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_closure_executable_with_return_type_from_closure() {
    // TODO(paulberry): fix.
  }

  @override
  test_closure_executable_with_unimported_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_field_propagated_type_final_immediate() {
    // TODO(paulberry): fix.
  }

  @override
  test_fully_linked_references_follow_other_references() {
    // TODO(paulberry): fix.
  }

  @override
  test_implicit_dependencies_follow_other_dependencies() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_bottom_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_imported_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_return_type_from_closure() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_return_type_from_closure_field() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_return_type_from_closure_local() {
    // TODO(paulberry): fix.
  }

  @override
  test_initializer_executable_with_unimported_return_type() {
    // TODO(paulberry): fix.
  }

  @override
  test_linked_reference_reuse() {
    // TODO(paulberry): fix.
  }

  @override
  test_linked_type_dependency_reuse() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_inGenericClass() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_inGenericFunction() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_noArguments() {
    // TODO(paulberry): fix.
  }

  @override
  test_syntheticFunctionType_withArguments() {
    // TODO(paulberry): fix.
  }

  @override
  test_variable_propagated_type_final_immediate() {
    // TODO(paulberry): fix.
  }

  @override
  test_variable_propagated_type_new_reference() {
    // TODO(paulberry): fix.
  }

  @override
  test_variable_propagated_type_omit_dynamic() {
    // TODO(paulberry): fix.
  }
}

/**
 * Override of [SummaryTest] which creates linked summaries directly from the
 * AST.
 */
@reflectiveTest
abstract class LinkedSummarizeAstTest extends Object with SummaryTest {
  @override
  LinkedLibrary linked;

  @override
  List<UnlinkedUnit> unlinkedUnits;

  /**
   * Map from absolute URI to the [UnlinkedUnit] for each compilation unit
   * passed to [addNamedSource].
   */
  Map<String, UnlinkedUnit> uriToUnit = <String, UnlinkedUnit>{};

  @override
  bool get checkAstDerivedData => true;

  @override
  bool get expectAbsoluteUrisInDependencies => false;

  @override
  bool get skipFullyLinkedData => false;

  @override
  addNamedSource(String filePath, String contents) {
    CompilationUnit unit = _parseText(contents);
    UnlinkedUnit unlinkedUnit =
        new UnlinkedUnit.fromBuffer(serializeAstUnlinked(unit).toBuffer());
    uriToUnit[absUri(filePath)] = unlinkedUnit;
  }

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    Uri testDartUri = Uri.parse(absUri('/test.dart'));
    CompilationUnit unit = _parseText(text);
    UnlinkedUnit definingUnit =
        new UnlinkedUnit.fromBuffer(serializeAstUnlinked(unit).toBuffer());
    uriToUnit[testDartUri.toString()] = definingUnit;
    LinkedLibrary getDependency(String absoluteUri) {
      Map<String, LinkedLibrary> sdkLibraries =
          SerializedMockSdk.instance.uriToLinkedLibrary;
      LinkedLibrary linkedLibrary = sdkLibraries[absoluteUri];
      if (linkedLibrary == null && !allowMissingFiles) {
        fail('Linker unexpectedly requested LinkedLibrary for "$absoluteUri".'
            '  Libraries available: ${sdkLibraries.keys}');
      }
      return linkedLibrary;
    }
    UnlinkedUnit getUnit(String absoluteUri) {
      UnlinkedUnit unit = uriToUnit[absoluteUri] ??
          SerializedMockSdk.instance.uriToUnlinkedUnit[absoluteUri];
      if (unit == null && !allowMissingFiles) {
        fail('Linker unexpectedly requested unit for "$absoluteUri".');
      }
      return unit;
    }
    linked = link(uriToUnit.keys.toSet(), getDependency, getUnit)[
        testDartUri.toString()];
    expect(linked, isNotNull);
    validateLinkedLibrary(linked);
    unlinkedUnits = <UnlinkedUnit>[definingUnit];
    for (String relativeUri in definingUnit.publicNamespace.parts) {
      UnlinkedUnit unit = uriToUnit[
          resolveRelativeUri(testDartUri, Uri.parse(relativeUri)).toString()];
      if (unit == null) {
        if (!allowMissingFiles) {
          fail('Test referred to unknown unit $relativeUri');
        }
      } else {
        unlinkedUnits.add(unit);
      }
    }
  }

  test_class_no_superclass() {
    UnlinkedClass cls = serializeClassText('part of dart.core; class Object {}',
        className: 'Object');
    expect(cls.supertype, isNull);
    expect(cls.hasNoSupertype, isTrue);
  }

  CompilationUnit _parseText(String text) {
    CharSequenceReader reader = new CharSequenceReader(text);
    Scanner scanner =
        new Scanner(null, reader, AnalysisErrorListener.NULL_LISTENER);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, AnalysisErrorListener.NULL_LISTENER);
    parser.parseGenericMethods = true;
    return parser.parseCompilationUnit(token);
  }
}
