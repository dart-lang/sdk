// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveOnClauseMultiTest);
    defineReflectiveTests(RemoveOnClauseTest);
  });
}

@reflectiveTest
class RemoveOnClauseMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_ON_CLAUSE_MULTI;

  Future<void> test_singleFile() async {
    newFile('$testPackageLibPath/a.dart', '''
part 'test.dart';

extension E on int { }
''');

    await resolveTestCode('''
part of 'a.dart';

augment extension E on int { }

augment extension E on num { }
''');
    await assertHasFixAllFix(
        ParserErrorCode.EXTENSION_AUGMENTATION_HAS_ON_CLAUSE, '''
part of 'a.dart';

augment extension E { }

augment extension E { }
''');
  }
}

@reflectiveTest
class RemoveOnClauseTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_ON_CLAUSE;

  Future<void> test_it() async {
    newFile('$testPackageLibPath/a.dart', '''
part 'test.dart';

extension E on int { }
''');

    await resolveTestCode('''
part of 'a.dart';

augment extension E on int { }
''');
    await assertHasFix('''
part of 'a.dart';

augment extension E { }
''');
  }
}
