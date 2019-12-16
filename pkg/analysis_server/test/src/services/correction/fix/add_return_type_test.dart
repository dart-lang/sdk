// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddReturnTypeLintTest);
  });
}

@reflectiveTest
class AddReturnTypeLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_RETURN_TYPE;

  @override
  String get lintCode => LintNames.always_declare_return_types;

  test_localFunction_block() async {
    await resolveTestUnit('''
class A {
  void m() {
    /*LINT*/f() {
      return '';
    }
  }
}
''');
    await assertHasFix('''
class A {
  void m() {
    /*LINT*/String f() {
      return '';
    }
  }
}
''');
  }

  test_localFunction_expression() async {
    await resolveTestUnit('''
class A {
  void m() {
    /*LINT*/f() => '';
  }
}
''');
    await assertHasFix('''
class A {
  void m() {
    /*LINT*/String f() => '';
  }
}
''');
  }

  test_method_block_noReturn() async {
    await resolveTestUnit('''
class A {
  /*LINT*/m() {
  }
}
''');
    await assertNoFix();
  }

  test_method_block_returnDynamic() async {
    await resolveTestUnit('''
class A {
  /*LINT*/m(p) {
    return p;
  }
}
''');
    await assertNoFix();
  }

  test_method_block_returnNoValue() async {
    await resolveTestUnit('''
class A {
  /*LINT*/m() {
    return;
  }
}
''');
    await assertHasFix('''
class A {
  /*LINT*/void m() {
    return;
  }
}
''');
  }

  test_method_block_singleReturn() async {
    await resolveTestUnit('''
class A {
  /*LINT*/m() {
    return '';
  }
}
''');
    await assertHasFix('''
class A {
  /*LINT*/String m() {
    return '';
  }
}
''');
  }

  test_method_expression() async {
    await resolveTestUnit('''
class A {
  /*LINT*/m() => '';
}
''');
    await assertHasFix('''
class A {
  /*LINT*/String m() => '';
}
''');
  }

  test_topLevelFunction_block() async {
    await resolveTestUnit('''
/*LINT*/f() {
  return '';
}
''');
    await assertHasFix('''
/*LINT*/String f() {
  return '';
}
''');
  }

  test_topLevelFunction_expression() async {
    await resolveTestUnit('''
/*LINT*/f() => '';
''');
    await assertHasFix('''
/*LINT*/String f() => '';
''');
  }
}
