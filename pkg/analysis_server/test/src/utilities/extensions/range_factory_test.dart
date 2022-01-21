// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RangeFactory_NodeInListTest);
    defineReflectiveTests(RangeFactory_NodeInListWithCommentsTest);
    defineReflectiveTests(RangeFactory_NodeWithCommentsTest);
  });
}

abstract class BaseRangeFactoryTest extends AbstractSingleUnitTest {
  /// Assuming that the test code starts with a function whose block body starts
  /// with a method invocation, return the list of arguments in that invocation.
  NodeList<Expression> get _argumentList {
    var invocation = findNode.methodInvocations.single;
    return invocation.argumentList.arguments;
  }

  void _assertArgumentRange(int index, SourceRange expectedRange) {
    var list = _argumentList;
    expect(range.nodeInListWithComments(testUnit.lineInfo!, list, list[index]),
        expectedRange);
  }

  void _assertClassMemberRanges(Map<int, SourceRange> expectedRanges) {
    var class_ = findNode.classDeclaration('class');
    var list = class_.members;
    for (var entry in expectedRanges.entries) {
      expect(range.nodeWithComments(testUnit.lineInfo!, list[entry.key]),
          entry.value);
    }
  }

  void _assertUnitRanges(Map<int, SourceRange> expectedRanges) {
    var list = testUnit.declarations;
    for (var entry in expectedRanges.entries) {
      expect(range.nodeWithComments(testUnit.lineInfo!, list[entry.key]),
          entry.value);
    }
  }

  /// Create a [SourceRange] for the positions start/end before the supplied
  /// search strings.
  SourceRange _range({
    String? startsBefore,
    String? startsAfter,
    String? endsBefore,
    String? endsAfter,
  }) {
    expect(startsBefore == null, isNot(startsAfter == null),
        reason: 'Specify exactly one of startsBefore/startsAfter');
    expect(endsBefore == null, isNot(endsAfter == null),
        reason: 'Specify exactly one of endsBefore/endsAfter');

    final offset = startsBefore != null
        ? testCode.indexOf(startsBefore)
        : testCode.indexOf(startsAfter!) + startsAfter.length;
    final end = endsBefore != null
        ? testCode.indexOf(endsBefore)
        : testCode.indexOf(endsAfter!) + endsAfter.length;

    expect(offset, greaterThanOrEqualTo(0));
    expect(end, greaterThanOrEqualTo(0));

    return SourceRange(offset, end - offset);
  }
}

/// Copied from `analyzer_plugin/test/utilities/range_factory_test.dart` in
/// order to ensure backward compatibility.
@reflectiveTest
class RangeFactory_NodeInListTest extends BaseRangeFactoryTest {
  // TODO(brianwilkerson) When the tested method becomes public API then these
  //  two classes should be merged.
  Future<void> test_argumentList_first_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1, b: 2);
}
void g({int? a, int? b}) {}
''');
    _assertArgumentRange(0, SourceRange(15, 6));
  }

  Future<void> test_argumentList_first_positional() async {
    await resolveTestCode('''
void f() {
  g(1, 2);
}
void g(int a, int b) {}
''');
    _assertArgumentRange(0, SourceRange(15, 3));
  }

  Future<void> test_argumentList_last_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1, b: 2);
}
void g({int? a, int? b}) {}
''');
    _assertArgumentRange(1, SourceRange(19, 6));
  }

  Future<void> test_argumentList_last_positional() async {
    await resolveTestCode('''
void f() {
  g(1, 2);
}
void g(int a, int b) {}
''');
    _assertArgumentRange(1, SourceRange(16, 3));
  }

  Future<void> test_argumentList_middle_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1, b: 2, c: 3);
}
void g({int? a, int? b, int? c}) {}
''');
    _assertArgumentRange(1, SourceRange(19, 6));
  }

  Future<void> test_argumentList_middle_positional() async {
    await resolveTestCode('''
void f() {
  g(1, 2, 3);
}
void g(int a, int b, int c) {}
''');
    _assertArgumentRange(1, SourceRange(16, 3));
  }

  Future<void> test_argumentList_only_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1);
}
void g({int? a}) {}
''');
    _assertArgumentRange(0, SourceRange(15, 4));
  }

  Future<void> test_argumentList_only_named_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(a: 1,);
}
void g({int? a}) {}
''');
    _assertArgumentRange(0, SourceRange(15, 5));
  }

  Future<void> test_argumentList_only_positional() async {
    await resolveTestCode('''
void f() {
  g(1);
}
void g(int a) {}
''');
    _assertArgumentRange(0, SourceRange(15, 1));
  }

  Future<void> test_argumentList_only_positional_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(1,);
}
void g(int a) {}
''');
    _assertArgumentRange(0, SourceRange(15, 2));
  }
}

