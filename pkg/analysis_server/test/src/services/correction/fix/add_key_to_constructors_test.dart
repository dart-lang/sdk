// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddKeyToConstructorsTest);
  });
}

@reflectiveTest
class AddKeyToConstructorsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_KEY_TO_CONSTRUCTORS;

  @override
  String get lintCode => LintNames.use_key_in_widget_constructors;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_class_newline() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
}
''');
  }

  Future<void> test_class_noNewline() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);
}
''');
  }

  Future<void> test_constructor_namedParameters_withoutSuper() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget({required String s});
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget({Key? key, required String s}) : super(key: key);
}
''');
  }

  Future<void> test_constructor_namedParameters_withSuper() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget({required String s}) : super();
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget({Key? key, required String s}) : super(key: key);
}
''');
  }

  Future<void> test_constructor_noNamedParameters_withoutSuper() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget(String s);
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget(String s, {Key? key}) : super(key: key);
}
''');
  }

  Future<void> test_constructor_noNamedParameters_withSuper() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget(String s) : super();
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget(String s, {Key? key}) : super(key: key);
}
''');
  }

  Future<void> test_constructor_noParameters_withoutSuper() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget();
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget({Key? key}) : super(key: key);
}
''');
  }

  Future<void> test_constructor_noParameters_withSuper_empty() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget() : super();
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget({Key? key}) : super(key: key);
}
''');
  }

  Future<void> test_constructor_noParameters_withSuper_nonEmpty() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget() : super(text: '');
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  MyWidget({Key? key}) : super(key: key, text: '');
}
''', errorFilter: (error) => error.errorCode is LintCode);
  }
}
