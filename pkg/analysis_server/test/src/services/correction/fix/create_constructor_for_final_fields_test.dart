// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateConstructorForFinalFieldsTest);
    defineReflectiveTests(CreateConstructorForFinalFieldsWithoutNullSafetyTest);
    defineReflectiveTests(
        CreateConstructorForFinalFieldsWithoutSuperParametersTest);
  });
}

@reflectiveTest
class CreateConstructorForFinalFieldsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS;

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
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b = 2;
  final int? c;

  const MyWidget({super.key, required this.a, this.c});
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
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
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final Widget child;
  final int? b;

  const MyWidget({super.key, required this.a, this.b, required this.child});
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
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
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final List<Widget> children;
  final int? b;

  const MyWidget({super.key, required this.a, this.b, required this.children});
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
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
    await assertHasFix('''
class Test {
  Test(this.a, this.c);

  final int a;
  final int b = 2;
  final int c;
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
  }

  Future<void> test_class_simple() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b = 2;
  final int c;
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b = 2;
  final int c;

  Test(this.a, this.c);
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
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
    await assertHasFix('''
enum E {
  v(0, 2);
  final int a;
  final int b = 1;
  final int c;

  const E(this.a, this.c);
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
  }

  Future<void> test_topLevelField() async {
    await resolveTestCode('''
final int v;
''');
    await assertNoFix();
  }
}

@reflectiveTest
class CreateConstructorForFinalFieldsWithoutNullSafetyTest
    extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS;

  @override
  String get testPackageLanguageVersion => '2.9';

  Future<void> test_class_flutter() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b = 2;
  final int c;
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b = 2;
  final int c;

  const MyWidget({Key key, this.a, this.c}) : super(key: key);
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
  }

  Future<void> test_class_flutter_childLast() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final Widget child;
  final int b;
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final Widget child;
  final int b;

  const MyWidget({Key key, this.a, this.b, this.child}) : super(key: key);
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
  }

  Future<void> test_class_flutter_childrenLast() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final List<Widget> children;
  final int b;
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final List<Widget> children;
  final int b;

  const MyWidget({Key key, this.a, this.b, this.children}) : super(key: key);
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
  }
}

@reflectiveTest
class CreateConstructorForFinalFieldsWithoutSuperParametersTest
    extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS;

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
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b = 2;
  final int? c;

  const MyWidget({Key? key, required this.a, this.c}) : super(key: key);
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
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
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final Widget child;
  final int? b;

  const MyWidget({Key? key, required this.a, this.b, required this.child}) : super(key: key);
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
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
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final List<Widget>? children;
  final int? b;

  const MyWidget({Key? key, required this.a, this.b, this.children}) : super(key: key);
}
''', errorFilter: (error) {
      return error.message.contains("'a'");
    });
  }
}
