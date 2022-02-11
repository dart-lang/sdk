// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_utilities/check/check.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassBodyTest1);
    defineReflectiveTests(ClassBodyTest2);
  });
}

@reflectiveTest
class ClassBodyTest1 extends AbstractCompletionDriverTest
    with ClassBodyTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ClassBodyTest2 extends AbstractCompletionDriverTest
    with ClassBodyTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ClassBodyTestCases on AbstractCompletionDriverTest {
  /// It does not really matter which classes we list here, in this test
  /// suite we only need to know that we suggest classes at all.
  List<CompletionSuggestionChecker> get sampleClassChecks {
    return const {
      'Object',
    }.map((name) {
      return (CompletionSuggestionTarget suggestion) {
        suggestion
          ..completion.isEqualTo(name)
          ..isClass;
      };
    }).toList();
  }

  @override
  bool get supportsAvailableSuggestions => true;

  Future<void> test_nothing_x() async {
    await _checkContainers(
      line: '^',
      validator: (
        response, {
        required bool isClass,
        required bool isMixin,
      }) {
        check(response).suggestions
          ..withKindKeyword.matchesInAnyOrder(
            {
              // TODO(scheglov) Not quite right, without static.
              Keyword.CONST,
              if (isClass || isMixin) Keyword.COVARIANT,
              Keyword.DYNAMIC,
              // TODO(scheglov) This does not look right, mixin.
              if (isClass || isMixin) Keyword.FACTORY,
              Keyword.FINAL,
              Keyword.GET,
              Keyword.LATE,
              Keyword.OPERATOR,
              Keyword.SET,
              Keyword.STATIC,
              Keyword.VAR,
              Keyword.VOID,
            }.asKeywordChecks,
          )
          ..includesAll(sampleClassChecks);
      },
    );
  }

  Future<void> test_static_const_x() async {
    await _checkContainers(
      line: 'static const ^',
      validator: (
        response, {
        required bool isClass,
        required bool isMixin,
      }) {
        check(response).suggestions
          ..withKindKeyword.matchesInAnyOrder(
            {
              Keyword.DYNAMIC,
              Keyword.VOID,
            }.asKeywordChecks,
          )
          ..includesAll(sampleClassChecks);
      },
    );
  }

  Future<void> test_static_final_Ox() async {
    await _checkContainers(
      line: 'static final O^',
      validator: (
        response, {
        required bool isClass,
        required bool isMixin,
      }) {
        if (isProtocolVersion2) {
          check(response).suggestions
            ..withKindKeyword.isEmpty
            ..includesAll(sampleClassChecks);
        } else {
          check(response).suggestions
            ..withKindKeyword.matchesInAnyOrder(
              {
                Keyword.DYNAMIC,
                Keyword.VOID,
              }.asKeywordChecks,
            )
            ..includesAll(sampleClassChecks);
        }
      },
    );
  }

  Future<void> test_static_final_x() async {
    await _checkContainers(
      line: 'static final ^',
      validator: (
        response, {
        required bool isClass,
        required bool isMixin,
      }) {
        check(response).suggestions
          ..withKindKeyword.matchesInAnyOrder(
            {
              Keyword.DYNAMIC,
              Keyword.VOID,
            }.asKeywordChecks,
          )
          ..includesAll(sampleClassChecks);
      },
    );
  }

  Future<void> test_static_fx() async {
    await _checkContainers(
      line: 'static f^',
      validator: (
        response, {
        required bool isClass,
        required bool isMixin,
      }) {
        if (isProtocolVersion2) {
          check(response).suggestions
            ..withKindKeyword.matchesInAnyOrder(
              {
                Keyword.FINAL,
              }.asKeywordChecks,
            )
            ..includesAll([
              (suggestion) => suggestion
                ..completion.isEqualTo('FutureOr')
                ..isClass,
            ]);
        } else {
          check(response).suggestions
            ..withKindKeyword.matchesInAnyOrder(
              {
                Keyword.ABSTRACT,
                Keyword.CONST,
                Keyword.COVARIANT,
                Keyword.DYNAMIC,
                Keyword.EXTERNAL,
                Keyword.FINAL,
                Keyword.LATE,
              }.asKeywordChecks,
            )
            ..includesAll(sampleClassChecks);
        }
      },
    );
  }

  Future<void> test_static_late_x() async {
    await _checkContainers(
      line: 'static late ^',
      validator: (
        response, {
        required bool isClass,
        required bool isMixin,
      }) {
        check(response).suggestions
          ..withKindKeyword.matchesInAnyOrder(
            {
              Keyword.DYNAMIC,
              Keyword.FINAL,
            }.asKeywordChecks,
          )
          ..includesAll(sampleClassChecks);
      },
    );
  }

  Future<void> test_static_x() async {
    await _checkContainers(
      line: 'static ^',
      validator: (
        response, {
        required bool isClass,
        required bool isMixin,
      }) {
        check(response).suggestions
          ..withKindKeyword.matchesInAnyOrder(
            {
              Keyword.CONST,
              Keyword.DYNAMIC,
              Keyword.FINAL,
              Keyword.LATE,
            }.asKeywordChecks,
          )
          ..includesAll(sampleClassChecks);
      },
    );
  }

  Future<void> test_static_x_name_eq() async {
    await _checkContainers(
      line: 'static ^ name = 0;',
      validator: (
        response, {
        required bool isClass,
        required bool isMixin,
      }) {
        check(response).suggestions
          ..withKindKeyword.matchesInAnyOrder(
            {
              // TODO(scheglov) This does not look right.
              Keyword.ABSTRACT,
              Keyword.CONST,
              // TODO(scheglov) This does not look right.
              Keyword.COVARIANT,
              Keyword.DYNAMIC,
              // TODO(scheglov) This does not look right.
              Keyword.EXTERNAL,
              Keyword.FINAL,
              Keyword.LATE,
            }.asKeywordChecks,
          )
          ..includesAll(sampleClassChecks);
      },
    );
  }

  Future<void> test_sx() async {
    await _checkContainers(
      line: 's^',
      validator: (
        response, {
        required bool isClass,
        required bool isMixin,
      }) {
        if (isProtocolVersion2) {
          check(response).suggestions
            ..withKindKeyword.matchesInAnyOrder(
              {
                Keyword.SET,
                Keyword.STATIC,
              }.asKeywordChecks,
            )
            ..includesAll([
              (suggestion) => suggestion
                ..completion.isEqualTo('String')
                ..isClass,
            ]);
        } else {
          check(response).suggestions
            ..withKindKeyword.matchesInAnyOrder(
              {
                // TODO(scheglov) Not quite right, without static.
                Keyword.CONST,
                if (isClass || isMixin) Keyword.COVARIANT,
                Keyword.DYNAMIC,
                // TODO(scheglov) This does not look right, mixin.
                if (isClass || isMixin) Keyword.FACTORY,
                Keyword.FINAL,
                Keyword.GET,
                Keyword.LATE,
                Keyword.OPERATOR,
                Keyword.SET,
                Keyword.STATIC,
                Keyword.VAR,
                Keyword.VOID,
              }.asKeywordChecks,
            )
            ..includesAll(sampleClassChecks);
        }
      },
    );
  }

  Future<void> _checkContainers({
    required String line,
    required void Function(
      CompletionResponseForTesting response, {
      required bool isClass,
      required bool isMixin,
    })
        validator,
  }) async {
    // class
    {
      var response = await getTestCodeSuggestions('''
class A {
  $line
}
''');
      validator(
        response,
        isClass: true,
        isMixin: false,
      );
    }
    // enum
    {
      var response = await getTestCodeSuggestions('''
enum E {
  v;
  $line
}
''');
      validator(
        response,
        isClass: false,
        isMixin: false,
      );
    }
    // extension
    {
      var response = await getTestCodeSuggestions('''
extension on Object {
  $line
}
''');
      validator(
        response,
        isClass: false,
        isMixin: false,
      );
    }
    // mixin
    {
      var response = await getTestCodeSuggestions('''
mixin M {
  $line
}
''');
      validator(
        response,
        isClass: false,
        isMixin: true,
      );
    }
  }
}
