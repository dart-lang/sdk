// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      CreateConstructorForFinalFieldsRequiredPositionalTest,
    );
    defineReflectiveTests(CreateConstructorForFinalFieldsRequiredNamedTest);
    defineReflectiveTests(
      CreateConstructorForFinalFieldsWithoutSuperParametersTest,
    );
  });
}

@reflectiveTest
class CreateConstructorForFinalFieldsRequiredNamedTest
    extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createConstructorForFinalFieldsRequiredNamed;

  Future<void> test_class_excludesLate() async {
    await resolveTestCode('''
class Test {
  final int a;
  late final int b;
}
''');
    await assertHasFix('''
class Test {
  final int a;
  late final int b;

  Test({required this.a});
}
''');
  }

  Future<void> test_class_flutter() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class Test extends StatelessWidget {
  final int _a;
}
''');
    await assertHasFix(
      '''
import 'package:flutter/widgets.dart';

class Test extends StatelessWidget {
  final int _a;

  const Test({super.key, required this._a});
}
''',
      filter: (error) {
        return error.message.contains("'_a' must be initialized");
      },
    );
  }

  Future<void> test_class_flutter_lint() async {
    writeTestPackageConfig(flutter: true);
    createAnalysisOptionsFile(
      lints: [LintNames.always_put_required_named_parameters_first],
    );
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class Test extends StatelessWidget {
  final int _a;
}
''');
    await assertHasFix(
      '''
import 'package:flutter/widgets.dart';

class Test extends StatelessWidget {
  final int _a;

  const Test({required this._a, super.key});
}
''',
      filter: (error) {
        return error.message.contains("'_a' must be initialized");
      },
    );
  }

  Future<void> test_class_flutter_lint_notRequired() async {
    writeTestPackageConfig(flutter: true);
    createAnalysisOptionsFile(
      lints: [LintNames.always_put_required_named_parameters_first],
    );
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class Base extends StatelessWidget {
  final int? a;

  const Base({super.key, this.a});
}

class Test extends Base {
  final int other;
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class Base extends StatelessWidget {
  final int? a;

  const Base({super.key, this.a});
}

class Test extends Base {
  final int other;

  Test({required this.other, super.key, super.a});
}
''');
  }

  Future<void> test_class_hasSuperClass_withOptionalNamed() async {
    await resolveTestCode('''
class A {
  final int? f11;
  final int? f12;

  A({this.f11, this.f12})
}

class B extends A {
  final int f21;
  final int f22;
}
''');
    await assertHasFix(
      '''
class A {
  final int? f11;
  final int? f12;

  A({this.f11, this.f12})
}

class B extends A {
  final int f21;
  final int f22;

  B({super.f11, super.f12, required this.f21, required this.f22});
}
''',
      filter: (error) {
        return error.message.contains("'f21'");
      },
    );
  }

  Future<void> test_class_hasSuperClass_withRequiredNamed() async {
    await resolveTestCode('''
class A {
  final int f11;
  final int f12;

  A({required this.f11, required this.f12})
}

class B extends A {
  final int f21;
  final int f22;
}
''');
    await assertHasFix(
      '''
class A {
  final int f11;
  final int f12;

  A({required this.f11, required this.f12})
}

class B extends A {
  final int f21;
  final int f22;

  B({required super.f11, required super.f12, required this.f21, required this.f22});
}
''',
      filter: (error) {
        return error.message.contains("'f21'");
      },
    );
  }

  Future<void> test_class_hasSuperClass_withRequiredNamed_lint() async {
    createAnalysisOptionsFile(
      lints: [LintNames.always_put_required_named_parameters_first],
    );
    await resolveTestCode('''
class A {
  final int? f11;
  final int f12;

  A({this.f11, required this.f12})
}

class B extends A {
  final int? f21;
  int? f22;
}
''');
    await assertHasFix(
      '''
class A {
  final int? f11;
  final int f12;

  A({this.f11, required this.f12})
}

class B extends A {
  final int? f21;
  int? f22;

  B({required super.f12, required this.f21, super.f11});
}
''',
      filter: (error) {
        return error.message.contains("'f21'");
      },
    );
  }

  Future<void> test_class_lint_sortConstructorsFirst() async {
    createAnalysisOptionsFile(lints: [LintNames.sort_constructors_first]);
    await resolveTestCode('''
class Test {
  final int a;
  final int b = 2;
  final int c;
}
''');
    await assertHasFix(
      '''
class Test {
  Test({required this.a, required this.c});

  final int a;
  final int b = 2;
  final int c;
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_noSuperClass() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b = 2;
  final int c;
}
''');
    await assertHasFix(
      '''
class Test {
  final int a;
  final int b = 2;
  final int c;

  Test({required this.a, required this.c});
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_noSuperClass_hasPrivate() async {
    await resolveTestCode('''
class Test {
  final int _a;
  final int _b;
  final int c;
}
''');
    await assertHasFix(
      '''
class Test {
  final int _a;
  final int _b;
  final int c;

  Test({required this._a, required this._b, required this.c});
}
''',
      filter: (error) {
        return error.diagnosticCode == diag.finalNotInitialized &&
            error.message.contains("'_a'");
      },
    );
  }

  Future<void> test_class_noSuperClass_hasPrivate_onlyUnderscores() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int _;
  final int __;
}
''');
    await assertNoFix(
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void>
  test_class_noSuperClass_hasPrivate_unsupportedPrivateNamedParameters() async {
    await resolveTestCode('''
// @dart=3.10
class Test {
  final int _a;
  final int _b;
  final int c;
}
''');
    await assertHasFix(
      '''
// @dart=3.10
class Test {
  final int _a;
  final int _b;
  final int c;

  Test({required int a, required int b, required this.c}) : _a = a, _b = b;
}
''',
      filter: (error) {
        return error.diagnosticCode == diag.finalNotInitialized &&
            error.message.contains("'_a'");
      },
    );
  }

  Future<void> test_enum() async {
    await resolveTestCode('''
enum E {
  v(a: 0, c: 2);
  final int a;
  final int b = 1;
  final int c;
}
''');
    await assertHasFix(
      '''
enum E {
  v(a: 0, c: 2);
  final int a;
  final int b = 1;
  final int c;

  const E({required this.a, required this.c});
}
''',
      filter: (error) {
        return error.message.contains("'a' must be initialized");
      },
    );
  }
}

@reflectiveTest
class CreateConstructorForFinalFieldsRequiredPositionalTest
    extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createConstructorForFinalFields;

  Future<void> test_class_excludesLate() async {
    await resolveTestCode('''
class Test {
  final int a;
  late final int b;
}
''');
    await assertHasFix('''
class Test {
  final int a;
  late final int b;

  Test(this.a);
}
''');
  }

  Future<void> test_class_flutter() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b = 2;
  final int? c;
}
''');
    await assertHasFix(
      '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b = 2;
  final int? c;

  const MyWidget({super.key, required this.a, this.c});
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_flutter_childLast() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final Widget child;
  final int? b;
}
''');
    await assertHasFix(
      '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final Widget child;
  final int? b;

  const MyWidget({super.key, required this.a, this.b, required this.child});
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_flutter_childrenLast() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final List<Widget> children;
  final int? b;
}
''');
    await assertHasFix(
      '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final List<Widget> children;
  final int? b;

  const MyWidget({super.key, required this.a, this.b, required this.children});
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_hasPrivate() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int _b;
  final int c;
}
''');
    await assertHasFix(
      '''
