// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSingleQuotedStringTest);
  });
}

@reflectiveTest
class ConvertToSingleQuotedStringTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_SINGLE_QUOTED_STRING;

  Future<void> test_one_embeddedTarget() async {
    await resolveTestCode('''
main() {
  print("a'b'c");
}
''');
    await assertNoAssistAt('"a');
  }

  Future<void> test_one_enclosingTarget() async {
    await resolveTestCode('''
main() {
  print('abc');
}
''');
    await assertNoAssistAt("'ab");
  }

  Future<void> test_one_interpolation() async {
    await resolveTestCode(r'''
main() {
  var b = 'b';
  var c = 'c';
  print("a $b-${c} d");
}
''');
    await assertHasAssistAt(r'"a $b', r'''
main() {
  var b = 'b';
  var c = 'c';
  print('a $b-${c} d');
}
''');
  }

  Future<void> test_one_interpolation_unterminated() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode(r'''
void f(int a) {
  "$a
}
''');
    await assertNoAssistAt('"');
  }

  Future<void> test_one_raw() async {
    await resolveTestCode('''
main() {
  print(r"abc");
}
''');
    await assertHasAssistAt('"ab', '''
main() {
  print(r'abc');
}
''');
  }

  Future<void> test_one_simple() async {
    await resolveTestCode('''
main() {
  print("abc");
}
''');
    await assertHasAssistAt('"ab', '''
main() {
  print('abc');
}
''');
  }

  Future<void> test_one_simple_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_single_quotes]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
main() {
  print("abc");
}
''');
    await assertNoAssist();
  }

  Future<void> test_one_simple_unterminated_empty() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  "
}
''');
    await assertNoAssistAt('"');
  }

  Future<void> test_three_embeddedTarget() async {
    await resolveTestCode('''
main() {
  print("""a''\'bc""");
}
''');
    await assertNoAssistAt('"a');
  }

  Future<void> test_three_enclosingTarget() async {
    await resolveTestCode("""
main() {
  print('''abc''');
}
""");
    await assertNoAssistAt("'ab");
  }

  Future<void> test_three_interpolation() async {
    await resolveTestCode(r'''
main() {
  var b = 'b';
  var c = 'c';
  print("""a $b-${c} d""");
}
''');
    await assertHasAssistAt(r'"a $b', r"""
main() {
  var b = 'b';
  var c = 'c';
  print('''a $b-${c} d''');
}
""");
  }

  Future<void> test_three_raw() async {
    await resolveTestCode('''
main() {
  print(r"""abc""");
}
''');
    await assertHasAssistAt('"ab', """
main() {
  print(r'''abc''');
}
""");
  }

  Future<void> test_three_simple() async {
    await resolveTestCode('''
main() {
  print("""abc""");
}
''');
    await assertHasAssistAt('"ab', """
main() {
  print('''abc''');
}
""");
  }
}
