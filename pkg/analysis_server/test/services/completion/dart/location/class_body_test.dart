// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassBodyTest);
    defineReflectiveTests(ClassOverrideTest);
  });
}

@reflectiveTest
class ClassBodyTest extends AbstractCompletionDriverTest
    with ClassBodyTestCases {}

mixin ClassBodyTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterField_beforeEnd() async {
    await computeSuggestions('''
class A {var foo; ^}
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  final
    kind: keyword
  static
    kind: keyword
  void
    kind: keyword
  const
    kind: keyword
  set
    kind: keyword
  factory
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterField_beforeField() async {
    await computeSuggestions('''
class A {var bar; ^ var foo;}
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  final
    kind: keyword
  static
    kind: keyword
  void
    kind: keyword
  const
    kind: keyword
  set
    kind: keyword
  factory
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeField() async {
    await computeSuggestions('''
class A {^ var foo;}
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  final
    kind: keyword
  static
    kind: keyword
  void
    kind: keyword
  const
    kind: keyword
  set
    kind: keyword
  factory
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeMethodWithoutType() async {
    await computeSuggestions('''
class A { ^ foo() {}}
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  final
    kind: keyword
  static
    kind: keyword
  void
    kind: keyword
  const
    kind: keyword
  set
    kind: keyword
  factory
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeMethodWithoutType_partial() async {
    await computeSuggestions('''
class A { d^ foo() {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  dynamic
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
class A {^}
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  final
    kind: keyword
  static
    kind: keyword
  void
    kind: keyword
  const
    kind: keyword
  set
    kind: keyword
  factory
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_nothing_x() async {
    await _checkContainers(
      line: '^',
      validator: (context) {
        _printKeywordsOrClass();

        var keywords = {
          Keyword.CONST,
          if (context.isClass || context.isMixin) Keyword.COVARIANT,
          Keyword.DYNAMIC,
          if (context.isClass) Keyword.FACTORY,
          Keyword.FINAL,
          Keyword.GET,
          if (!context.isExtension && !context.isExtensionType) Keyword.LATE,
          Keyword.OPERATOR,
          Keyword.SET,
          Keyword.STATIC,
          Keyword.VAR,
          Keyword.VOID,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''', where: context.where);
      },
    );
  }

  Future<void> test_static_const_x() async {
    await _checkContainers(
      line: 'static const ^',
      validator: (context) {
        _printKeywordsOrClass();

        var keywords = {
          Keyword.DYNAMIC,
          Keyword.VOID,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''', where: context.where);
      },
    );
  }

  Future<void> test_static_final_Ox() async {
    await _checkContainers(
      line: 'static final O^',
      validator: (context) {
        _printKeywordsOrClass();
        assertResponse(r'''
replacement
  left: 1
suggestions
  Object
    kind: class
''', where: context.where);
      },
    );
  }

  Future<void> test_static_final_x() async {
    await _checkContainers(
      line: 'static final ^',
      validator: (context) {
        _printKeywordsOrClass();

        var keywords = {
          Keyword.DYNAMIC,
          Keyword.VOID,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''', where: context.where);
      },
    );
  }

  Future<void> test_static_fx() async {
    _printKeywordsOrClass(
      sampleClassName: 'FutureOr',
    );

    await _checkContainers(
      line: 'static f^',
      validator: (context) {
        var keywords = {
          Keyword.FINAL,
        };

        assertResponse('''
replacement
  left: 1
suggestions
  FutureOr
    kind: class
${keywords.asKeywordSuggestions}
''', where: context.where);
      },
    );
  }

  Future<void> test_static_late_x() async {
    await _checkContainers(
      line: 'static late ^',
      validator: (context) {
        _printKeywordsOrClass();

        var keywords = {
          Keyword.CONST,
          Keyword.DYNAMIC,
          Keyword.EXTERNAL,
          Keyword.FINAL,
          Keyword.VAR,
          Keyword.VOID,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''', where: context.where);
      },
    );
  }

  Future<void> test_static_x() async {
    await _checkContainers(
      line: 'static ^',
      validator: (context) {
        _printKeywordsOrClass();

        var keywords = {
          Keyword.CONST,
          Keyword.DYNAMIC,
          Keyword.EXTERNAL,
          Keyword.FINAL,
          Keyword.VAR,
          Keyword.VOID,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''', where: context.where);
      },
    );
  }

  Future<void> test_static_x_name_eq() async {
    await _checkContainers(
      line: 'static ^ name = 0;',
      validator: (context) {
        _printKeywordsOrClass();

        var keywords = {
          Keyword.CONST,
          Keyword.DYNAMIC,
          // TODO(scheglov): This does not look right.
          Keyword.EXTERNAL,
          Keyword.FINAL,
          Keyword.VAR,
          Keyword.VOID,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''', where: context.where);
      },
    );
  }

  Future<void> test_sx() async {
    _printKeywordsOrClass(
      sampleClassName: 'String',
    );

    await _checkContainers(
      line: 's^',
      validator: (context) {
        var keywords = {
          Keyword.SET,
          Keyword.STATIC,
        };

        assertResponse('''
replacement
  left: 1
suggestions
  String
    kind: class
${keywords.asKeywordSuggestions}
''', where: context.where);
      },
    );
  }

  Future<void> _checkContainers({
    required String line,
    required void Function(_Context context) validator,
  }) async {
    // class
    {
      await computeSuggestions('''
class A {
  $line
}
''');
      validator(_Context(isClass: true));
    }
    // enum
    {
      await computeSuggestions('''
enum E {
  v;
  $line
}
''');
      validator(_Context(isEnum: true));
    }
    // extension
    {
      await computeSuggestions('''
extension on Object {
  $line
}
''');
      validator(_Context(isExtension: true));
    }
    // extension type
    {
      await computeSuggestions('''
extension type E(Object it) {
  $line
}
''');
      validator(_Context(isExtensionType: true));
    }
    // mixin
    {
      await computeSuggestions('''
mixin M {
  $line
}
''');
      validator(_Context(isMixin: true));
    }
  }

  void _printKeywordsOrClass({
    String sampleClassName = 'Object',
  }) {
    printerConfiguration.sorting = printer.Sorting.completionThenKind;
    printerConfiguration.filter = (suggestion) {
      var completion = suggestion.completion;
      if (suggestion.kind == CompletionSuggestionKind.KEYWORD) {
        return true;
      } else if (completion == sampleClassName) {
        return true;
      }
      return false;
    };
  }
}

@reflectiveTest
class ClassOverrideTest extends AbstractCompletionDriverTest
    with OverrideTestCases {}

mixin OverrideTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();
    writeTestPackageConfig(meta: true);

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        switch (suggestion.kind) {
          case CompletionSuggestionKind.IDENTIFIER:
            return suggestion.completion == 'override';
          case CompletionSuggestionKind.OVERRIDE:
            return suggestion.completion.contains('foo0');
        }
        return false;
      },
      withDisplayText: true,
    );
  }

  Future<void> test_class_atOverride_afterField_beforeRightBrace() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  final int bar01 = 0;

  @over^
}
''');

    assertResponse(r'''
replacement
  left: 4
suggestions
  override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: override foo01() { … }
    selection: 59 14
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void>
      test_class_atOverride_afterLeftBrace_beforeField_prevLine() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  @over^
  final int bar01 = 0;
}
''');

    assertResponse(r'''
replacement
  left: 4
suggestions
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void>
      test_class_atOverride_afterLeftBrace_beforeField_skipLine() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  @over^

  final int bar01 = 0;
}
''');

    assertResponse(r'''
replacement
  left: 4
suggestions
  override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: override foo01() { … }
    selection: 59 14
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void> test_class_atOverride_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  @over^
}
''');

    assertResponse(r'''
replacement
  left: 4
suggestions
  override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: override foo01() { … }
    selection: 59 14
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void> test_class_atOverride_afterMethod_beforeMethod_prevLine() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  void bar01() {}

  @over^
  void bar02() {}
}
''');

    // Note, no `foo01` override suggestion.
    assertResponse(r'''
replacement
  left: 4
suggestions
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void> test_class_atOverride_afterMethod_beforeMethod_skipLine() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  void bar01() {}

  @over^

  void bar02() {}
}
''');

    assertResponse(r'''
replacement
  left: 4
suggestions
  override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: override foo01() { … }
    selection: 59 14
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void> test_class_atOverride_afterMethod_beforeRightBrace() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  void bar() {}
  @over^
}
''');

    assertResponse(r'''
replacement
  left: 4
suggestions
  override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: override foo01() { … }
    selection: 59 14
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void> test_class_atOverride_operator() async {
    await computeSuggestions('''
class A {
  @over^
}
''');

    printerConfiguration.filter = (suggestion) {
      switch (suggestion.kind) {
        case CompletionSuggestionKind.IDENTIFIER:
          return suggestion.completion == 'override';
        case CompletionSuggestionKind.OVERRIDE:
          return suggestion.completion.contains('==');
      }
      return false;
    };

    assertResponse(r'''
replacement
  left: 4
suggestions
  override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    displayText: override ==(Object other) { … }
    selection: 74 22
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void> test_class_inComment() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  // foo^
  void bar() {}
}
''');

    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_class_inComment_dartdoc() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  /// foo^
  void bar() {}
}
''');

    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_class_inComment_reference() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  /// [foo^]
  void bar() {}
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
''');
  }

  Future<void> test_class_method_alreadyOverridden() async {
    await computeSuggestions('''
class A {
  void foo01() {}
  void foo02() {}
}

class B extends A {
  void foo02() {}
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }

  @FailingTest(reason: 'The parser recovers as `foo int;` and `bar = 0`.')
  Future<void> test_class_method_beforeField() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  foo^

  int bar = 0;
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }

  Future<void> test_class_method_beforeMethod() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  foo^

  void bar() {}
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }

  Future<void> test_class_method_fromExtends() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }

  Future<void> test_class_method_fromExtends_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

class A {
  void foo01() {}
}
''');

    await computeSuggestions('''
part 'a.dart';

class B extends A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }

  Future<void> test_class_method_fromExtends_multiple() async {
    await computeSuggestions('''
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

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
  @override
  void foo02() {
    // TODO: implement foo02
    super.foo02();
  }
    kind: override
    displayText: foo02() { … }
    selection: 60 14
''');
  }

  Future<void> test_class_method_fromExtends_private_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  // ignore:unused_element
  void _foo01() {}
  void foo02() {}
}
''');

    await computeSuggestions('''
