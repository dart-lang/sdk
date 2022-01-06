// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/field_formal_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_check.dart';
import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldFormalContributorTest);
  });
}

@reflectiveTest
class FieldFormalContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) {
    return FieldFormalContributor(request, builder);
  }

  /// https://github.com/dart-lang/sdk/issues/39028
  Future<void> test_mixin_constructor() async {
    addTestSource('''
mixin M {
  var field = 0;
  M(this.^);
}
''');

    var response = await computeSuggestions2();
    check(response).suggestions.isEmpty;
  }

  Future<void> test_replacement_left() async {
    addTestSource('''
class A {
  var field = 0;
  A(this.f^);
}
''');

    var response = await computeSuggestions2();
    check(response)
      ..hasReplacement(left: 1)
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('field')
          ..isField
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_replacement_right() async {
    addTestSource('''
class A {
  var field = 0;
  A(this.^f);
}
''');

    var response = await computeSuggestions2();
    check(response)
      ..hasReplacement(right: 1)
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('field')
          ..isField
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_suggestions_onlyLocal() async {
    addTestSource('''
class A {
  var inherited = 0;
}

class B extends A {
  var first = 0;
  var second = 1.2;
  B(this.^);
  B.constructor() {}
  void method() {}
}
''');

    var response = await computeSuggestions2();
    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('first')
          ..isField
          ..returnType.isEqualTo('int'),
        (suggestion) => suggestion
          ..completion.isEqualTo('second')
          ..isField
          ..returnType.isEqualTo('double'),
      ]);
  }

  Future<void> test_suggestions_onlyNotSpecified_optionalNamed() async {
    addTestSource('''
class Point {
  final int x;
  final int y;
  Point({this.x, this.^});
}
''');

    var response = await computeSuggestions2();
    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('y')
          ..isField
          ..returnType.isEqualTo('int'),
      ]);
  }

  Future<void> test_suggestions_onlyNotSpecified_requiredPositional() async {
    addTestSource('''
class Point {
  final int x;
  final int y;
  Point(this.x, this.^);
}
''');

    var response = await computeSuggestions2();
    check(response)
      ..hasEmptyReplacement()
      ..suggestions.matchesInAnyOrder([
        (suggestion) => suggestion
          ..completion.isEqualTo('y')
          ..isField
          ..returnType.isEqualTo('int'),
      ]);
  }
}
