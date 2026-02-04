// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TodoTest);
  });
}

@reflectiveTest
class TodoTest extends PubPackageResolutionTest {
  test_eof() async {
    await assertErrorsInCode(
      r'''
main() {}
// TODO: Implement something else
''',
      [error(diag.todo, 13, 30, text: 'TODO: Implement something else')],
    );
  }

  test_fixme() async {
    await assertErrorsInCode(
      r'''
main() {
  // FIXME: Implement
}
''',
      [error(diag.fixme, 14, 16, text: 'FIXME: Implement')],
    );
  }

  test_hack() async {
    await assertErrorsInCode(
      r'''
main() {
  // HACK: This is a hack
}
''',
      [error(diag.hack, 14, 20, text: 'HACK: This is a hack')],
    );
  }

  test_todo_multiLineComment() async {
    await assertErrorsInCode(
      r'''
main() {
  /* TODO: Implement */
  /* TODO: Implement*/
}
''',
      [
        error(diag.todo, 14, 15, text: 'TODO: Implement'),
        error(diag.todo, 38, 15, text: 'TODO: Implement'),
      ],
    );
  }

  test_todo_multiLineCommentWrapped() async {
    await assertErrorsInCode(
      r'''
main() {
  /* TODO(a): Implement something
   *  that is too long for one line
   * This line is not part of the todo
   */
  /* TODO: Implement something
   *  that is too long for one line
   * This line is not part of the todo
   */
  /* TODO(a): Implement something
   *  that is too long for one line
   *
   *  This line is not part of the todo
   */
  /* TODO: Implement something
   *  that is too long for one line
   *
   *  This line is not part of the todo
   */
}
''',
      [
        error(
          diag.todo,
          14,
          64,
          text: 'TODO(a): Implement something that is too long for one line',
        ),
        error(
          diag.todo,
          129,
          61,
          text: 'TODO: Implement something that is too long for one line',
        ),
        error(
          diag.todo,
          241,
          64,
          text: 'TODO(a): Implement something that is too long for one line',
        ),
        error(
          diag.todo,
          362,
          61,
          text: 'TODO: Implement something that is too long for one line',
        ),
      ],
    );
  }

  test_todo_singleLineComment() async {
    await assertErrorsInCode(
      r'''
main() {
  // TODO: Implement
}
''',
      [error(diag.todo, 14, 15, text: 'TODO: Implement')],
    );
  }

  test_todo_singleLineCommentDoubleCommented() async {
    // Continuations are ignored for code that looks like commented comments
    // although the original TODOs are still picked up.
    await assertErrorsInCode(
      r'''
main() {
//      // TODO: Implement something
//      //  that is too long for one line
//      main() {

//      // TODO: Implement something
//      // this is not a todo
//      main() {

//      // TODO: Implement something
//      main() {
}
''',
      [
        error(
          diag.todo,
          20,
          67,
          text: 'TODO: Implement something that is too long for one line',
        ),
        error(diag.todo, 117, 25, text: 'TODO: Implement something'),
        error(diag.todo, 202, 25, text: 'TODO: Implement something'),
      ],
    );
  }

  test_todo_singleLineCommentFollowedByDartdoc() async {
    await assertErrorsInCode(
      r'''
// TODO: Implement something
/// This is the function documentation
void f() {}
''',
      [error(diag.todo, 3, 25, text: 'TODO: Implement something')],
    );
  }

  test_todo_singleLineCommentLessIndentedContinuation() async {
    await assertErrorsInCode(
      r'''
main() {
  // TODO: Implement something
  //  that is too long for one line
//    this is not part of the todo
}
''',
      [
        error(
          diag.todo,
          14,
          61,
          text: 'TODO: Implement something that is too long for one line',
        ),
      ],
    );
  }

  test_todo_singleLineCommentMoreIndentedContinuation() async {
    await assertErrorsInCode(
      r'''
main() {
  // TODO: Implement something
  //  that is too long for one line
  //      this is not part of the todo
}
''',
      [
        error(
          diag.todo,
          14,
          61,
          text: 'TODO: Implement something that is too long for one line',
        ),
      ],
    );
  }

  test_todo_singleLineCommentNested() async {
    await assertErrorsInCode(
      r'''
main() {
  // TODO: Implement something
  //  that is too long for one line
  //  TODO: This is a separate todo that is accidentally indented
}
''',
      [
        error(
          diag.todo,
          14,
          61,
          text: 'TODO: Implement something that is too long for one line',
        ),
        error(
          diag.todo,
          82,
          59,
          text: 'TODO: This is a separate todo that is accidentally indented',
        ),
      ],
    );
  }

  test_todo_singleLineCommentWrapped() async {
    await assertErrorsInCode(
      r'''
main() {
  // TODO: Implement something
  //  that is too long for one line
  // this is not part of the todo

  // TODO: Implement something
  //  that is too long for one line

  //  this is not part of the todo

  // TODO: Implement something
  //  that is too long for one line
  //
  //  this is not part of the todo
}
''',
      [
        error(
          diag.todo,
          14,
          61,
          text: 'TODO: Implement something that is too long for one line',
        ),
        error(
          diag.todo,
          116,
          61,
          text: 'TODO: Implement something that is too long for one line',
        ),
        error(
          diag.todo,
          220,
          61,
          text: 'TODO: Implement something that is too long for one line',
        ),
      ],
    );
  }

  test_undone() async {
    await assertErrorsInCode(
      r'''
main() {
  // UNDONE: This was undone
}
''',
      [error(diag.undone, 14, 23, text: 'UNDONE: This was undone')],
    );
  }
}
