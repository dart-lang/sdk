// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.toplevel;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/imported_type_computer.dart';
import '../../reflective_tests.dart';
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

  test_class_importHide() {
    addSource('/testA.dart', 'class A { } class B { }');
    addTestSource('import "/testA.dart" hide ^; class C {}');
    return computeFull().then((_) {
      assertSuggestClass('A');
      assertSuggestClass('B');
      assertNotSuggested('Object');
    });
  }

  test_class_importShow() {
    addSource('/testA.dart', 'class A { } class B { }');
    addTestSource('import "/testA.dart" show ^; class C {}');
    return computeFull().then((_) {
      // only suggest elements listed in show combinator
      assertSuggestClass('A');
      assertSuggestClass('B');
      assertNotSuggested('Object');
    });
  }

  test_class_importShowWithPart() {
    addSource('/testB.dart', 'part of libA;  class B { }');
    addSource('/testA.dart', 'part "/testB.dart"; class A { }');
    addTestSource('import "/testA.dart" show ^; class C {}');
    return computeFull().then((_) {
      // only suggest elements listed in show combinator
      assertSuggestClass('A');
      assertSuggestClass('B');
      assertNotSuggested('Object');
    });
  }

  test_class_importedWithHide() {
    addSource('/testA.dart', 'class A { } class B { }');
    addTestSource('import "/testA.dart" hide B; class C {foo(){^}}');
    return computeFull().then((_) {
      // exclude elements listed in hide combinator
      assertSuggestClass('A');
      assertNotSuggested('B');
      assertSuggestClass('Object');
    });
  }

  test_class_importedWithPrefix() {
    addSource('/testA.dart', 'class A { }');
    addTestSource('import "/testA.dart" as foo; class C {foo(){^}}');
    return computeFull().then((_) {
      // do not suggest types imported with prefix
      assertNotSuggested('A');
      // do not suggest prefix as it is suggested by LocalComputer
      assertNotSuggested('foo');
    });
  }

  test_class_importedWithShow() {
    addSource('/testA.dart', 'class A { } class B { }');
    addTestSource('import "/testA.dart" show A; class C {foo(){^}}');
    return computeFull().then((_) {
      // only suggest elements listed in show combinator
      assertSuggestClass('A');
      assertNotSuggested('B');
      assertSuggestClass('Object');
    });
  }

  test_class_notImported() {
    addSource('/testA.dart', 'class A {int x;} class _B { }');
    addTestSource('class C {foo(){^}}');
    return computeFull(true).then((_) {
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

  test_field_name() {
    addSource('/testA.dart', 'class A { }');
    addTestSource('import "/testA.dart"; class C {A ^}');
    return computeFull().then((_) {
      assertNotSuggested('A');
    });
  }

  test_field_name2() {
    addSource('/testA.dart', 'class A { }');
    addTestSource('import "/testA.dart"; class C {var ^}');
    return computeFull().then((_) {
      assertNotSuggested('A');
    });
  }

  test_local_name() {
    addSource('/testA.dart', 'var T1;');
    addTestSource('import "/testA.dart"; class C {a() {C ^}}');
    return computeFull().then((_) {
      //TODO (danrubel) should not be suggested
      // but C ^ in this test
      // parses differently than var ^ in test below
      assertSuggestTopLevelVar('T1');
    });
  }

  test_local_name2() {
    addSource('/testA.dart', 'var T1;');
    addTestSource('import "/testA.dart"; class C {a() {var ^}}');
    return computeFull().then((_) {
      assertNotSuggested('T1');
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

  test_topLevelVar_name() {
    addSource('/testA.dart', 'class B { };');
    addTestSource('import "/testA.dart"; class C {} B ^');
    return computeFull().then((_) {
      assertNotSuggested('B');
    });
  }

  test_topLevelVar_name2() {
    addSource('/testA.dart', 'class B { };');
    addTestSource('import "/testA.dart"; class C {} var ^');
    return computeFull().then((_) {
      assertNotSuggested('B');
    });
  }

  test_topLevelVar_notImported() {
    addSource('/testA.dart', 'var T1; var _T2;');
    addTestSource('class C {foo(){^}}');
    return computeFull(true).then((_) {
      assertSuggestTopLevelVar('T1', CompletionRelevance.LOW);
      assertNotSuggested('_T2');
    });
  }
}
