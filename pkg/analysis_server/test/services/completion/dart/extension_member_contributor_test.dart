// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/extension_member_contributor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMemberContributorTest);
  });
}

@reflectiveTest
class ExtensionMemberContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new ExtensionMemberContributor();
  }

  void setUp() {
    createAnalysisOptionsFile(experiments: ['extension-methods']);
    super.setUp();
  }

  test_extensionOverride() async {
    addTestSource('''
extension E on int {
  bool a(int b, int c) {}
  int get b => 0;
  set c(int d) {}
}
void f() {
  E(2).a^
}
''');
    await computeSuggestions();
    assertSuggestMethod('a', null, 'bool', defaultArgListString: 'b, c');
    assertSuggestGetter('b', 'int');
    assertSuggestSetter('c');
  }

  test_literal() async {
    addTestSource('''
extension E on int {
  bool a(int b, int c) {}
  int get b => 0;
  set c(int d) {}
}
void f() {
  2.a^
}
''');
    await computeSuggestions();
    assertSuggestMethod('a', null, 'bool', defaultArgListString: 'b, c');
    assertSuggestGetter('b', 'int');
    assertSuggestSetter('c');
  }

  test_identifier() async {
    addTestSource('''
extension E on int {
  bool a(int b, int c) {}
  int get b => 0;
  set c(int d) {}
}
void f(int i) {
  i.a^
}
''');
    await computeSuggestions();
    assertSuggestMethod('a', null, 'bool', defaultArgListString: 'b, c');
    assertSuggestGetter('b', 'int');
    assertSuggestSetter('c');
  }

  test_function() async {
    addTestSource('''
extension E on int {
  bool a(int b, int c) {}
  int get b => 0;
  set c(int d) {}
}
void f() {
  g().a^
}
int g() => 3;
''');
    await computeSuggestions();
    assertSuggestMethod('a', null, 'bool', defaultArgListString: 'b, c');
    assertSuggestGetter('b', 'int');
    assertSuggestSetter('c');
  }
}
