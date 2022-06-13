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
    with ClassBodyTestCases, OverrideTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ClassBodyTest2 extends AbstractCompletionDriverTest
    with ClassBodyTestCases, OverrideTestCases {
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

  Future<void> test_nothing_x() async {
    await _checkContainers(
      line: '^',
      validator: (context, response) {
        check(response).suggestions
          ..withKindKeyword.matchesInAnyOrder(
            {
              // TODO(scheglov) Not quite right, without static.
              Keyword.CONST,
              if (context.isClass || context.isMixin) Keyword.COVARIANT,
              Keyword.DYNAMIC,
              // TODO(scheglov) This does not look right, mixin.
              if (context.isClass || context.isMixin) Keyword.FACTORY,
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
      validator: (context, response) {
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
      validator: (context, response) {
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
      validator: (context, response) {
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
      validator: (context, response) {
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
      validator: (context, response) {
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
      validator: (context, response) {
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
      validator: (context, response) {
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
      validator: (context, response) {
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
                if (context.isClass || context.isMixin) Keyword.COVARIANT,
                Keyword.DYNAMIC,
                // TODO(scheglov) This does not look right, mixin.
                if (context.isClass || context.isMixin) Keyword.FACTORY,
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
      _Context context,
      CompletionResponseForTesting response,
    )
        validator,
  }) async {
    // class
    {
      var response = await getTestCodeSuggestions('''
class A {
  $line
}
''');
      validator(_Context(isClass: true), response);
    }
    // enum
    {
      var response = await getTestCodeSuggestions('''
enum E {
  v;
  $line
}
''');
      validator(_Context(), response);
    }
    // extension
    {
      var response = await getTestCodeSuggestions('''
extension on Object {
  $line
}
''');
      validator(_Context(), response);
    }
    // mixin
    {
      var response = await getTestCodeSuggestions('''
mixin M {
  $line
}
''');
      validator(_Context(isMixin: true), response);
    }
  }
}

mixin OverrideTestCases on AbstractCompletionDriverTest {
  Future<void> test_class_inComment() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  // foo^
  void bar() {}
}
''');

    check(response).suggestions.overrides.isEmpty;
  }

  Future<void> test_class_inComment_dartdoc() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  /// foo^
  void bar() {}
}
''');

    check(response).suggestions.overrides.isEmpty;
  }

  Future<void> test_class_inComment_reference() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  /// [foo^]
  void bar() {}
}
''');

    check(response).suggestions.overrides.isEmpty;
  }

  Future<void> test_class_method_alreadyOverridden() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
  void foo02() {}
}

class B extends A {
  void foo02() {}
  foo^
}
''');

    check(response).suggestions.overrides
      ..includesAll([
        _isOverrideWithSuper_foo01,
      ])
      ..excludesAll([
        (suggestion) => suggestion.completion.contains('foo02'),
      ]);
  }

  Future<void> test_class_method_beforeField() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  foo^
  
  int bar = 0;
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithSuper_foo01,
    ]);
  }

  Future<void> test_class_method_beforeMethod() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  foo^
  
  void bar() {}
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithSuper_foo01,
    ]);
  }

  Future<void> test_class_method_fromExtends() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  foo^
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithSuper_foo01,
    ]);
  }

  Future<void> test_class_method_fromExtends_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

class A {
  void foo01() {}
}
''');

    final response = await getTestCodeSuggestions('''
part 'a.dart';

class B extends A {
  foo^
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithSuper_foo01,
    ]);
  }

  Future<void> test_class_method_fromExtends_multiple() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  void foo02() {}
}

class C extends B {
  foo^
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithSuper_foo01,
      _isOverrideWithSuper_foo02,
    ]);
  }

  Future<void> test_class_method_fromExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  // ignore:unused_element
  void _foo01() {}
  void foo02() {}
}
''');

    final response = await getTestCodeSuggestions('''
import 'a.dart';

class B extends A {
  foo^
}
''');

    check(response).suggestions.overrides
      ..includesAll([
        _isOverrideWithSuper_foo02,
      ])
      ..excludesAll([
        _isOverrideWithSuper_private_foo01,
      ]);
  }

  Future<void> test_class_method_fromExtends_private_thisLibrary() async {
    final response = await getTestCodeSuggestions('''
class A {
  void _foo01() {}
  void foo02() {}
}

