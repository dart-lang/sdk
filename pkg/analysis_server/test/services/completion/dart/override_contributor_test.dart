// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/override_contributor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  // Revisit this contributor and these tests
  // once DartChangeBuilder API has solidified.
  // initializeTestEnvironment();
  // defineReflectiveTests(InheritedContributorTest);
}

@reflectiveTest
class OverrideContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new OverrideContributor();
  }

  test_fromMultipleSuperclasses() async {
    addTestSource(r'''
class A {
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
    await computeSuggestions();
    _assertOverride('''@override
  A suggested1(int x) {
    // TODO: implement suggested1
    return null;
  }''');
    _assertOverride(
        '''@override\n  A suggested1(int x) {\n    // TODO: implement suggested1\n    return null;\n  }''');
    _assertOverride(
        '''@override\n  B suggested2(String y) {\n    // TODO: implement suggested2\n    return null;\n  }''');
    _assertOverride(
        '''@override\n  C suggested3([String z]) {\n    // TODO: implement suggested3\n    return null;\n  }''');
  }

  test_fromPart() async {
    addSource('/myLib.dart', '''
library myLib;
part '$testFile'
part '/otherPart.dart'
class A {
  A suggested1(int x) => null;
  B suggested2(String y) => null;
}
''');
    addSource('/otherPart.dart', '''
part of myLib;
class B extends A {
  B suggested2(String y) => null;
  C suggested3([String z]) => null;
}
''');
    addTestSource(r'''
part of myLib;
class C extends B {
  sugg^
}
''');
    // assume information for context.getLibrariesContaining has been cached
    await computeLibrariesContaining();
    await computeSuggestions();
    _assertOverride('''@override
  A suggested1(int x) {
    // TODO: implement suggested1
    return null;
  }''');
    _assertOverride(
        '''@override\n  A suggested1(int x) {\n    // TODO: implement suggested1\n    return null;\n  }''');
    _assertOverride(
        '''@override\n  B suggested2(String y) {\n    // TODO: implement suggested2\n    return null;\n  }''');
    _assertOverride(
        '''@override\n  C suggested3([String z]) {\n    // TODO: implement suggested3\n    return null;\n  }''');
  }

  CompletionSuggestion _assertOverride(String completion) {
    CompletionSuggestion cs = getSuggest(
        completion: completion,
        csKind: CompletionSuggestionKind.IDENTIFIER,
        elemKind: null);
    if (cs == null) {
      failedCompletion('expected $completion', suggestions);
    }
    expect(cs.kind, equals(CompletionSuggestionKind.IDENTIFIER));
    expect(cs.relevance, equals(DART_RELEVANCE_HIGH));
    expect(cs.importUri, null);
//    expect(cs.selectionOffset, equals(completion.length));
//    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, isFalse);
    expect(cs.isPotential, isFalse);
    expect(cs.element, isNotNull);
    return cs;
  }
}
