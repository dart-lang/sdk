// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/selection.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SelectionConstructorInClassTest);
    defineReflectiveTests(SelectionConstructorInEnumTest);
    defineReflectiveTests(SelectionConstructorInExtensionTypeTest);
  });
}

/// This class has all of the invocation site tests because the structure of the
/// AST at the invocation site doesn't depend on the kind of declaration
/// containing the constructor declaration.
@reflectiveTest
class SelectionConstructorInClassTest extends _SelectionConstructorTestBase {
  Future<void> test_declaration_primary_named_onConstructorName() async {
    await resolveTestCode('''
class C.n^ame() {}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_primary_named_onContainerName() async {
    await resolveTestCode('''
class C^.name() {}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_primary_named_overBoth() async {
    await resolveTestCode('''
class [!C.nam!]e() {}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_primary_onKeyword() async {
    await resolveTestCode('''
cla^ss C() {}
''');
    _assertNoConstructor();
  }

  Future<void> test_declaration_primary_unnamed() async {
    await resolveTestCode('''
class C^() {}
''');
    _assertHasConstructor();
  }

  Future<void>
  test_declaration_secondary_factory_named_onConstructorName() async {
    await resolveTestCode('''
class C {
  factory na^me() => C._();
  C._();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_factory_named_onFactory() async {
    await resolveTestCode('''
class C {
  facto^ry name() => C._();
  C._();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_factory_named_overBoth() async {
    await resolveTestCode('''
class C {
  fact[!ory na!]me() => C._();
  C._();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_factory_unnamed() async {
    await resolveTestCode('''
class C {
  facto^ry () => C._();
  C._();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_new_named_onConstructorName() async {
    await resolveTestCode('''
class C {
  new na^me();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_new_named_onNew() async {
    await resolveTestCode('''
class C {
  ne^w name();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_new_named_overBoth() async {
    await resolveTestCode('''
class C {
  ne[!w na!]me();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_new_unnamed() async {
    await resolveTestCode('''
class C {
  ^new ();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_simple_named_onClassName() async {
    await resolveTestCode('''
class C {
  ^C.name();
}
''');
    _assertHasConstructor();
  }

  Future<void>
  test_declaration_secondary_simple_named_onConstructorName() async {
    await resolveTestCode('''
class C {
  C.na^me();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_simple_named_overBoth() async {
    await resolveTestCode('''
class C {
  [!C.na!]me();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_simple_unnamed() async {
    await resolveTestCode('''
class C {
  ^C();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_invocation_named_onArgumentList() async {
    await resolveTestCode('''
class C {
  C.name();
}

void f() {
  C.name(^);
}
''');
    _assertNoConstructor();
  }

  Future<void> test_invocation_named_onClassName() async {
    await resolveTestCode('''
class C {
  C.name();
}

void f() {
  ^C.name();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_invocation_named_onConstructorName() async {
    await resolveTestCode('''
class C {
  C.name();
}

void f() {
  C.^name();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_invocation_named_overBoth() async {
    await resolveTestCode('''
class C {
  C.name();
}

void f() {
  [!C.nam!]e();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_invocation_unnamed() async {
    await resolveTestCode('''
class C() {}

void f() {
  ^C();
}
''');
    _assertHasConstructor();
  }
}

@reflectiveTest
class SelectionConstructorInEnumTest extends _SelectionConstructorTestBase {
  Future<void> test_declaration_primary_named_onConstructorName() async {
    await resolveTestCode('''
enum E.n^ame() { a.name() }
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_primary_named_onContainerName() async {
    await resolveTestCode('''
enum E^.name() { a.name() }
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_primary_named_overBoth() async {
    await resolveTestCode('''
enum [!E.nam!]e() { a.name() }
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_primary_onKeyword() async {
    await resolveTestCode('''
en^um E() { a }
''');
    _assertNoConstructor();
  }

  Future<void> test_declaration_primary_unnamed() async {
    await resolveTestCode('''
enum E^() { a }
''');
    _assertHasConstructor();
  }

  Future<void>
  test_declaration_secondary_factory_named_onConstructorName() async {
    await resolveTestCode('''
enum E {
  a._();

  factory na^me() => a;

  const E._();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_factory_named_onFactory() async {
    await resolveTestCode('''
enum E {
  a._();

  facto^ry name() => a;

  const E._();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_factory_named_overBoth() async {
    await resolveTestCode('''
enum E {
  a._();

  fa[!ctory na!]me() => a;

  const E._();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_factory_unnamed() async {
    await resolveTestCode('''
enum E {
  a._();

  facto^ry () => a;

  const E._();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_new_named_onConstructorName() async {
    await resolveTestCode('''
enum E {
  a.name();

  const new na^me();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_new_named_onNew() async {
    await resolveTestCode('''
enum E {
  a.name();

  const new^ name();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_new_named_overBoth() async {
    await resolveTestCode('''
enum E {
  a.name();

  const ne[!w na!]me();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_new_unnamed() async {
    await resolveTestCode('''
enum E {
  a();

  const ^new ();
}
''');
    _assertHasConstructor();
  }

  Future<void>
  test_declaration_secondary_simple_named_onConstructorName() async {
    await resolveTestCode('''
enum E {
  a.name();

  const E.na^me();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_simple_named_onEnumName() async {
    await resolveTestCode('''
enum E {
  a.name();

  const E^.name();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_simple_named_overBoth() async {
    await resolveTestCode('''
enum E {
  a.name();

  const [!E.na!]me();
}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_secondary_simple_unnamed() async {
    await resolveTestCode('''
enum E {
  a();

  const E^();
}
''');
    _assertHasConstructor();
  }
}

@reflectiveTest
class SelectionConstructorInExtensionTypeTest
    extends _SelectionConstructorTestBase {
  Future<void> test_declaration_primary_named_onConstructorName() async {
    await resolveTestCode('''
extension type E.n^ame(int x) {}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_primary_named_onContainerName() async {
    await resolveTestCode('''
extension type E^.name(int x) {}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_primary_named_overBoth() async {
    await resolveTestCode('''
extension type [!E.nam!]e(int x) {}
''');
    _assertHasConstructor();
  }

  Future<void> test_declaration_primary_onExtensionKeyword() async {
    await resolveTestCode('''
exten^sion type E(int x) {}
''');
    _assertNoConstructor();
  }

  Future<void> test_declaration_primary_onTypeKeyword() async {
    await resolveTestCode('''
extension ^type E(int x) {}
''');
    _assertNoConstructor();
  }

  Future<void> test_declaration_primary_unnamed() async {
    await resolveTestCode('''
extension type E^(int x) {}
''');
    _assertHasConstructor();
  }
}

abstract class _SelectionConstructorTestBase extends AbstractSingleUnitTest {
  void _assertHasConstructor() {
    expect(_getConstructor(), isA<ConstructorElement>());
  }

  void _assertNoConstructor() {
    expect(_getConstructor(), isNull);
  }

  ConstructorElement? _getConstructor() {
    var range = _getSourceRange();
    var selection = testAnalysisResult.unit.select(
      offset: range.offset,
      length: range.length,
    );
    if (selection == null) {
      fail('No selection found');
    }
    return selection.constructor();
  }

  SourceRange _getSourceRange() {
    if (parsedTestCode.positions.length == 1) {
      return SourceRange(parsedTestCode.position.offset, 0);
    } else if (parsedTestCode.ranges.length == 1) {
      return parsedTestCode.range.sourceRange;
    } else {
      fail('Invalid source range in test code.');
    }
  }
}
