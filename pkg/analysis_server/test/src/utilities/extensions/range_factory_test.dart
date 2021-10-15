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
  });
}

abstract class BaseRangeFactoryTest extends AbstractSingleUnitTest {
  /// Assuming that the test code starts with a function whose block body starts
  /// with a method invocation, return the list of arguments in that invocation.
  NodeList<Expression> get _argumentList {
    var invocation = findNode.methodInvocations.single;
    return invocation.argumentList.arguments;
  }

  void _assertRange(int index, SourceRange expectedRange) {
    var list = _argumentList;
    expect(range.nodeInListWithComments(testUnit.lineInfo!, list, list[index]),
        expectedRange);
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
    _assertRange(0, SourceRange(15, 6));
  }

  Future<void> test_argumentList_first_positional() async {
    await resolveTestCode('''
void f() {
  g(1, 2);
}
void g(int a, int b) {}
''');
    _assertRange(0, SourceRange(15, 3));
  }

  Future<void> test_argumentList_last_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1, b: 2);
}
void g({int? a, int? b}) {}
''');
    _assertRange(1, SourceRange(19, 6));
  }

  Future<void> test_argumentList_last_positional() async {
    await resolveTestCode('''
void f() {
  g(1, 2);
}
void g(int a, int b) {}
''');
    _assertRange(1, SourceRange(16, 3));
  }

  Future<void> test_argumentList_middle_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1, b: 2, c: 3);
}
void g({int? a, int? b, int? c}) {}
''');
    _assertRange(1, SourceRange(19, 6));
  }

  Future<void> test_argumentList_middle_positional() async {
    await resolveTestCode('''
void f() {
  g(1, 2, 3);
}
void g(int a, int b, int c) {}
''');
    _assertRange(1, SourceRange(16, 3));
  }

  Future<void> test_argumentList_only_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1);
}
void g({int? a}) {}
''');
    _assertRange(0, SourceRange(15, 4));
  }

  Future<void> test_argumentList_only_named_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(a: 1,);
}
void g({int? a}) {}
''');
    _assertRange(0, SourceRange(15, 5));
  }

  Future<void> test_argumentList_only_positional() async {
    await resolveTestCode('''
void f() {
  g(1);
}
void g(int a) {}
''');
    _assertRange(0, SourceRange(15, 1));
  }

  Future<void> test_argumentList_only_positional_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(1,);
}
void g(int a) {}
''');
    _assertRange(0, SourceRange(15, 2));
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
    _assertRange(0, SourceRange(20, 36));
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
    _assertRange(0, SourceRange(20, 25));
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
    _assertRange(0, SourceRange(20, 21));
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
    _assertRange(1, SourceRange(36, 36));
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
    _assertRange(1, SourceRange(36, 25));
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
    _assertRange(1, SourceRange(36, 21));
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
    _assertRange(1, SourceRange(36, 21));
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
    _assertRange(1, SourceRange(36, 36));
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
    _assertRange(1, SourceRange(36, 25));
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
    _assertRange(1, SourceRange(36, 21));
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
    _assertRange(1, SourceRange(25, 21));
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
    _assertRange(0, SourceRange(20, 31));
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
    _assertRange(0, SourceRange(20, 20));
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
    _assertRange(0, SourceRange(20, 16));
  }
}
