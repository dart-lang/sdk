// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(JoinElseWithIf);
    defineReflectiveTests(JoinIfWithElseTest);
  });
}

@reflectiveTest
class JoinElseWithIf extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.joinElseWithIf;

  Future<void> test_block_if() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } el^se {
    if (1 case double value) {
      print(value);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (1 case double value) {
    print(value);
  }
}
''');
  }

  Future<void> test_block_notIf() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
    print(0);
  } el^se {
    print(1);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_blockComment_after_else_keyword() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } el^se /* comment here */ {
    if (2 == 2)
      print(0);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_comment_before_else_keyword() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } /* comment here */ e^lse {
    if (2 == 2)
      print(0);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } /* comment here */ else if (2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_enclosing_if_statement() async {
    // Should make no difference because the enclosing `if` thenStatement is
    // not considered for anything in this assist.
    await resolveTestCode('''
void f() {
  if (1 == 1) print(0);
  el^se {
    if (2 == 2) {
      print(1);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) print(0);
  else if (2 == 2) {
    print(1);
  }
}
''');
  }

  Future<void> test_endOfLineComment_after_else_keyword() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } els^e // comment here
  {
    if (2 == 2)
      print(0);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_noAssistOnOuterIf() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1) {
  } else {
    if (1 case double value) {
      print(value);
    }
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_notBlock() async {
    // No assist because this is a bad formatted `if else` statement.
    await resolveTestCode('''
void f() {
  if (1 == 1) print(0);
  el^se
    if (2 == 2) {
      print(1);
    }
}
''');
    await assertNoAssist();
  }

  Future<void> test_statementAfterInner() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } e^lse {
    if (2 == 2) {
      print(2);
    }
    print(1);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_statementBeforeInner() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } ^else {
    print(1);
    if (2 == 2) {
      print(2);
    }
  }
}
''');
    await assertNoAssist();
  }
}

@reflectiveTest
class JoinIfWithElseTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.joinIfWithElse;

  Future<void> test_block_statement() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2)
      print(0);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_blockComments_after_inner_if_block() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    ^if (2 == 2) /* comment here */ {
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    /* comment here */
    print(0);
  }
}
''');
  }

  Future<void> test_blockMulti() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(1);
      print(2);
      print(3);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(1);
    print(2);
    print(3);
  }
}
''');
  }

  Future<void> test_case() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (1 case double value) {
      print(value);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (1 case double value) {
    print(value);
  }
}
''');
  }

  Future<void> test_comments_after_inner_if_keyword() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f /* comment here */ (2 == 2)
      print(0);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    /* comment here */
    print(0);
  }
}
''');
  }

  Future<void> test_comments_before_inner_if() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    // comment here
    /* comment here */
    i^f (2 == 2)
      print(0);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    // comment here
    /* comment here */
    print(0);
  }
}
''');
  }

  Future<void> test_enclosing_if_statement() async {
    // Should make no difference because the enclosing `if` thenStatement is
    // not considered for anything in this assist.
    await resolveTestCode('''
void f() {
  if (1 == 1) print(0);
  else {
    ^if (2 == 2) {
      print(1);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) print(0);
  else if (2 == 2) {
    print(1);
  }
}
''');
  }

  Future<void> test_endOfLineComments_after_inner_else_block() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(0);
    } else {
      print(1);
    }
    // comment here
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else {
    print(1);
    // comment here
  }
}
''');
  }

  Future<void> test_endOfLineComments_after_inner_else_if_condition() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    ^if (2 == 2)
      print(0);
    else if (3 == 3) // comment here
      print(1);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else if (3 == 3) {
    // comment here
    print(1);
  }
}
''');
  }

  Future<void> test_endOfLineComments_after_inner_else_keyword() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2)
      print(0);
    else // comment here
      print(1);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else {
    // comment here
    print(1);
  }
}
''');
  }

  Future<void> test_endOfLineComments_after_inner_else_statement() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(0);
    } else print(1);
    // comment here
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else {
    print(1);
    // comment here
  }
}
''');
  }

  Future<void> test_endOfLineComments_after_inner_elseIf_block() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    ^if (2 == 2) {
      print(0);
    } else if (3 == 3) {
      print(1);
    }
    // comment here
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else if (3 == 3) {
    print(1);
    // comment here
  }
}
''');
  }

  Future<void>
  test_endOfLineComments_after_inner_elseIf_else_statement() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(0);
    } else if (3 == 3) print(1);
    // comment here
    else print(2);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else if (3 == 3) {
    print(1);
    // comment here
  } else {
    print(2);
  }
}
''');
  }

  Future<void> test_endOfLineComments_after_inner_elseIf_statement() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    if^ (2 == 2) {
      print(0);
    } else if (3 == 3) print(1);
    // comment here
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else if (3 == 3) {
    print(1);
    // comment here
  }
}
''');
  }

  Future<void> test_endOfLineComments_after_inner_if_block() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(0);
    }
    // comment here
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
    // comment here
  }
}
''');
  }

  Future<void> test_endOfLineComments_after_inner_if_condition() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    ^if (2 == 2) // comment here
      print(0);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    // comment here
    print(0);
  }
}
''');
  }

  Future<void> test_endOfLineComments_if_block_noNewLines() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    // comment here
    i^f (2 == 2) {print(0);}
    // comment here 2
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    // comment here
    print(0);
    // comment here 2
  }
}
''');
  }

  Future<void> test_endOfLineComments_inside_inner_else_block() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    ^if (2 == 2) {
      print(0);
    } else {
      // comment here
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else {
    // comment here
  }
}
''');
  }

  Future<void> test_endOfLineComments_inside_inner_if_block() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      // comment here
      print(0);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    // comment here
    print(0);
  }
}
''');
  }

  Future<void> test_noAssistOnInnerElses() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    if (1 case double value) {
      /*0*/print(value);
    } else /*1*/if (2 == 2) {
    } /*2*/else /*3*/print(0);
  }
}
''');
    await assertNoAssist();
    await assertNoAssist(1);
    await assertNoAssist(2);
    await assertNoAssist(3);
  }

  Future<void> test_notBlock() async {
    // No assist because this is a bad formatted `if else` statement.
    await resolveTestCode('''
void f() {
  if (1 == 1) print(0);
  else
    i^f (2 == 2) {
      print(1);
    }
}
''');
    await assertNoAssist();
  }

  Future<void> test_outerNotIf() async {
    await resolveTestCode('''
void f() {
  i^f (1 == 1) {
    print(0);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_statementAfterInner() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(2);
    }
    print(1);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_statementBeforeInner() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    print(1);
    i^f (2 == 2) {
      print(2);
    }
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_targetWithElseBlock() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(0);
    } else {
      print(1);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else {
    print(1);
  }
}
''');
  }

  Future<void> test_targetWithElseIfBlock() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(0);
    } else if (3 == 3) {
      print(1);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else if (3 == 3) {
    print(1);
  }
}
''');
  }

  Future<void> test_targetWithElseIfElseBlock() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(0);
    } else if (3 == 3) {
      print(1);
    } else {
      print(2);
    }
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else if (3 == 3) {
    print(1);
  } else {
    print(2);
  }
}
''');
  }

  Future<void> test_targetWithElseStatement() async {
    await resolveTestCode('''
void f() {
  if (1 == 1) {
  } else {
    i^f (2 == 2) {
      print(0);
    } else print(1);
  }
}
''');
    await assertHasAssist('''
void f() {
  if (1 == 1) {
  } else if (2 == 2) {
    print(0);
  } else {
    print(1);
  }
}
''');
  }
}
