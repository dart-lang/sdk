// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithLiteralTest);
  });
}

@reflectiveTest
class ReplaceWithLiteralTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_LITERAL;

  @override
  String get lintCode => LintNames.prefer_collection_literals;

  test_linkedHashMap_withCommentsInGeneric() async {
    await resolveTestUnit('''
import 'dart:collection';

final a = /*LINT*/new LinkedHashMap<int,/*comment*/int>();
''');
    await assertHasFix('''
import 'dart:collection';

final a = /*LINT*/<int,/*comment*/int>{};
''');
  }

  test_linkedHashMap_withDynamicGenerics() async {
    await resolveTestUnit('''
import 'dart:collection';

final a = /*LINT*/new LinkedHashMap<dynamic,dynamic>();
''');
    await assertHasFix('''
import 'dart:collection';

final a = /*LINT*/<dynamic,dynamic>{};
''');
  }

  test_linkedHashMap_withGeneric() async {
    await resolveTestUnit('''
import 'dart:collection';

final a = /*LINT*/new LinkedHashMap<int,int>();
''');
    await assertHasFix('''
import 'dart:collection';

final a = /*LINT*/<int,int>{};
''');
  }

  test_linkedHashMap_withoutGeneric() async {
    await resolveTestUnit('''
import 'dart:collection';

final a = /*LINT*/new LinkedHashMap();
''');
    await assertHasFix('''
import 'dart:collection';

final a = /*LINT*/{};
''');
  }

  test_list_withGeneric() async {
    await resolveTestUnit('''
final a = /*LINT*/new List<int>();
''');
    await assertHasFix('''
final a = /*LINT*/<int>[];
''');
  }

  test_list_withoutGeneric() async {
    await resolveTestUnit('''
final a = /*LINT*/new List();
''');
    await assertHasFix('''
final a = /*LINT*/[];
''');
  }

  test_map_withGeneric() async {
    await resolveTestUnit('''
final a = /*LINT*/new Map<int,int>();
''');
    await assertHasFix('''
final a = /*LINT*/<int,int>{};
''');
  }

  test_map_withoutGeneric() async {
    await resolveTestUnit('''
final a = /*LINT*/new Map();
''');
    await assertHasFix('''
final a = /*LINT*/{};
''');
  }
}
