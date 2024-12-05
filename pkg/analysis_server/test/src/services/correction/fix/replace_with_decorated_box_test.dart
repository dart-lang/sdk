// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithDecoratedBoxTest);
    defineReflectiveTests(ReplaceWithDecoratedBoxInFileTest);
    defineReflectiveTests(ReplaceWithDecoratedBoxBulkTest);
  });
}

@reflectiveTest
class ReplaceWithDecoratedBoxBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_decorated_box;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_singleFile() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void f(Color color) {
  Container(
    decoration: BoxDecoration(),
    child: Container(
      decoration: const BoxDecoration(),
      child: const Text(''),
    ),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

void f(Color color) {
  const DecoratedBox(
    decoration: BoxDecoration(),
    child: DecoratedBox(
      decoration: BoxDecoration(),
      child: Text(''),
    ),
  );
}
''');
  }
}

@reflectiveTest
class ReplaceWithDecoratedBoxInFileTest extends FixInFileProcessorTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
    createAnalysisOptionsFile(lints: [LintNames.use_decorated_box]);
  }

  Future<void> test_functionExpression() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

void f() {
  Container(
    decoration: const BoxDecoration(),
    child: InkWell(
      onHover: (b) {
        Container(
          decoration: const BoxDecoration(),
          child: const Text(''),
        );
      },
      child: Container(
        decoration: const BoxDecoration(),
        child: const Text(''),
      ),
    ),
  );
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
import 'package:flutter/material.dart';

void f() {
  DecoratedBox(
    decoration: const BoxDecoration(),
    child: InkWell(
      onHover: (b) {
        Container(
          decoration: const BoxDecoration(),
          child: const Text(''),
        );
      },
      child: Container(
        decoration: const BoxDecoration(),
        child: const Text(''),
      ),
    ),
  );
}
''');
  }

  Future<void> test_notDirectParent() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

void f() {
  Container(
    decoration: const BoxDecoration(),
    child: Container(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(),
        child: Text(''),
      ),
    ),
  );
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
import 'package:flutter/material.dart';

void f() {
  DecoratedBox(
    decoration: const BoxDecoration(),
    child: Container(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(),
        child: Text(''),
      ),
    ),
  );
}
''');
  }

  Future<void> test_parentConst_childConst() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

void f() {
  Container(
    decoration: const BoxDecoration(),
    child: Container(
      decoration: const BoxDecoration(),
      child: const Text(''),
    ),
  );
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
import 'package:flutter/material.dart';

void f() {
  const DecoratedBox(
    decoration: BoxDecoration(),
    child: DecoratedBox(
      decoration: BoxDecoration(),
      child: Text(''),
    ),
  );
}
''');
  }

  Future<void> test_parentConst_childNotConst() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

void f(int i) {
  Container(
    decoration: const BoxDecoration(),
    child: Container(
      decoration: const BoxDecoration(),
      child: Text('$i'),
    ),
  );
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
import 'package:flutter/material.dart';

void f(int i) {
  DecoratedBox(
    decoration: const BoxDecoration(),
    child: DecoratedBox(
      decoration: const BoxDecoration(),
      child: Text('$i'),
    ),
  );
}
''');
  }

  Future<void> test_parentNotConst_childConst() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

void f(Color color) {
  Container(
    decoration: BoxDecoration(color: color),
    child: Container(
      decoration: const BoxDecoration(),
      child: Text(''),
    ),
  );
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
import 'package:flutter/material.dart';

void f(Color color) {
  DecoratedBox(
    decoration: BoxDecoration(color: color),
    child: const DecoratedBox(
      decoration: BoxDecoration(),
      child: Text(''),
    ),
  );
}
''');
  }
}

@reflectiveTest
class ReplaceWithDecoratedBoxTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_DECORATED_BOX;

  @override
  String get lintCode => LintNames.use_decorated_box;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_canBeConst() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void f() {
  Container(
    decoration: BoxDecoration(),
    child: Text(''),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

void f() {
  const DecoratedBox(
    decoration: BoxDecoration(),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_const() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void f() {
  Container(
    decoration: const BoxDecoration(),
    child: const Text(''),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

void f() {
  const DecoratedBox(
    decoration: BoxDecoration(),
    child: Text(''),
  );
}
''');
  }

  Future<void> test_hierarchy() async {
    useLineEndingsForPlatform = false;

    await resolveTestCode('''
import 'package:flutter/material.dart';

void f() {
  Container(
    decoration: BoxDecoration(),
    child: Container(
      decoration: const BoxDecoration(),
      child: Container(
        decoration: BoxDecoration(),
        child: Text(''),
      ),
    ),
  );
}
''');

    await assertHasFix(
      '''
import 'package:flutter/material.dart';

void f() {
  DecoratedBox(
    decoration: BoxDecoration(),
    child: Container(
      decoration: const BoxDecoration(),
      child: Container(
        decoration: BoxDecoration(),
        child: Text(''),
      ),
    ),
  );
}
''',
      allowFixAllFixes: true,
      errorFilter: (error) => error.offset == 54,
    );

    await assertHasFix(
      '''
import 'package:flutter/material.dart';

void f() {
  Container(
    decoration: BoxDecoration(),
    child: DecoratedBox(
      decoration: const BoxDecoration(),
      child: Container(
        decoration: BoxDecoration(),
        child: Text(''),
      ),
    ),
  );
}
''',
      allowFixAllFixes: true,
      errorFilter: (error) => error.offset == 109,
    );

    await assertHasFix(
      '''
import 'package:flutter/material.dart';

void f() {
  Container(
    decoration: BoxDecoration(),
    child: Container(
      decoration: const BoxDecoration(),
      child: const DecoratedBox(
        decoration: BoxDecoration(),
        child: Text(''),
      ),
    ),
  );
}
''',
      allowFixAllFixes: true,
      errorFilter: (error) => error.offset == 174,
    );
  }

  Future<void> test_nonConst() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

void f() {
  Container(
    key: UniqueKey(),
    decoration: const BoxDecoration(),
    child: const Text(''),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';

void f() {
  DecoratedBox(
    key: UniqueKey(),
    decoration: const BoxDecoration(),
    child: const Text(''),
  );
}
''');
  }
}
