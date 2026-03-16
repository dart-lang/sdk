// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitOnlyFuturesBulkTest);
    defineReflectiveTests(AwaitOnlyFuturesLintTest);
    defineReflectiveTests(InvalidCovariantModifierInPrimaryConstructorBulkTest);
    defineReflectiveTests(InvalidCovariantModifierInPrimaryConstructorTest);
    defineReflectiveTests(RepresentationFieldModifierTest);
    defineReflectiveTests(UnnecessaryAwaitInReturnLintTest);
  });
}

@reflectiveTest
class AwaitOnlyFuturesBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.await_only_futures;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() async {
  print(await 23);
}

f2() async {
  print(await 'hola');
}
''');
    await assertHasFix('''
f() async {
  print(23);
}

f2() async {
  print('hola');
}
''');
  }
}

@reflectiveTest
class AwaitOnlyFuturesLintTest extends RemoveKeywordLintTest {
  @override
  String get lintCode => LintNames.await_only_futures;

  Future<void> test_intLiteral() async {
    await resolveTestCode('''
bad() async {
  print(await 23);
}
''');
    await assertHasFix('''
bad() async {
  print(23);
}
''');
  }

  Future<void> test_stringLiteral() async {
    await resolveTestCode('''
bad() async {
  print(await 'hola');
}
''');
    await assertHasFix('''
bad() async {
  print('hola');
}
''');
  }
}

@reflectiveTest
class InvalidCovariantModifierInPrimaryConstructorBulkTest
    extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A(covariant final int v);
class B(covariant final int v);
class C<T>(covariant final T v);
''');
    await assertHasFix('''
class A(final int v);
class B(final int v);
class C<T>(final T v);
''');
  }
}

@reflectiveTest
class InvalidCovariantModifierInPrimaryConstructorTest
    extends RemoveKeywordTest {
  Future<void> test_requiredNamed_withComment() async {
    await resolveTestCode('''
class C({covariant /* ? */ final int v = 0});
''');
    await assertHasFix('''
class C({/* ? */ final int v = 0});
''');
  }

  Future<void> test_requiredPositional() async {
    await resolveTestCode('''
class C<T>(covariant final T v);
''');
    await assertHasFix('''
class C<T>(final T v);
''');
  }
}

abstract class RemoveKeywordLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeKeyword;
}

abstract class RemoveKeywordTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeKeyword;
}

@reflectiveTest
class RepresentationFieldModifierTest extends RemoveKeywordTest {
  Future<void> test_requiredPositional() async {
    await resolveTestCode('''
extension type E<T>(var T v);
''');
    await assertHasFix('''
extension type E<T>(T v);
''');
  }
}

@reflectiveTest
class UnnecessaryAwaitInReturnLintTest extends RemoveKeywordLintTest {
  @override
  String get lintCode => LintNames.unnecessary_await_in_return;

  Future<void> test_arrow() async {
    await resolveTestCode(r'''
class A {
  Future<int> f() async => await future;
}
final future = Future.value(1);
''');
    await assertHasFix(r'''
class A {
  Future<int> f() async => future;
}
final future = Future.value(1);
''');
  }

  Future<void> test_expressionBody() async {
    await resolveTestCode(r'''
class A {
  Future<int> f() async {
    return await future;
  }
}
final future = Future.value(1);
''');
    await assertHasFix(r'''
class A {
  Future<int> f() async {
    return future;
  }
}
final future = Future.value(1);
''');
  }
}
