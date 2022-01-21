// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddFieldFormalParametersTest);
  });
}

@reflectiveTest
class AddFieldFormalParametersTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_FIELD_FORMAL_PARAMETERS;

  Future<void> test_flutter_nullable() async {
    writeTestPackageConfig(
      flutter: true,
    );

    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b;
  final int? c;
  final int d;

  MyWidget({required Key key, required this.a}) : super(key: key);
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  final int a;
  final int b;
  final int? c;
  final int d;

  MyWidget({required Key key, required this.a, required this.b, this.c, required this.d}) : super(key: key);
}
''');
  }

  Future<void> test_flutter_potentiallyNullable() async {
    writeTestPackageConfig(
      flutter: true,
    );

    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget<T> extends StatelessWidget {
  final int a;
  final int b;
  final T c;
  final int d;

  MyWidget({required Key key, required this.a}) : super(key: key);
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';

class MyWidget<T> extends StatelessWidget {
  final int a;
  final int b;
  final T c;
  final int d;

  MyWidget({required Key key, required this.a, required this.b, required this.c, required this.d}) : super(key: key);
}
''');
  }

  Future<void> test_hasRequiredParameter() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a);
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, this.b, this.c);
}
''');
  }

  Future<void> test_noParameters() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test();
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, this.b, this.c);
}
''');
  }

  Future<void> test_noRequiredParameter() async {
    await resolveTestCode('''
class Test {
  final int a;
  final int b;
  final int c;
  Test([this.c = 0]);
}
''');
    await assertHasFix('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, this.b, [this.c = 0]);
}
''');
  }

  Future<void> test_notAllFinal() async {
    await resolveTestCode('''
class Test {
  final int a;
  int b = 0;
  final int c;
  Test();
}
''');
    await assertHasFix('''
class Test {
  final int a;
  int b = 0;
  final int c;
  Test(this.a, this.c);
}
''');
  }
}
