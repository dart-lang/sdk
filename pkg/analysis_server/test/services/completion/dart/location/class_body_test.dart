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
    defineReflectiveTests(ClassBodyTest1);
    defineReflectiveTests(ClassBodyTest2);
    defineReflectiveTests(ClassOverrideTest1);
    defineReflectiveTests(ClassOverrideTest2);
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
  Future<void> test_afterField_beforeEnd() async {
    await computeSuggestions('''
class A {var foo; ^}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterField_beforeField() async {
    await computeSuggestions('''
class A {var bar; ^ var foo;}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeField() async {
    await computeSuggestions('''
class A {^ var foo;}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeMethodWithoutType() async {
    await computeSuggestions('''
class A { ^ foo() {}}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeMethodWithoutType_partial() async {
    await computeSuggestions('''
class A { d^ foo() {}}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  dynamic
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_afterLeftBrace_beforeRightBrace() async {
    await computeSuggestions('''
class A {^}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_nothing_x() async {
    await _checkContainers(
      line: '^',
      validator: (context) {
        _printKeywordsOrClass();

        final keywords = {
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
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''');
      },
    );
  }

  Future<void> test_static_const_x() async {
    await _checkContainers(
      line: 'static const ^',
      validator: (context) {
        _printKeywordsOrClass();

        final keywords = {
          Keyword.DYNAMIC,
          Keyword.VOID,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''');
      },
    );
  }

  Future<void> test_static_final_Ox() async {
    await _checkContainers(
      line: 'static final O^',
      validator: (context) {
        if (isProtocolVersion2) {
          _printKeywordsOrClass();
          assertResponse(r'''
replacement
  left: 1
suggestions
  Object
    kind: class
''');
        } else {
          _printKeywordsOrClass();

          final keywords = {
            Keyword.DYNAMIC,
            Keyword.VOID,
          };

          assertResponse('''
replacement
  left: 1
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''');
        }
      },
    );
  }

  Future<void> test_static_final_x() async {
    await _checkContainers(
      line: 'static final ^',
      validator: (context) {
        _printKeywordsOrClass();

        final keywords = {
          Keyword.DYNAMIC,
          Keyword.VOID,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''');
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
        if (isProtocolVersion2) {
          final keywords = {
            Keyword.FINAL,
          };

          assertResponse('''
replacement
  left: 1
suggestions
  FutureOr
    kind: class
${keywords.asKeywordSuggestions}
''');
        } else {
          // TODO(scheglov) This is wrong.
          final keywords = {
            Keyword.ABSTRACT,
            Keyword.CONST,
            Keyword.COVARIANT,
            Keyword.DYNAMIC,
            Keyword.EXTERNAL,
            Keyword.FINAL,
            Keyword.LATE,
          };

          assertResponse('''
replacement
  left: 1
suggestions
  FutureOr
    kind: class
${keywords.asKeywordSuggestions}
''');
        }
      },
    );
  }

  Future<void> test_static_late_x() async {
    await _checkContainers(
      line: 'static late ^',
      validator: (context) {
        _printKeywordsOrClass();

        final keywords = {
          Keyword.DYNAMIC,
          Keyword.FINAL,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''');
      },
    );
  }

  Future<void> test_static_x() async {
    await _checkContainers(
      line: 'static ^',
      validator: (context) {
        _printKeywordsOrClass();

        final keywords = {
          Keyword.CONST,
          Keyword.DYNAMIC,
          Keyword.FINAL,
          Keyword.LATE,
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''');
      },
    );
  }

  Future<void> test_static_x_name_eq() async {
    await _checkContainers(
      line: 'static ^ name = 0;',
      validator: (context) {
        _printKeywordsOrClass();

        final keywords = {
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
        };

        assertResponse('''
suggestions
  Object
    kind: class
${keywords.asKeywordSuggestions}
''');
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
        if (isProtocolVersion2) {
          final keywords = {
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
''');
        } else {
          final keywords = {
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
          };

          assertResponse('''
replacement
  left: 1
suggestions
  String
    kind: class
${keywords.asKeywordSuggestions}
''');
        }
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
      validator(_Context());
    }
    // extension
    {
      await computeSuggestions('''
extension on Object {
  $line
}
''');
      validator(_Context());
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
    printerConfiguration.filter = (suggestion) {
      final completion = suggestion.completion;
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
class ClassOverrideTest1 extends AbstractCompletionDriverTest
    with OverrideTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ClassOverrideTest2 extends AbstractCompletionDriverTest
    with OverrideTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin OverrideTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        if (suggestion.kind == CompletionSuggestionKind.OVERRIDE) {
          return suggestion.completion.contains('foo0');
        }
        return false;
      },
      withDisplayText: true,
    );
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
  final bool isMixin;

  _Context({
    this.isClass = false,
    this.isMixin = false,
  });
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