@reflectiveTest
class RangeFactory_NodeInListWithCommentsTest extends BaseRangeFactoryTest {
  Future<void> test_argumentList_first_named_leadingAndTrailingComment() async {
    await resolveTestCode('''
void f() {
  g(
    // comment
    a: 1, // comment
    // comment
    b: 2,
  );
}
void g({int? a, int? b}) {}
''');
    _assertArgumentRange(0, SourceRange(20, 36));
  }

  Future<void> test_argumentList_first_named_leadingComment() async {
    await resolveTestCode('''
void f() {
  g(
    // comment
    a: 1,
    // comment
    b: 2,
  );
}
void g({int? a, int? b}) {}
''');
    _assertArgumentRange(0, SourceRange(20, 25));
  }

  Future<void> test_argumentList_first_named_trailingComment() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1, // comment
    // comment
    b: 2,
  );
}
void g({int? a, int? b}) {}
''');
    _assertArgumentRange(0, SourceRange(20, 21));
  }

  Future<void> test_argumentList_last_named_leadingAndTrailingComment() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1, // comment
    // comment
    b: 2, // comment
  );
}
void g({int? a, int? b}) {}
''');
    _assertArgumentRange(1, SourceRange(36, 36));
  }

  Future<void> test_argumentList_last_named_leadingComment() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1, // comment
    // comment
    b: 2,
  );
}
void g({int? a, int? b}) {}
''');
    _assertArgumentRange(1, SourceRange(36, 25));
  }

  Future<void> test_argumentList_last_named_trailingComment() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1, // comment
    b: 2, // comment
  );
}
void g({int? a, int? b}) {}
''');
    _assertArgumentRange(1, SourceRange(36, 21));
  }

  Future<void>
      test_argumentList_last_named_trailingComment_commentAfterTrailing() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1, // comment
    b: 2, // comment
    // final comment
  );
}
void g({int? a, int? b}) {}
''');
    _assertArgumentRange(1, SourceRange(36, 21));
  }

  Future<void>
      test_argumentList_middle_named_leadingAndTrailingComment() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1, // comment
    // comment
    b: 2, // comment
    // comment
    c: 3,
  );
}
void g({int? a, int? b, int? c}) {}
''');
    _assertArgumentRange(1, SourceRange(36, 36));
  }

  Future<void> test_argumentList_middle_named_leadingComment() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1, // comment
    // comment
    b: 2,
    // comment
    c: 3,
  );
}
void g({int? a, int? b, int? c}) {}
''');
    _assertArgumentRange(1, SourceRange(36, 25));
  }

  Future<void> test_argumentList_middle_named_trailingComment() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1, // comment
    b: 2, // comment
    // comment
    c: 3,
  );
}
void g({int? a, int? b, int? c}) {}
''');
    _assertArgumentRange(1, SourceRange(36, 21));
  }

  Future<void>
      test_argumentList_middle_named_trailingComment_noTrailingOnPrevious() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1,
    b: 2, // comment
    c: 3,
  );
}
void g({int? a, int? b, int? c}) {}
''');
    _assertArgumentRange(1, SourceRange(25, 21));
  }

  Future<void> test_argumentList_only_named_leadingAndTrailingComment() async {
    await resolveTestCode('''
void f() {
  g(
    // comment
    a: 1, // comment
  );
}
void g({int? a}) {}
''');
    _assertArgumentRange(0, SourceRange(20, 31));
  }

  Future<void> test_argumentList_only_named_leadingComment() async {
    await resolveTestCode('''
void f() {
  g(
    // comment
    a: 1,
  );
}
void g({int? a}) {}
''');
    _assertArgumentRange(0, SourceRange(20, 20));
  }

  Future<void> test_argumentList_only_named_trailingComment() async {
    await resolveTestCode('''
void f() {
  g(
    a: 1, // comment
  );
}
void g({int? a}) {}
''');
    _assertArgumentRange(0, SourceRange(20, 16));
  }
}

@reflectiveTest
class RangeFactory_NodeWithCommentsTest extends BaseRangeFactoryTest {
  Future<void> test_class_multiple_leading() async {
    await resolveTestCode('''
