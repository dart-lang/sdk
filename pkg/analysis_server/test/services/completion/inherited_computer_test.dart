// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.inherited_computer_test;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/inherited_contributor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/src/matcher/core_matchers.dart';
import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'completion_test_util.dart';

main() {
  initializeTestEnvironment();
//  defineReflectiveTests(InheritedContributorTest);
}

@reflectiveTest
class InheritedContributorTest extends AbstractCompletionTest {
  @override
  void setUpContributor() {
    contributor = new NewCompletionWrapper(new InheritedContributor());
  }

  test_fromMultipleSuperclasses() {
    addTestSource(r'''
class A {
  notSuggested() => null;
  A suggested1(int x) => null;
  B suggested2(String y) => null;
}
class B extends A {
  B suggested2(String y) => null;
  C suggested3([String z]) => null;
}
class C extends B {
  sugg^
}
''');
    computeFast();
    return computeFull((bool result) {
      _assertOverride(
          '@override\n  A suggested1(int x) {\n    // TODO: implement suggested1\n    return null;\n  }');
      _assertOverride(
          '''@override\n  B suggested2(String y) {\n    // TODO: implement suggested2\n    return null;\n  }''');
      _assertOverride(
          '''@override\n  C suggested3([String z]) {\n    // TODO: implement suggested3\n    return null;\n  }''');
      assertNotSuggested(
          '''@override\n  notSuggested() {\n    // TODO: implement notSuggested\n    return null;\n  }''');
    });
  }

  CompletionSuggestion _assertOverride(String completion) {
    CompletionSuggestion cs = getSuggest(
        completion: completion,
        csKind: CompletionSuggestionKind.IDENTIFIER,
        elemKind: null);
    if (cs == null) {
      failedCompletion('expected $completion', request.suggestions);
    }
    expect(cs.kind, equals(CompletionSuggestionKind.IDENTIFIER));
    expect(cs.relevance, equals(DART_RELEVANCE_HIGH));
    expect(cs.importUri, null);
//    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, isFalse);
    expect(cs.isPotential, isFalse);
    expect(cs.element, isNotNull);
    return cs;
  }
}