import 'a.dart';

class B extends A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo02() {
    // TODO: implement foo02
    super.foo02();
  }
    kind: override
    displayText: foo02() { … }
    selection: 60 14
''');
  }

  Future<void> test_class_method_fromExtends_private_thisLibrary() async {
    await computeSuggestions('''
class A {
  void _foo01() {}
  void foo02() {}
}

class B extends A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void _foo01() {
    // TODO: implement _foo01
    super._foo01();
  }
    kind: override
    displayText: _foo01() { … }
    selection: 62 15
  @override
  void foo02() {
    // TODO: implement foo02
    super.foo02();
  }
    kind: override
    displayText: foo02() { … }
    selection: 60 14
''');
  }

  Future<void>
      test_class_method_fromExtends_signatureHasUnimportedTypes() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';

class A {
  FutureOr<void> foo01() {}
}
''');
    await computeSuggestions('''
import 'a.dart';

class B extends A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  FutureOr<void> foo01() {
    // TODO: implement foo01
    return super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 70 21
''');
  }

  Future<void> test_class_method_fromExtends_withOverride() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B extends A {
  @override
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 48 14
''');
  }

  Future<void> test_class_method_fromExtends_withOverride_nonVirtual() async {
    await computeSuggestions('''
import 'package:meta/meta.dart';

class A {
  void foo01() {}

  @nonVirtual
  void foo02() {}
}

class B extends A {
  @override
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 48 14
''');
  }

  Future<void> test_class_method_fromImplements() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

class B implements A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
  }
    kind: override
    displayText: foo01() { … }
    selection: 55
''');
  }

  Future<void> test_class_method_fromWith() async {
    await computeSuggestions('''
mixin M {
  void foo01() {}
}

class A with M {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }

  Future<void> test_class_method_with_namedParameters() async {
    await computeSuggestions('''
class A {
  void foo01(int a, int b, { int? c, int? d }) {}
}

class B extends A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01(int a, int b, {int? c, int? d}) {
    // TODO: implement foo01
    super.foo01(a, b, c: c, d: d);
  }
    kind: override
    displayText: foo01(int a, int b, {int? c, int? d}) { … }
    selection: 90 30
''');
  }

  Future<void> test_class_method_without_namedParameters() async {
    await computeSuggestions('''
class A {
  void foo01(int a, int b) {}
}

class B extends A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01(int a, int b) {
    // TODO: implement foo01
    super.foo01(a, b);
  }
    kind: override
    displayText: foo01(int a, int b) { … }
    selection: 72 18
''');
  }

  Future<void> test_class_operator_eqEq() async {
    await computeSuggestions('''
class A {
  opera^
}
''');

    printerConfiguration.filter = (suggestion) {
      return suggestion.completion.contains('==(');
    };

    assertResponse(r'''
replacement
  left: 5
suggestions
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    displayText: ==(Object other) { … }
    selection: 75 22
''');
  }

  Future<void> test_class_operator_plus() async {
    await computeSuggestions('''
class A {
  int operator +(int other) { }
}

class B extends A {
  opera^
}
''');

    printerConfiguration.filter = (suggestion) {
      return suggestion.completion.contains('+(');
    };

    assertResponse(r'''
replacement
  left: 5
suggestions
  @override
  int operator +(int other) {
    // TODO: implement +
    return super + other;
  }
    kind: override
    displayText: +(int other) { … }
    selection: 69 21
''');
  }

  Future<void> test_extension_method() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

extension E on A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
''');
  }

  Future<void> test_mixin_beforeMethod_atOverride_skipLine() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

