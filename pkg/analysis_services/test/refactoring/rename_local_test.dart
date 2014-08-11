// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.refactoring.rename_local;

import 'package:analysis_services/correction/change.dart';
import 'package:analysis_services/correction/status.dart';
import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/index/local_memory_index.dart';
import 'package:analysis_services/refactoring/refactoring.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analysis_services/src/correction/source_range.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';



main() {
  groupSep = ' | ';
  runReflectiveTests(RenameLocalTest);
}


@ReflectiveTestCase()
class RenameLocalTest extends RenameRefactoringTest {
  void test_createChange_localVariable() {
    indexTestUnit('''
main() {
  int test = 0;
  test = 1;
  test += 2;
  print(test);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test = 0');
    print(refactoring.refactoringName);
    expect(refactoring.refactoringName, 'Rename Local Variable');
    refactoring.newName = 'newName';
    // validate change
    // TODO(scheglov)
//    assertSuccessfulRename(
//        "// filler filler filler filler filler filler filler filler filler filler",
//        "main() {",
//        "  int newName = 0;",
//        "  newName = 1;",
//        "  newName += 2;",
//        "  print(newName);",
//        "}");
  }
}


/**
 * The base class for all [RenameRefactoring] tests.
 *
 * TODO(scheglov) extract
 */
class RenameRefactoringTest extends AbstractSingleUnitTest {
  Index index;
  SearchEngineImpl searchEngine;

  RenameRefactoring refactoring;
  Change refactoringChange;

  /**
   * Creates a new [RenameRefactoring] in [refactoringC] for the [Element] of
   * the [SimpleIdentifier] at the given [search] pattern.
   */
  void createRenameRefactoringAtString(String search) {
    SimpleIdentifier identifier = findIdentifier(search);
    Element element = identifier.bestElement;
    // TODO(scheglov) uncomment later
//    if (element instanceof PrefixElement) {
//      element = IndexContributor.getImportElement(identifier);
//    }
    refactoring = new RenameRefactoring(searchEngine, element);
    expect(refactoring, isNotNull);
  }

  void indexTestUnit(String code) {
    resolveTestUnit(code);
    index.indexUnit(context, testUnit);
  }

  void setUp() {
    super.setUp();
    index = createLocalMemoryIndex();
    searchEngine = new SearchEngineImpl(index);
  }
}
