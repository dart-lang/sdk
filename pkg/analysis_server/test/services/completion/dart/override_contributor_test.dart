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
  defineReflectiveTests(OverrideContributorTest);
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
  void suggested4() { }
  int get suggested5 => null;
}
class C extends B {
  sugg^
}
''');
    await computeSuggestions();
    _assertOverride('''
@override
  A suggested1(int x) {
    // TODO: implement suggested1
    return super.suggested1(x);
  }''',
        displayText: 'suggested1(int x) { … }',
        selectionOffset: 72,
        selectionLength: 27);
    _assertOverride('''
@override
  A suggested1(int x) {
    // TODO: implement suggested1
    return super.suggested1(x);
  }''',
        displayText: 'suggested1(int x) { … }',
        selectionOffset: 72,
        selectionLength: 27);
    _assertOverride('''
@override
  B suggested2(String y) {
    // TODO: implement suggested2
    return super.suggested2(y);
  }''',
        displayText: 'suggested2(String y) { … }',
        selectionOffset: 75,
        selectionLength: 27);
    _assertOverride('''
@override
  C suggested3([String z]) {
    // TODO: implement suggested3
    return super.suggested3(z);
  }''',
        displayText: 'suggested3([String z]) { … }',
        selectionOffset: 77,
        selectionLength: 27);
    _assertOverride('''
@override
  void suggested4() {
    // TODO: implement suggested4
    super.suggested4();
  }''',
        displayText: 'suggested4() { … }',
        selectionOffset: 70,
        selectionLength: 19);
    _assertOverride('''
@override
  // TODO: implement suggested5
  int get suggested5 => super.suggested5;''',
        displayText: 'suggested5 => …',
        selectionOffset: 66,
        selectionLength: 16);
  }

  test_fromPart() async {
    addSource('/myLib.dart', '''
library myLib;
part '${convertPathForImport(testFile)}'
part '${convertPathForImport('/otherPart.dart')}'
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
    _assertOverride('''
@override
  A suggested1(int x) {
    // TODO: implement suggested1
    return super.suggested1(x);
  }''', displayText: 'suggested1(int x) { … }');
    _assertOverride('''
@override
  A suggested1(int x) {
    // TODO: implement suggested1
    return super.suggested1(x);
  }''',
        displayText: 'suggested1(int x) { … }',
        selectionOffset: 72,
        selectionLength: 27);
    _assertOverride('''
@override
  B suggested2(String y) {
    // TODO: implement suggested2
    return super.suggested2(y);
  }''',
        displayText: 'suggested2(String y) { … }',
        selectionOffset: 75,
        selectionLength: 27);
    _assertOverride('''
@override
  C suggested3([String z]) {
    // TODO: implement suggested3
    return super.suggested3(z);
  }''',
        displayText: 'suggested3([String z]) { … }',
        selectionOffset: 77,
        selectionLength: 27);
  }

  test_withExistingOverride() async {
    addTestSource('''
class A {
  method() {}
  int age;
}

class B extends A {
  @override
  meth^
}
''');
    await computeSuggestions();
    _assertOverride('''
method() {
    // TODO: implement method
    return super.method();
  }''',
        displayText: 'method() { … }',
        selectionOffset: 45,
        selectionLength: 22);
  }

  @failingTest
  test_withOverrideAnnotation() async {
    addTestSource('''
class A {
  method() {}
  int age;
}

class B extends A {
  @override
  ^
}
''');
    await computeSuggestions();
    _assertOverride('''
method() {
    // TODO: implement method
    return super.method();
  }''',
        displayText: 'method() { … }',
        selectionOffset: 45,
        selectionLength: 22);
  }

  @failingTest
  test_insideBareClass() async {
    addTestSource('''
class A {
  method() {}
  int age;
}

class B extends A {
  ^
}
''');
    await computeSuggestions();
    _assertOverride('''
method() {
    // TODO: implement method
    return super.method();
  }''',
        displayText: 'method() { … }',
        selectionOffset: 45,
        selectionLength: 22);
  }

  CompletionSuggestion _assertOverride(String completion,
      {String displayText, int selectionOffset, int selectionLength}) {
    CompletionSuggestion cs = getSuggest(
        completion: completion,
        csKind: CompletionSuggestionKind.OVERRIDE,
        elemKind: null);
    if (cs == null) {
      failedCompletion('expected $completion', suggestions);
    }
    expect(cs.kind, equals(CompletionSuggestionKind.OVERRIDE));
    expect(cs.relevance, equals(DART_RELEVANCE_HIGH));
    expect(cs.importUri, null);
    if (selectionOffset != null && selectionLength != null) {
      expect(cs.selectionOffset, selectionOffset);
      expect(cs.selectionLength, selectionLength);
    }
    expect(cs.isDeprecated, isFalse);
    expect(cs.isPotential, isFalse);
    expect(cs.element, isNotNull);
    expect(cs.displayText, displayText);
    return cs;
  }
}