mixin B on A {
  @over^

  void bar() {}
}
''');

    assertResponse(r'''
replacement
  left: 4
suggestions
  override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: override foo01() { … }
    selection: 59 14
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void> test_mixin_beforeRightBrace() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

mixin B on A {
  ^
}
''');

    assertResponse(r'''
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }

  Future<void> test_mixin_beforeRightBrace_atOverride() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

mixin B on A {
  @over^
}
''');

    assertResponse(r'''
replacement
  left: 4
suggestions
  override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: override foo01() { … }
    selection: 59 14
  override
    kind: topLevelVariable
    displayText: null
''');
  }

  Future<void> test_mixin_beforeRightBrace_partial() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

mixin B on A {
  foo0^
}
''');

    assertResponse(r'''
replacement
  left: 4
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }

  Future<void> test_mixin_method_fromConstraints_alreadyOverridden() async {
    await computeSuggestions('''
class A {
  void foo01() {}
  void foo02() {}
}

mixin M on A {
  void foo02() {}
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }

  Future<void> test_mixin_method_fromImplements() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

mixin M implements A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
  }
    kind: override
    displayText: foo01() { … }
    selection: 55
''');
  }

  Future<void> test_mixin_method_fromSuperclassConstraint() async {
    await computeSuggestions('''
class A {
  void foo01() {}
}

mixin M on A {
  foo^
}
''');

    assertResponse(r'''
replacement
  left: 3
suggestions
  @override
  void foo01() {
    // TODO: implement foo01
    super.foo01();
  }
    kind: override
    displayText: foo01() { … }
    selection: 60 14
''');
  }
}

class _Context {
  final bool isClass;
  final bool isEnum;
  final bool isExtension;
  final bool isExtensionType;
  final bool isMixin;

  _Context({
    this.isClass = false,
    this.isEnum = false,
    this.isExtension = false,
    this.isExtensionType = false,
    this.isMixin = false,
  });

  String get where => isClass
      ? ' in class'
      : isEnum
          ? ' in enum'
          : isExtension
              ? ' in extension'
              : isExtensionType
                  ? ' in extension type'
                  : ' in mixin';
}

extension on Iterable<Keyword> {
  String get asKeywordSuggestions {
    return map((keyword) {
      return '''
  ${keyword.lexeme}
    kind: keyword''';
    }).join('\n');
  }
}