class B extends A {
  foo^
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithSuper_private_foo01,
      _isOverrideWithSuper_foo02,
    ]);
  }

  Future<void> test_class_method_fromExtends_withOverride() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  @override
  foo^
}
''');

    check(response).suggestions.overrides.includesAll([
      (suggestion) => suggestion
        ..displayText.isEqualTo('foo01() { … }')
        ..hasSelection(offset: 48, length: 14)
        ..completion.isEqualTo(r'''
void foo01() {
    // TODO: implement foo01
    super.foo01();
  }'''),
    ]);
  }

  Future<void> test_class_method_fromImplements() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

class B implements A {
  foo^
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithoutSuper_foo01,
    ]);
  }

  Future<void> test_class_method_fromWith() async {
    final response = await getTestCodeSuggestions('''
mixin M {
  void foo01() {}
}

class A with M {
  foo^
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithSuper_foo01,
    ]);
  }

  Future<void> test_class_operator_eqEq() async {
    final response = await getTestCodeSuggestions('''
class A {
  opera^
}
''');

    check(response).suggestions.overrides.includesAll([
      (suggestion) => suggestion
        ..displayText.isEqualTo('==(Object other) { … }')
        ..hasSelection(offset: 75, length: 22)
        ..completion.isEqualTo(r'''
@override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }'''),
    ]);
  }

  Future<void> test_class_operator_plus() async {
    final response = await getTestCodeSuggestions('''
class A {
  int operator +(int other) { }
}

class B extends A {
  opera^
}
''');

    check(response).suggestions.overrides.includesAll([
      (suggestion) => suggestion
        ..displayText.isEqualTo('+(int other) { … }')
        ..hasSelection(offset: 69, length: 21)
        ..completion.isEqualTo(r'''
@override
  int operator +(int other) {
    // TODO: implement +
    return super + other;
  }'''),
    ]);
  }

  Future<void> test_extension_method() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

extension E on A {
  foo^
}
''');

    check(response).suggestions.overrides.isEmpty;
  }

  Future<void> test_mixin_method_fromConstraints_alreadyOverridden() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
  void foo02() {}
}

mixin M on A {
  void foo02() {}
  foo^
}
''');

    check(response).suggestions.overrides
      ..includesAll([
        _isOverrideWithSuper_foo01,
      ])
      ..excludesAll([
        (suggestion) => suggestion.completion.contains('foo02'),
      ]);
  }

  Future<void> test_mixin_method_fromImplements() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

mixin M implements A {
  foo^
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithoutSuper_foo01,
    ]);
  }

  Future<void> test_mixin_method_fromSuperclassConstraint() async {
    final response = await getTestCodeSuggestions('''
class A {
  void foo01() {}
}

mixin M on A {
  foo^
}
''');

    check(response).suggestions.overrides.includesAll([
      _isOverrideWithSuper_foo01,
    ]);
  }

  static void _isOverrideWithoutSuper_foo01(
    CheckTarget<CompletionSuggestionForTesting> suggestion,
  ) {
    suggestion
      ..displayText.isEqualTo('foo01() { … }')
      ..hasSelection(offset: 55)
      ..completion.isEqualTo(r'''
@override
  void foo01() {
    // TODO: implement foo01
  }''');
  }

  static void _isOverrideWithSuper_foo01(
    CheckTarget<CompletionSuggestionForTesting> suggestion,
  ) {
    suggestion
      ..displayText.isEqualTo('foo01() { … }')
      ..hasSelection(offset: 60, length: 14)
      ..completion.isEqualTo(r'''
@override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }''');
  }

  static void _isOverrideWithSuper_foo02(
    CheckTarget<CompletionSuggestionForTesting> suggestion,
  ) {
    suggestion
      ..displayText.isEqualTo('foo02() { … }')
      ..hasSelection(offset: 60, length: 14)
      ..completion.isEqualTo(r'''
@override
  void foo02() {
    // TODO: implement foo02
    super.foo02();
  }''');
  }

  static void _isOverrideWithSuper_private_foo01(
    CheckTarget<CompletionSuggestionForTesting> suggestion,
  ) {
    suggestion
      ..displayText.isEqualTo('_foo01() { … }')
      ..hasSelection(offset: 62, length: 15)
      ..completion.isEqualTo(r'''
@override
  void _foo01() {
    // TODO: implement _foo01
    super._foo01();
  }''');
  }
}

class _Context {
  final bool isClass;
  final bool isMixin;

  _Context({
    this.isClass = false,
    this.isMixin = false,
  });
}
