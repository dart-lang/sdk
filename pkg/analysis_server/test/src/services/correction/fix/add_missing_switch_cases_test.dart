// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingSwitchCasesTest_SwitchExpression);
    defineReflectiveTests(AddMissingSwitchCasesTest_SwitchStatement);
  });
}

@reflectiveTest
class AddMissingSwitchCasesTest_SwitchExpression
    extends _AddMissingSwitchCasesTest {
  @override
  FixKind get kind => DartFixKind.addMissingSwitchCases;

  Future<void> test_bool_hasFalse() async {
    await resolveTestCode('''
int f(bool x) {
  return switch (x) {
    false => 0,
  };
}
''');
    await assertHasFixes([
      '''
int f(bool x) {
  return switch (x) {
    false => 0,
    // TODO: Handle this case.
    true => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_bool_hasTrue() async {
    await resolveTestCode('''
int f(bool x) {
  return switch (x) {
    true => 0,
  };
}
''');
    await assertHasFixes([
      '''
int f(bool x) {
  return switch (x) {
    true => 0,
    // TODO: Handle this case.
    false => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_enum_hasFirst() async {
    await resolveTestCode('''
enum E {
  first, second, third
}

int f(E x) {
  return switch (x) {
    E.first => 0,
  };
}
''');
    await assertHasFixes([
      '''
enum E {
  first, second, third
}

int f(E x) {
  return switch (x) {
    E.first => 0,
    // TODO: Handle this case.
    E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    E.third => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_enum_importedWithPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {
  first, second, third
}
''');

    await resolveTestCode('''
import 'a.dart' as prefix;

int f(prefix.E x) {
  return switch (x) {
  };
}
''');
    await assertHasFixes([
      '''
import 'a.dart' as prefix;

int f(prefix.E x) {
  return switch (x) {
    // TODO: Handle this case.
    prefix.E.first => throw UnimplementedError(),
    // TODO: Handle this case.
    prefix.E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    prefix.E.third => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_enum_notImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {
  first, second, third
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

var value = E.first;
''');

    createAnalysisOptionsFile(lints: [LintNames.prefer_relative_imports]);

    await resolveTestCode('''
import 'b.dart';

int f() {
  return switch (value) {
  };
}
''');
    await assertHasFixes([
      '''
import 'a.dart';
import 'b.dart';

int f() {
  return switch (value) {
    // TODO: Handle this case.
    E.first => throw UnimplementedError(),
    // TODO: Handle this case.
    E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    E.third => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_enum_privateEnum() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum _E {
  first, second
}

var e = _E.first;
''');

    await resolveTestCode('''
import 'a.dart';

int f() {
  return switch (e) {
  };
}
''');
    await assertHasFixes([
      '''
import 'a.dart';

int f() {
  return switch (e) {
    // TODO: Handle this case.
    _ => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_enum_privateMemberInOtherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {
  first, second, _unknown
}
''');

    await resolveTestCode('''
import 'a.dart';

int f(E x) {
  return switch (x) {
    E.first => 0,
  };
}
''');
    await assertHasFixes([
      '''
import 'a.dart';

int f(E x) {
  return switch (x) {
    E.first => 0,
    // TODO: Handle this case.
    E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    _ => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_enum_privateMemberInSameLibrary() async {
    await resolveTestCode('''
enum E {
  first, second, _unknown
}

int f(E x) {
  return switch (x) {
    E.first => 0,
  };
}
''');
    await assertHasFixes([
      '''
enum E {
  first, second, _unknown
}

int f(E x) {
  return switch (x) {
    E.first => 0,
    // TODO: Handle this case.
    E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    E._unknown => throw UnimplementedError(),
  };
}
''',
    ], filter: (e) => e.diagnosticCode == diag.nonExhaustiveSwitchExpression);
  }

  Future<void> test_incomplete_switchExpression() async {
    await resolveTestCode('''
enum E {a, b, c}
int f(E e) => switch(e
''');
    await assertNoFix(
      filter: (diagnostic) =>
          diagnostic.diagnosticCode == diag.nonExhaustiveSwitchExpression,
    );
  }

  Future<void> test_nullable_unhandledNull() async {
    await resolveTestCode('''
enum E {a, b, c}
int f(E? e) => switch (e) {
  E.a => 0,
  E.b => 1,
};
''');
    await assertHasFixes([
      '''
enum E {a, b, c}
int f(E? e) => switch (e) {
  E.a => 0,
  E.b => 1,
  // TODO: Handle this case.
  E.c => throw UnimplementedError(),
  // TODO: Handle this case.
  null => throw UnimplementedError(),
};
''',
    ]);
  }

  Future<void> test_num_anyDouble_intProperty() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int(hashCode: 5) => 0,
  };
}
''');
    await assertHasFixes([
      '''
int f(num x) {
  return switch (x) {
    double() => 0,
    int(hashCode: 5) => 0,
    // TODO: Handle this case.
    int() => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_num_doubleAny() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {
    double() => 0,
  };
}
''');
    await assertHasFixes([
      '''
int f(num x) {
  return switch (x) {
    double() => 0,
    // TODO: Handle this case.
    int() => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_num_doubleAny_coreWithPrefix() async {
    await resolveTestCode('''
import 'dart:core' as core;

core.int f(core.num x) {
  return switch (x) {
    core.double() => 0,
  };
}
''');
    await assertHasFixes([
      '''
import 'dart:core' as core;

core.int f(core.num x) {
  return switch (x) {
    core.double() => 0,
    // TODO: Handle this case.
    core.int() => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_num_doubleAny_intWhen() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {
    double() => 0,
    int() when x > 5 => 0,
  };
}
''');
    await assertHasFixes([
      '''
int f(num x) {
  return switch (x) {
    double() => 0,
    int() when x > 5 => 0,
    // TODO: Handle this case.
    int() => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_num_empty() async {
    await resolveTestCode('''
int f(num x) {
  return switch (x) {};
}
''');
    await assertHasFixes([
      '''
int f(num x) {
  return switch (x) {
    // TODO: Handle this case.
    double() => throw UnimplementedError(),
    // TODO: Handle this case.
    int() => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_privateEnum() async {
    newFile('$testPackageLibPath/enum.dart', r'''
enum _E { first, second }

_E f() => _E.first;
''');
    await resolveTestCode('''
import 'enum.dart';

int g() {
  return switch (f()) {
  };
}
''');
    await assertHasFixes([
      '''
import 'enum.dart';

int g() {
  return switch (f()) {
    // TODO: Handle this case.
    _ => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_privateEnumConstant() async {
    newFile('$testPackageLibPath/enum.dart', r'''
enum E { first, second, _unknown }
''');
    await resolveTestCode('''
import 'enum.dart';

int g(E e) {
  return switch (e) {
  };
}
''');
    await assertHasFixes([
      '''
import 'enum.dart';

int g(E e) {
  return switch (e) {
    // TODO: Handle this case.
    E.first => throw UnimplementedError(),
    // TODO: Handle this case.
    E.second => throw UnimplementedError(),
    // TODO: Handle this case.
    _ => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_privateEnumConstant_privateMissing() async {
    newFile('$testPackageLibPath/enum.dart', r'''
enum E { first, second, _unknown }
''');
    await resolveTestCode('''
import 'enum.dart';

int g(E e) {
  return switch (e) {
    E.first => 0,
    E.second => 1,
  };
}
''');
    await assertHasFixes([
      '''
import 'enum.dart';

int g(E e) {
  return switch (e) {
    E.first => 0,
    E.second => 1,
    // TODO: Handle this case.
    _ => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_privateEnumConstant_recordMultipleMissing() async {
    newFile('$testPackageLibPath/enum.dart', r'''
enum E1 { a, b }
enum E2 { first, second, _unknown }
''');
    await resolveTestCode('''
import 'enum.dart';

int g((E1, E2) e) {
  return switch (e) {
    (E1.a, E2.first) => 0,
    (E1.b, E2.second) => 1,
  };
}
''');
    await assertHasFixes([
      '''
import 'enum.dart';

int g((E1, E2) e) {
  return switch (e) {
    (E1.a, E2.first) => 0,
    (E1.b, E2.second) => 1,
    // TODO: Handle this case.
    (E1.a, E2.second) => throw UnimplementedError(),
  };
}
''',
      '''
import 'enum.dart';

int g((E1, E2) e) {
  return switch (e) {
    (E1.a, E2.first) => 0,
    (E1.b, E2.second) => 1,
    // TODO: Handle this case.
    (E1.a, E2.second) => throw UnimplementedError(),
    // TODO: Handle this case.
    (E1.a, _) => throw UnimplementedError(),
  };
}
''',
      '''
import 'enum.dart';

int g((E1, E2) e) {
  return switch (e) {
    (E1.a, E2.first) => 0,
    (E1.b, E2.second) => 1,
    // TODO: Handle this case.
    (E1.a, E2.second) => throw UnimplementedError(),
    // TODO: Handle this case.
    (E1.a, _) => throw UnimplementedError(),
    // TODO: Handle this case.
    (E1.b, E2.first) => throw UnimplementedError(),
  };
}
''',
      '''
import 'enum.dart';

int g((E1, E2) e) {
  return switch (e) {
    (E1.a, E2.first) => 0,
    (E1.b, E2.second) => 1,
    // TODO: Handle this case.
    (E1.a, E2.second) => throw UnimplementedError(),
    // TODO: Handle this case.
    (E1.a, _) => throw UnimplementedError(),
    // TODO: Handle this case.
    (E1.b, E2.first) => throw UnimplementedError(),
    // TODO: Handle this case.
    (E1.b, _) => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_privateEnumConstant_recordPrivateMissing() async {
    newFile('$testPackageLibPath/enum.dart', r'''
enum E { first, second, _unknown }
''');
    await resolveTestCode('''
import 'enum.dart';

int g((E, E) e) {
  return switch (e) {
    (E.first, _) => 0,
    (E.second, _) => 1,
  };
}
''');
    await assertHasFixes([
      '''
import 'enum.dart';

int g((E, E) e) {
  return switch (e) {
    (E.first, _) => 0,
    (E.second, _) => 1,
    // TODO: Handle this case.
    _ => throw UnimplementedError(),
  };
}
''',
    ]);
  }

  Future<void> test_sealed_impl_needed() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('$otherRoot/lib/src/private.dart', '''
sealed class A {}
sealed class B implements A {}
abstract final class C implements B {}
final class BImpl extends B {}
''');
    newFile('$otherRoot/lib/exposed.dart', '''
export 'src/private.dart' show A, B, C;
''');
    updateTestPubspecFile('''
name: test
dependencies:
  other: any
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'other', rootFolder: otherRoot),
    );
    await resolveTestCode('''
import 'package:other/exposed.dart';

int f(A a) => switch (a) {
};
''');
    await assertHasFixes([
      '''
import 'package:other/exposed.dart';

int f(A a) => switch (a) {
  // TODO: Handle this case.
  C() => throw UnimplementedError(),
  // TODO: Handle this case.
  _ => throw UnimplementedError(),
};
''',
    ]);
  }

  Future<void> test_sealed_impl_neededPartial() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('$otherRoot/lib/src/private.dart', '''
sealed class A {}
sealed class B implements A {}
abstract final class C implements B {}
final class BImpl extends B {}
''');
    newFile('$otherRoot/lib/exposed.dart', '''
export 'src/private.dart' show A, B, C;
''');
    updateTestPubspecFile('''
name: test
dependencies:
  other: any
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'other', rootFolder: otherRoot),
    );
    await resolveTestCode('''
import 'package:other/exposed.dart';

int f(A a) => switch (a) {
  C() => 0,
};
''');
    await assertHasFixes([
      '''
import 'package:other/exposed.dart';

int f(A a) => switch (a) {
  C() => 0,
  // TODO: Handle this case.
  _ => throw UnimplementedError(),
};
''',
    ]);
  }

  Future<void> test_sealed_impl_nonTransitive() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('$otherRoot/lib/src/private.dart', '''
sealed class A {}
sealed class B implements A {}
final class _CImpl extends B implements C {}
final class _BImpl extends B {}
abstract final class C implements B {}
''');
    newFile('$otherRoot/lib/exposed.dart', '''
export 'src/private.dart' show A, B, C;
''');
    updateTestPubspecFile('''
name: test
dependencies:
  other: any
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'other', rootFolder: otherRoot),
    );
    await resolveTestCode('''
import 'package:other/exposed.dart';

int f(A a) => switch (a) {
};
''');
    await assertHasFixes([
      '''
import 'package:other/exposed.dart';

int f(A a) => switch (a) {
  // TODO: Handle this case.
  C() => throw UnimplementedError(),
  // TODO: Handle this case.
  _ => throw UnimplementedError(),
};
''',
    ]);
  }

  Future<void> test_sealed_impl_recordEmpty() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('$otherRoot/lib/src/private.dart', '''
sealed class A {}
sealed class B implements A {}
abstract final class C implements B {}
final class BImpl extends B {}
''');
    newFile('$otherRoot/lib/exposed.dart', '''
export 'src/private.dart' show A, B, C;
''');
    updateTestPubspecFile('''
name: test
dependencies:
  other: any
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'other', rootFolder: otherRoot),
    );
    await resolveTestCode('''
import 'package:other/exposed.dart';

int f((A, A) a) => switch (a) {
};
''');
    await assertHasFixes([
      '''
import 'package:other/exposed.dart';

int f((A, A) a) => switch (a) {
  // TODO: Handle this case.
  (_, _) => throw UnimplementedError(),
};
''',
    ]);
  }

  Future<void> test_sealed_impl_recordPartial() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('$otherRoot/lib/src/private.dart', '''
sealed class A {}
sealed class B implements A {}
abstract final class C implements B {}
final class BImpl extends B {}
''');
    newFile('$otherRoot/lib/exposed.dart', '''
export 'src/private.dart' show A, B, C;
''');
    updateTestPubspecFile('''
name: test
dependencies:
  other: any
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'other', rootFolder: otherRoot),
    );
    await resolveTestCode('''
import 'package:other/exposed.dart';

int f((A, A) a) => switch (a) {
  (C(), C()) => 0,
};
''');
    await assertHasFixes([
      '''
import 'package:other/exposed.dart';

int f((A, A) a) => switch (a) {
  (C(), C()) => 0,
  // TODO: Handle this case.
  (C(), B()) => throw UnimplementedError(),
};
''',
      '''
import 'package:other/exposed.dart';

int f((A, A) a) => switch (a) {
  (C(), C()) => 0,
  // TODO: Handle this case.
  (C(), B()) => throw UnimplementedError(),
  // TODO: Handle this case.
  (B(), _) => throw UnimplementedError(),
};
''',
    ]);
  }

  Future<void> test_sealed_impl_requestedTwice() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('$otherRoot/lib/src/private.dart', '''
sealed class A {}
sealed class B implements A {}
final class CImpl extends B implements C {}
''');
    newFile('$otherRoot/lib/exposed.dart', '''
export 'src/private.dart' show A, B;
''');
    updateTestPubspecFile('''
name: test
dependencies:
  other: any
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'other', rootFolder: otherRoot),
    );
    await resolveTestCode('''
import 'package:other/exposed.dart';

int f(A a) => switch (a) {
};
''');
    await assertHasFixWithoutApplying();
    await assertHasFixes([
      '''
import 'package:other/exposed.dart';

int f(A a) => switch (a) {
  // TODO: Handle this case.
  B() => throw UnimplementedError(),
};
''',
    ]);
  }

  Future<void> test_sealed_impl_shadow_final() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('$otherRoot/lib/src/private.dart', '''
sealed class S {}
abstract final class A extends S {}
abstract final class B extends S {}

sealed class SImpl implements S {}
final class AImpl extends SImpl implements A {}
final class BImpl extends SImpl implements B {}
''');
    newFile('$otherRoot/lib/exposed.dart', '''
export 'src/private.dart' show S, A, B;
''');
    updateTestPubspecFile('''
name: test
dependencies:
  other: any
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'other', rootFolder: otherRoot),
    );
    await resolveTestCode('''
import 'package:other/exposed.dart';

int f(S s) => switch (s) {
};
''');
    await assertHasFixes([
      '''
import 'package:other/exposed.dart';

int f(S s) => switch (s) {
  // TODO: Handle this case.
  A() => throw UnimplementedError(),
  // TODO: Handle this case.
  B() => throw UnimplementedError(),
};
''',
    ]);
  }

  Future<void> test_sealed_private() async {
    newFile('$testPackageLibPath/a.dart', '''
sealed class S {}
sealed class A implements S {}
sealed class B implements S {}
sealed class _SImpl extends S {}
class _AImpl extends _SImpl implements A {}
class _BImpl extends _SImpl implements B {}
''');

    await resolveTestCode('''
import 'a.dart';
int f(S x) {
  return switch (x) {};
}
''');
    await assertHasFixes([
      '''
import 'a.dart';
int f(S x) {
  return switch (x) {
    // TODO: Handle this case.
    A() => throw UnimplementedError(),
    // TODO: Handle this case.
    B() => throw UnimplementedError(),
  };
}
''',
    ]);
  }
}

@reflectiveTest
class AddMissingSwitchCasesTest_SwitchStatement
    extends _AddMissingSwitchCasesTest {
  @override
  FixKind get kind => DartFixKind.addMissingSwitchCases;

  bool Function(Diagnostic) get _filter {
    var hasError = false;
    return (diagnostic) {
      if (!hasError &&
          diagnostic.diagnosticCode == diag.nonExhaustiveSwitchStatement) {
        hasError = true;
        return true;
      }
      return false;
    };
  }

  Future<void> assertHasFixesWithFilter(List<String> expected) async {
    await assertHasFixes(expected, filter: _filter);
  }

  Future<void> test_empty() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixes([
      '''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_empty_singleLine() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E e) {
  switch (e) {}
}
''');
    await assertHasFixes([
      '''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_enum_privateEnum() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum _E {
  first, second
}

var e = _E.first;
''');

    await resolveTestCode('''
import 'a.dart';

void f() {
  switch (e) {
  }
}
''');
    await assertHasFixes([
      '''
import 'a.dart';

void f() {
  switch (e) {
    default:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_enum_privateMemberInOtherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b, _c}
''');

    await resolveTestCode('''
import 'a.dart';

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixes([
      '''
import 'a.dart';

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    default:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_enum_privateMemberInSameLibrary() async {
    await resolveTestCode('''
enum E {a, b, _c}
void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixes([
      '''
enum E {a, b, _c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E._c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ], filter: (e) => e.diagnosticCode == diag.nonExhaustiveSwitchStatement);
  }

  Future<void> test_final() async {
    await resolveTestCode('''
enum E {
  a(0),
  b(1);

  final int f;
  const E(this.f);
}

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixes([
      '''
enum E {
  a(0),
  b(1);

  final int f;
  const E(this.f);
}

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_import_prefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixes([
      '''
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case my.E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_import_prefix_hideDefault() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
import 'a.dart' hide E;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixesWithFilter([
      '''
import 'a.dart' hide E;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case my.E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/49759',
    reason: 'Fails because we use the wrong import (dream) in the cases',
  )
  Future<void> test_import_prefix_multiple() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
import 'a.dart' as dream;
import 'a.dart' as big;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixesWithFilter([
      '''
import 'a.dart' as dream;
import 'a.dart' as big;
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case my.E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case my.E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_import_prefix_twice() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum E {a, b}
''');
    await resolveTestCode('''
import 'a.dart';
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
  }
}
''');
    await assertHasFixesWithFilter([
      '''
import 'a.dart';
import 'a.dart' as my;

void f(my.E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_incomplete_switchStatement() async {
    await resolveTestCode(r'''
enum E {a, b, c}
void f(E e) {
  switch(e
}
''');
    await assertNoFix(filter: _filter);
  }

  Future<void> test_notBrackets() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E e) {
  switch (e)
}
''');
    await assertHasFixesWithFilter([
      '''
enum E {a, b, c}
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_nullable_handledNull() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
    case null:
  }
}
''');
    await assertHasFixes([
      '''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
    case null:
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_nullable_unhandledNull() async {
    await resolveTestCode('''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
    case E.b:
  }
}
''');
    await assertHasFixes([
      '''
enum E {a, b, c}
void f(E? e) {
  switch (e) {
    case E.a:
    case E.b:
    case E.c:
      // TODO: Handle this case.
      throw UnimplementedError();
    case null:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_num_doubleAny() async {
    await resolveTestCode('''
void f(num x) {
  switch (x) {
    case double():
  }
}
''');
    await assertHasFixes([
      '''
void f(num x) {
  switch (x) {
    case double():
    case int():
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_num_doubleAny_intProperty() async {
    await resolveTestCode('''
void f(num x) {
  switch (x) {
    case double():
    case int(hashCode: 5):
  }
}
''');
    await assertHasFixes([
      '''
void f(num x) {
  switch (x) {
    case double():
    case int(hashCode: 5):
    case int():
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_num_empty() async {
    await resolveTestCode('''
void f(num x) {
  switch (x) {}
}
''');
    await assertHasFixes([
      '''
void f(num x) {
  switch (x) {
    case double():
      // TODO: Handle this case.
      throw UnimplementedError();
    case int():
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_privateEnum() async {
    newFile('$testPackageLibPath/enum.dart', r'''
enum _E { first, second }

_E f() => _E.first;
''');
    await resolveTestCode('''
import 'enum.dart';

int g() {
  switch (f()) {
  }
}
''');
    await assertHasFixes([
      '''
import 'enum.dart';

int g() {
  switch (f()) {
    default:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_privateEnumConstant() async {
    newFile('$testPackageLibPath/enum.dart', r'''
enum E { first, second, _unknown }
''');
    await resolveTestCode('''
import 'enum.dart';

int g(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixes([
      '''
import 'enum.dart';

int g(E e) {
  switch (e) {
    case E.first:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.second:
      // TODO: Handle this case.
      throw UnimplementedError();
    default:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_privateEnumConstant_privateMissing() async {
    newFile('$testPackageLibPath/enum.dart', r'''
enum E { first, second, _unknown }
''');
    await resolveTestCode('''
import 'enum.dart';

int g(E e) {
  switch (e) {
    case E.first:
    case E.second:
      return 0;
  }
}
''');
    await assertHasFixes([
      '''
import 'enum.dart';

int g(E e) {
  switch (e) {
    case E.first:
    case E.second:
      return 0;
    default:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_sealed_impl() async {
    var otherRoot = getFolder('$packagesRootPath/other');
    newFile('$otherRoot/lib/src/private.dart', '''
sealed class A {}
sealed class B implements A {}
abstract final class C implements B {}
final class CImpl extends B implements C {}
''');
    newFile('$otherRoot/lib/exposed.dart', '''
export 'src/private.dart' show A, B, C;
''');
    updateTestPubspecFile('''
name: test
dependencies:
  other: any
''');
    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'other', rootFolder: otherRoot),
    );
    await resolveTestCode('''
import 'package:other/exposed.dart';

void f(A a) {
  switch (a) {
  }
}
''');
    await assertHasFixes([
      '''
import 'package:other/exposed.dart';

void f(A a) {
  switch (a) {
    case C():
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }

  Future<void> test_static() async {
    await resolveTestCode('''
enum E {
  a,
  b;

  static int s = 1;
}

void f(E e) {
  switch (e) {
  }
}
''');
    await assertHasFixes([
      '''
enum E {
  a,
  b;

  static int s = 1;
}

void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      throw UnimplementedError();
    case E.b:
      // TODO: Handle this case.
      throw UnimplementedError();
  }
}
''',
    ]);
  }
}

/// Common superclass for [AddMissingSwitchCasesTest_SwitchExpression] and
/// [AddMissingSwitchCasesTest_SwitchStatement] that adds extra checking to
/// the applied fix.
abstract class _AddMissingSwitchCasesTest
    extends FixProcessorForBuiltInDiagnosticTest {
  static final List<DiagnosticCode> _ignored = [
    diag.todo,
    diag.undefinedUnqualifiedNameReadNotFound,
  ];

  /// Expands [FixProcessorTest.assertHasFix] to check that a sequence of
  /// applied fixes don't have any unexpected diagnostics.
  ///
  /// This is done to ensure that the added missing cases actual make the
  /// switch exhaustive.
  Future<void> assertHasFixes(
    List<String> expectedContents, {
    DiagnosticFilter? filter,
  }) async {
    for (int index = 0; index < expectedContents.length; index++) {
      String expectedContent = expectedContents[index];
      await assertHasFix(expectedContent, filter: index > 0 ? _filter : filter);

      // Update the test source to the expected content. This should either
      // trigger another fix or be exhaustive.
      newFile(testFile.path, expectedContent);

      bool expectExhaustive = index == expectedContents.length - 1;
      if (expectExhaustive) {
        var oldVerifyNoTestUnitErrors = verifyNoTestUnitErrors;
        verifyNoTestUnitErrors = true;
        await resolveTestFile(ignore: _ignored);
        verifyNoTestUnitErrors = oldVerifyNoTestUnitErrors;
      } else {
        await resolveTestFile();
      }
    }
  }

  static bool _filter(Diagnostic diagnostic) =>
      !_ignored.contains(diagnostic.diagnosticCode);
}
