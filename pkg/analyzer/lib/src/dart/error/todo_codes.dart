// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

// It is hard to visually separate each code's _doc comment_ from its published
// _documentation comment_ when each is written as an end-of-line comment.
// ignore_for_file: slash_for_doc_comments

/**
 * The error code indicating a marker in code for work that needs to be finished
 * or revisited.
 */
class TodoCode extends ErrorCode {
  /**
   * The single enum of TodoCode.
   */
  static const TodoCode TODO = TodoCode('TODO');

  /**
   * This matches the two common Dart task styles
   *
   * * TODO:
   * * TODO(username):
   *
   * As well as
   * * TODO
   *
   * But not
   * * todo
   * * TODOS
   */
  static RegExp TODO_REGEX =
      RegExp("([\\s/\\*])((TODO[^\\w\\d][^\\r\\n]*)|(TODO:?\$))");

  /**
   * Initialize a newly created error code to have the given [name].
   */
  const TodoCode(String name)
      : super(
          message: "{0}",
          name: name,
          uniqueName: 'TodoCode.$name',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.TODO;
}
