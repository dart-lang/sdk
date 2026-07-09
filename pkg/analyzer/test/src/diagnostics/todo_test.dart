// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TodoTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TodoTest extends PubPackageResolutionTest {
  test_eof() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {}
// TODO: Implement something else
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.todo] TODO: Implement something else
''');
  }

  test_fixme() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  // FIXME: Implement
//   ^^^^^^^^^^^^^^^^
// [diag.fixme] FIXME: Implement
}
''');
  }

  test_hack() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  // HACK: This is a hack
//   ^^^^^^^^^^^^^^^^^^^^
// [diag.hack] HACK: This is a hack
}
''');
  }

  test_todo_multiLineComment() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  /* TODO: Implement */
//   ^^^^^^^^^^^^^^^
// [diag.todo] TODO: Implement
  /* TODO: Implement*/
//   ^^^^^^^^^^^^^^^
// [diag.todo] TODO: Implement
}
''');
  }

  test_todo_multiLineComment2() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
/*
TODO: Implement1
// [diag.todo][column 1][length 16] TODO: Implement1
TODO: Implement2
// [diag.todo][column 1][length 16] TODO: Implement2
*/
}
''');
  }

  test_todo_multiLineCommentWrapped() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  /* TODO(a): Implement something
// [diag.todo][column 6][length 64] TODO(a): Implement something that is too long for one line
   *  that is too long for one line
   * This line is not part of the todo
   */
  /* TODO: Implement something
// [diag.todo][column 6][length 61] TODO: Implement something that is too long for one line
   *  that is too long for one line
   * This line is not part of the todo
   */
  /* TODO(a): Implement something
// [diag.todo][column 6][length 64] TODO(a): Implement something that is too long for one line
   *  that is too long for one line
   *
   *  This line is not part of the todo
   */
  /* TODO: Implement something
// [diag.todo][column 6][length 61] TODO: Implement something that is too long for one line
   *  that is too long for one line
   *
   *  This line is not part of the todo
  */
}
''');
  }

  test_todo_multiLineCommentWrapped_windows_line_endings() async {
    await resolveTestCodeWithDiagnostics(
      r'''
main() {
  /* TODO(a): Implement something
// [diag.todo][column 6][length 65] TODO(a): Implement something that is too long for one line
   *  that is too long for one line
   * This line is not part of the todo
   */
  /* TODO: Implement something
// [diag.todo][column 6][length 62] TODO: Implement something that is too long for one line
   *  that is too long for one line
   * This line is not part of the todo
   */
  /* TODO(a): Implement something
// [diag.todo][column 6][length 65] TODO(a): Implement something that is too long for one line
   *  that is too long for one line
   *
   *  This line is not part of the todo
   */
  /* TODO: Implement something
// [diag.todo][column 6][length 62] TODO: Implement something that is too long for one line
   *  that is too long for one line
   *
   *  This line is not part of the todo
   */
}
'''
          .split("\n")
          .join("\r\n"),
    );
  }

  test_todo_singleLineComment() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  // TODO: Implement
//   ^^^^^^^^^^^^^^^
// [diag.todo] TODO: Implement
}
''');
  }

  test_todo_singleLineCommentDoubleCommented() async {
    // Continuations are ignored for code that looks like commented comments
    // although the original TODOs are still picked up.
    await resolveTestCodeWithDiagnostics(r'''
main() {
//      // TODO: Implement something
// [diag.todo][column 12][length 67] TODO: Implement something that is too long for one line
//      //  that is too long for one line
//      main() {

//      // TODO: Implement something
//         ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.todo] TODO: Implement something
//      // this is not a todo
//      main() {

//      // TODO: Implement something
//         ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.todo] TODO: Implement something
//      main() {
}
''');
  }

  test_todo_singleLineCommentFollowedByDartdoc() async {
    await resolveTestCodeWithDiagnostics(r'''
// TODO: Implement something
// ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.todo] TODO: Implement something
/// This is the function documentation
void f() {}
''');
  }

  test_todo_singleLineCommentLessIndentedContinuation() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  // TODO: Implement something
// [diag.todo][column 6][length 61] TODO: Implement something that is too long for one line
  //  that is too long for one line
//    this is not part of the todo
}
''');
  }

  test_todo_singleLineCommentMoreIndentedContinuation() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  // TODO: Implement something
// [diag.todo][column 6][length 61] TODO: Implement something that is too long for one line
  //  that is too long for one line
  //      this is not part of the todo
}
''');
  }

  test_todo_singleLineCommentNested() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  // TODO: Implement something
// [diag.todo][column 6][length 61] TODO: Implement something that is too long for one line
  //  that is too long for one line
  //  TODO: This is a separate todo that is accidentally indented
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.todo] TODO: This is a separate todo that is accidentally indented
}
''');
  }

  test_todo_singleLineCommentWrapped() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  // TODO: Implement something
// [diag.todo][column 6][length 61] TODO: Implement something that is too long for one line
  //  that is too long for one line
  // this is not part of the todo

  // TODO: Implement something
// [diag.todo][column 6][length 61] TODO: Implement something that is too long for one line
  //  that is too long for one line

  //  this is not part of the todo

  // TODO: Implement something
// [diag.todo][column 6][length 61] TODO: Implement something that is too long for one line
  //  that is too long for one line
  //
  //  this is not part of the todo
}
''');
  }

  test_undone() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  // UNDONE: This was undone
//   ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.undone] UNDONE: This was undone
}
''');
  }
}
