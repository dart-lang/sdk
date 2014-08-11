// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.toplevel;

import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/src/completion/imported_type_computer.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ImportedTypeComputerTest);
}

@ReflectiveTestCase()
class ImportedTypeComputerTest extends AbstractCompletionTest {

  @override
  void setUp() {
    super.setUp();
    computer = new ImportedTypeComputer();
  }

  test_class() {
    addSource('/testA.dart', 'class A {int x;} class _B { }');
    addTestSource('import "/testA.dart"; class C {foo(){^}}');
    return computeFull().then((_) {
      assertSuggestClass('A');
      assertNotSuggested('x');
      assertNotSuggested('_B');
      // Should not suggest compilation unit elements
      // which are returned by the LocalComputer
      assertNotSuggested('C');
    });
  }

  test_class_importedWithPrefix() {
    addSource('/testA.dart', 'class A { }');
    addTestSource('import "/testA.dart" as foo; class C {foo(){^}}');
    return computeFull().then((_) {
      // do not suggest types imported with prefix
      assertNotSuggested('A');
    });
  }

  test_class_notImported() {
    addSource('/testA.dart', 'class A {int x;} class _B { }');
    addTestSource('class C {foo(){^}}');
    return computeFull().then((_) {
      assertSuggestClass('A', CompletionRelevance.LOW);
      assertNotSuggested('x');
      assertNotSuggested('_B');
    });
  }

  test_dartCore() {
    addTestSource('class C {foo(){^}}');
    return computeFull().then((_) {
      assertSuggestClass('Object');
      assertNotSuggested('HtmlElement');
    });
  }

  test_dartHtml() {
    addTestSource('import "dart:html"; class C {foo(){^}}');
    return computeFull().then((_) {
      assertSuggestClass('Object');
      assertSuggestClass('HtmlElement');
    });
  }

  test_topLevelVar() {
    addSource('/testA.dart', 'var T1; var _T2;');
    addTestSource('import "/testA.dart"; class C {foo(){^}}');
    return computeFull().then((_) {
      assertSuggestTopLevelVar('T1');
      assertNotSuggested('_T2');
    });
  }

  test_topLevelVar_notImported() {
    addSource('/testA.dart', 'var T1; var _T2;');
    addTestSource('class C {foo(){^}}');
    return computeFull().then((_) {
      assertSuggestTopLevelVar('T1', CompletionRelevance.LOW);
      assertNotSuggested('_T2');
    });
  }
}
