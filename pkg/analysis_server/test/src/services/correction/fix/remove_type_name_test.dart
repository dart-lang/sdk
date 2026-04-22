// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveTypeNameBulkTest);
    defineReflectiveTests(RemoveTypeNameTest);
  });
}

@reflectiveTest
class RemoveTypeNameBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_type_name_in_constructor;

  Future<void> test_in_file() async {
    await resolveTestCode(r'''
class C {
  C.name();
  C();
  factory C.f() => C();
}
''');
    await assertHasFix(r'''
class C {
  new name();
  new ();
  factory f() => C();
}
''');
  }
}

@reflectiveTest
class RemoveTypeNameTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeTypeName;

  @override
  String get lintCode => LintNames.unnecessary_type_name_in_constructor;

  Future<void> test_factory_named() async {
    await resolveTestCode('''
class C {
  factory C.name() => C._();

  new _();
}
''');
    await assertHasFix('''
class C {
  factory name() => C._();

  new _();
}
''');
  }

  Future<void> test_factory_unnamed() async {
    await resolveTestCode('''
class C {
  factory C() => C._();

  new _();
}
''');
    await assertHasFix('''
class C {
  factory () => C._();

  new _();
}
''');
  }

  Future<void> test_generative_explicitNew() async {
    await resolveTestCode('''
class C {
  C.new();
}
''');
    await assertHasFix('''
class C {
  new ();
}
''');
  }

  Future<void> test_generative_named() async {
    await resolveTestCode('''
class C {
  C.name();
}
''');
    await assertHasFix('''
class C {
  new name();
}
''');
  }

  Future<void> test_generative_unnamed() async {
    await resolveTestCode('''
class C {
  C();
}
''');
    await assertHasFix('''
class C {
  new ();
}
''');
  }
}