class A {
  // 1
  int foo = 1;
  // 2
  int bar = 2;
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: '// 1', endsAfter: '= 1;'),
      1: _range(startsBefore: '// 2', endsAfter: '= 2;'),
    });
  }

  Future<void> test_class_multiple_leadingAndTrailing() async {
    await resolveTestCode('''
class A {
  // 2
  int foo = 1; // 3
  // 4
  int bar = 1; // 5
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
      1: _range(startsBefore: '// 4', endsAfter: '// 5'),
    });
  }

  Future<void>
      test_class_multiple_leadingAndTrailing_withClassBraceTrailing() async {
    await resolveTestCode('''
class A { // 1
  // 2
  int foo = 1; // 3
  // 4
  int bar = 1; // 5
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
      1: _range(startsBefore: '// 4', endsAfter: '// 5'),
    });
  }

  Future<void> test_class_multiple_trailing() async {
    await resolveTestCode('''
class A {
  int foo = 1; // 1
  int bar = 2; // 2
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: 'int foo', endsAfter: '// 1'),
      1: _range(startsBefore: 'int bar', endsAfter: '// 2'),
    });
  }

  Future<void> test_class_single_field_leading() async {
    await resolveTestCode('''
class A {
  // 1
  int foo = 1;
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: '// 1', endsAfter: '= 1;'),
    });
  }

  Future<void> test_class_single_field_leadingAndTrailing() async {
    await resolveTestCode('''
class A {
  // 1
  int foo = 1; // 2
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: '// 1', endsAfter: '; // 2'),
    });
  }

  Future<void>
      test_class_single_field_leadingAndTrailing_withClassBraceTrailing() async {
    await resolveTestCode('''
class A { // 1
  // 2
  int foo = 1; // 3
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
    });
  }

  Future<void> test_class_single_field_trailing() async {
    await resolveTestCode('''
class A {
  int foo = 1; // 1
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: 'int foo', endsAfter: '// 1'),
    });
  }

  Future<void> test_class_single_method_leading() async {
    await resolveTestCode('''
class A {
  // 1
  foo() {}
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: '// 1', endsAfter: '{}'),
    });
  }

  Future<void> test_class_single_method_leadingAndTrailing() async {
    await resolveTestCode('''
class A {
  // foo
  foo() {} // foo
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: '// foo', endsAfter: '} // foo'),
    });
  }

  Future<void>
      test_class_single_method_leadingAndTrailing_withClassBraceTrailing() async {
    await resolveTestCode('''
class A { // 1
  // 2
  foo() {} // 3
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
    });
  }

  Future<void> test_class_single_method_trailing() async {
    await resolveTestCode('''
class A {
  foo() {} // 1
}
''');
    _assertClassMemberRanges({
      0: _range(startsBefore: 'foo()', endsAfter: '// 1'),
    });
  }

  Future<void> test_topLevel_fileHeader_dartDoc() async {
    await resolveTestCode('''
// Copyright (c) ...
// ...

/// 1
int foo = 1; // 2

/// 3
int bar = 1; // 4
''');
    _assertUnitRanges({
      0: _range(startsBefore: '/// 1', endsAfter: '// 2'),
      1: _range(startsBefore: '/// 3', endsAfter: '// 4'),
    });
  }

  Future<void> test_topLevel_fileHeader_noDartDoc() async {
    await resolveTestCode('''
// Copyright (c) ...
// ...

int foo = 1; // 2

int bar = 1; // 4
''');
    _assertUnitRanges({
      0: _range(startsBefore: 'int foo', endsAfter: '// 2'),
      1: _range(startsBefore: 'int bar', endsAfter: '// 4'),
    });
  }

  Future<void> test_topLevel_languageVersion_dartDoc() async {
    await resolveTestCode('''
// @dart = 2.8

/// 1
int foo = 1; // 2

/// 3
int bar = 1; // 4
''');
    _assertUnitRanges({
      0: _range(startsBefore: '/// 1', endsAfter: '// 2'),
      1: _range(startsBefore: '/// 3', endsAfter: '// 4'),
    });
  }

  Future<void> test_topLevel_languageVersion_noDartDoc() async {
    await resolveTestCode('''
// @dart = 2.8

int foo = 1; // 2

int bar = 1; // 4
''');
    _assertUnitRanges({
      0: _range(startsBefore: 'int foo', endsAfter: '// 2'),
      1: _range(startsBefore: 'int bar', endsAfter: '// 4'),
    });
  }

  Future<void> test_topLevel_multiple_leading() async {
    await resolveTestCode('''
import '';

// 1
int foo = 1;

// 2
int bar = 2;
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 1', endsAfter: '= 1;'),
      1: _range(startsBefore: '// 2', endsAfter: '= 2;'),
    });
  }

  Future<void> test_topLevel_multiple_leadingAndTrailing() async {
    await resolveTestCode('''
import '';

// 2
int foo = 1; // 3

// 4
int bar = 1; // 5
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
      1: _range(startsBefore: '// 4', endsAfter: '// 5'),
    });
  }

  Future<void> test_topLevel_multiple_mixedComents() async {
    await resolveTestCode('''
import '';

// 1
// 2
int foo = 1; // 3

// 4
// 5
int bar = 1; // 6
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 1', endsAfter: '// 3'),
      1: _range(startsBefore: '// 4', endsAfter: '// 6'),
    });
  }

  Future<void> test_topLevel_multiple_trailing() async {
    await resolveTestCode('''
int foo = 1; // 1
int bar = 2; // 2
''');
    _assertUnitRanges({
      0: _range(startsBefore: 'int foo', endsAfter: '// 1'),
      1: _range(startsBefore: 'int bar', endsAfter: '// 2'),
    });
  }

  Future<void> test_topLevel_noTrailingNewline_leading() async {
    await resolveTestCode('''
import '';

// 1
int foo = 1;

// 2
int bar = 2;''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 1', endsAfter: '= 1;'),
      1: _range(startsBefore: '// 2', endsAfter: '= 2;'),
    });
  }

  Future<void> test_topLevel_noTrailingNewline_leadingAndTrailing() async {
    await resolveTestCode('''
import '';

// 2
int foo = 1; // 3

// 4
int bar = 1; // 5''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
      1: _range(startsBefore: '// 4', endsAfter: '// 5'),
    });
  }

  Future<void>
      test_topLevel_noTrailingNewline_leadingAndTrailing_withClassBraceTrailing() async {
    await resolveTestCode('''
import '';

// 2
int foo = 1; // 3

// 4
int bar = 1; // 5''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
      1: _range(startsBefore: '// 4', endsAfter: '// 5'),
    });
  }

  Future<void> test_topLevel_noTrailingNewline_trailing() async {
    await resolveTestCode('''
import '';

int foo = 1; // 1
int bar = 2; // 2''');
    _assertUnitRanges({
      0: _range(startsBefore: 'int foo', endsAfter: '// 1'),
      1: _range(startsBefore: 'int bar', endsAfter: '// 2'),
    });
  }

  Future<void> test_topLevel_single_field_leading() async {
    await resolveTestCode('''
import '';

// 1
int foo = 1;
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 1', endsAfter: '= 1;'),
    });
  }

  Future<void> test_topLevel_single_field_leadingAndTrailing() async {
    await resolveTestCode('''
import '';

// 1
int foo = 1; // 2
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 1', endsAfter: '// 2'),
    });
  }

  Future<void>
      test_topLevel_single_field_leadingAndTrailing_withClassBraceTrailing() async {
    await resolveTestCode('''
import '';

// 2
int foo = 1; // 3
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
    });
  }

  Future<void> test_topLevel_single_field_trailing() async {
    await resolveTestCode('''
import '';

int foo = 1; // 1
''');
    _assertUnitRanges({
      0: _range(startsBefore: 'int foo', endsAfter: '// 1'),
    });
  }

  Future<void> test_topLevel_single_method_leading() async {
    await resolveTestCode('''
import '';

// 1
foo() {}
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 1', endsAfter: '{}'),
    });
  }

  Future<void> test_topLevel_single_method_leadingAndTrailing() async {
    await resolveTestCode('''
import '';

// 1
foo() {} // 2
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 1', endsAfter: '// 2'),
    });
  }

  Future<void>
      test_topLevel_single_method_leadingAndTrailing_withClassBraceTrailing() async {
    await resolveTestCode('''
import '';

// 1
foo() {} // 2
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 1', endsAfter: '// 2'),
    });
  }

  Future<void> test_topLevel_single_method_trailing() async {
    await resolveTestCode('''
foo() {} // 1
''');
    _assertUnitRanges({
      0: _range(startsBefore: 'foo()', endsAfter: '// 1'),
    });
  }

  Future<void> test_topLevel_withDirectives_leading() async {
    await resolveTestCode('''
import 'dart:async';

// 1
int foo = 1;

// 2
int bar = 2;
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 1', endsAfter: '= 1;'),
      1: _range(startsBefore: '// 2', endsAfter: '= 2;'),
    });
  }

  Future<void> test_topLevel_withDirectives_leadingAndTrailing() async {
    await resolveTestCode('''
import 'dart:async';

// 2
int foo = 1; // 3

// 4
int bar = 1; // 5
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
      1: _range(startsBefore: '// 4', endsAfter: '// 5'),
    });
  }

  Future<void>
      test_topLevel_withDirectives_leadingAndTrailing_withClassBraceTrailing() async {
    await resolveTestCode('''
import 'dart:async';

// 2
int foo = 1; // 3

// 4
int bar = 1; // 5
''');
    _assertUnitRanges({
      0: _range(startsBefore: '// 2', endsAfter: '// 3'),
      1: _range(startsBefore: '// 4', endsAfter: '// 5'),
    });
  }

  Future<void> test_topLevel_withDirectives_trailing() async {
    await resolveTestCode('''
import 'dart:async';

int foo = 1; // 1
int bar = 2; // 2
''');
    _assertUnitRanges({
      0: _range(startsBefore: 'int foo', endsAfter: '// 1'),
      1: _range(startsBefore: 'int bar', endsAfter: '// 2'),
    });
  }
}