class Test {
  final int a;
  final int _b;
  final int c;

  Test(this.a, this._b, this.c);
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_inTopLevelMethod() async {
    await resolveTestCode('''
void f() {
  final int v;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_class_lint_sortConstructorsFirst() async {
    createAnalysisOptionsFile(lints: [LintNames.sort_constructors_first]);
    await resolveTestCode('''
class Test {
  final int a;
  final int b = 2;
  final int c;
}
''');
    await assertHasFix(
      '''
class Test {
  Test(this.a, this.c);

  final int a;
  final int b = 2;
  final int c;
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_simple() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b = 2;
  final int c;
}
''');
    await assertHasFix(
      '''
class Test {
  final int a;
  final int b = 2;
  final int c;

  Test(this.a, this.c);
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_enum_simple() async {
    await resolveTestCode('''
enum E {
  v(0, 2);
  final int a;
  final int b = 1;
  final int c;
}
''');
    await assertHasFix(
      '''
enum E {
  v(0, 2);
  final int a;
  final int b = 1;
  final int c;

  const E(this.a, this.c);
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_topLevelField() async {
    await resolveTestCode('''
final int v;
''');
    await assertNoFix();
  }
}

@reflectiveTest
class CreateConstructorForFinalFieldsWithoutSuperParametersTest
    extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createConstructorForFinalFields;

  @override
  String get testPackageLanguageVersion => '2.16';

  Future<void> test_class_flutter() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b = 2;
  final int? c;
}
''');
    await assertHasFix(
      '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b = 2;
  final int? c;

  const MyWidget({Key? key, required this.a, this.c}) : super(key: key);
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_flutter_childLast() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final Widget child;
  final int? b;
}
''');
    await assertHasFix(
      '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final Widget child;
  final int? b;

  const MyWidget({Key? key, required this.a, this.b, required this.child}) : super(key: key);
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_flutter_childrenLast() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final List<Widget>? children;
  final int? b;
}
''');
    await assertHasFix(
      '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final List<Widget>? children;
  final int? b;

  const MyWidget({Key? key, required this.a, this.b, this.children}) : super(key: key);
}
''',
      filter: (error) {
        return error.message.contains("'a'");
      },
    );
  }

  Future<void> test_class_flutter_private_field() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int _a;
  final int b;
}
''');
    await assertHasFix(
      '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int _a;
  final int b;

  const MyWidget({Key? key, required int a, required this.b}) : _a = a, super(key: key);
}
''',
      filter: (error) {
        return error.message.contains("'b'");
      },
    );
  }
}
