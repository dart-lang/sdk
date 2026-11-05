// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingEnumLikeCaseClausesTest);
  });
}

@reflectiveTest
class AddMissingEnumLikeCaseClausesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.addMissingEnumCaseClauses;

  @override
  String get lintCode => LintNames.exhaustive_cases;

  bool Function(Diagnostic) get _filter {
    var hasDiagnostic = false;
    return (diagnostic) {
      var diagnosticCode = diagnostic.diagnosticCode;
      if (!hasDiagnostic &&
          diagnosticCode is LintCode &&
          diagnosticCode.lowerCaseName == lintCode) {
        hasDiagnostic = true;
        return true;
      }
      return false;
    };
  }

  Future<void> assertHasFixWithFilter(String expected) async {
    await assertHasFix(expected, filter: _filter);
  }

  Future<void> test_class_emptySwitch() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFixWithFilter('''
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_class_emptySwitch_singleLine() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {}
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFixWithFilter('''
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_class_withExistingCase_deprecatedAliases() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {
    case E.oldA:
      break;
  }
}
class E {
  @deprecated
  static const E oldA = a;
  static const E a = E._(0);
  @deprecated
  static const E oldB = b;
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFixWithFilter('''
void f(E e) {
  switch (e) {
    case E.oldA:
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
class E {
  @deprecated
  static const E oldA = a;
  static const E a = E._(0);
  @deprecated
  static const E oldB = b;
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_class_withExistingCase_dotShorthand() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {
    case .a:
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFix('''
void f(E e) {
  switch (e) {
    case .a:
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_class_withExistingCase_localAlias() async {
    await resolveTestCode('''
void f(E e) {
  const a = E.a;
  switch (e) {
    case a:
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFix('''
void f(E e) {
  const a = E.a;
  switch (e) {
    case a:
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_class_withExistingCase_parenthesized() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {
    case (E.a):
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFix('''
void f(E e) {
  switch (e) {
    case (E.a):
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_class_withExistingCase_parenthesized_language219() async {
    await resolveTestCode('''
// @dart=2.19
void f(E e) {
  switch (e) {
    case (E.a):
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFix('''
// @dart=2.19
void f(E e) {
  switch (e) {
    case (E.a):
      break;
    case E.b:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_class_withExistingCases() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFix('''
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_class_withExistingCases_language219() async {
    await resolveTestCode('''
// @dart=2.19
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFix('''
// @dart=2.19
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_extensionType_importPrefixed() async {
    newFile('$testPackageLibPath/e.dart', '''
extension type const E._(int x) {
  static const E a = E._(0);
  static const E b = E._(1);
}
''');
    await resolveTestCode('''
import 'e.dart' as prefix;

void f(prefix.E e) {
  switch (e) {
    case prefix.E.a:
      break;
  }
}
''');
    await assertHasFix('''
import 'e.dart' as prefix;

void f(prefix.E e) {
  switch (e) {
    case prefix.E.a:
      break;
    case prefix.E.b:
      // TODO: Handle this case.
      break;
  }
}
''');
  }

  Future<void> test_extensionType_withExistingCase() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {
    case E.a:
      break;
  }
}
extension type const E._(int x) {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
}
''');
    await assertHasFixWithFilter('''
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
extension type const E._(int x) {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
}
''');
  }
}
