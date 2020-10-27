// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateConstructorForFinalFieldsTest);
    defineReflectiveTests(CreateConstructorForFinalFieldsWithNullSafetyTest);
  });
}

@reflectiveTest
class CreateConstructorForFinalFieldsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS;

  Future<void> test_flutter() async {
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

  Future<void> test_flutter_childLast() async {
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

  Future<void> test_flutter_childrenLast() async {
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

  Future<void> test_inTopLevelMethod() async {
    await resolveTestCode('''
main() {
  final int v;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_simple() async {
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

  Future<void> test_topLevelField() async {
    await resolveTestCode('''
final int v;
''');
    await assertNoFix();
  }
}

@reflectiveTest
class CreateConstructorForFinalFieldsWithNullSafetyTest extends FixProcessorTest
    with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS;

  Future<void> test_excludesLate() async {
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
}
