// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';

part 'package:analyzer/src/dart/error/todo_codes.g.dart';

/// Static helper methods and properties for working with [TodoCode]s.
class Todo {
  static const _codes = {
    'TODO': TodoCode.todo,
    'FIXME': TodoCode.fixme,
    'HACK': TodoCode.hack,
    'UNDONE': TodoCode.undone,
  };

  /// This matches the two common Dart task styles
  ///
  /// * `TODO`:
  /// * `TODO`(username):
  ///
  /// As well as
  /// * `TODO`
  ///
  /// But not
  // * `todo`
  /// * `TODOS`
  ///
  /// It also supports wrapped TODOs where the next line is indented by a space:
  ///
  ///   /**
  ///    * `TODO`(username): This line is
  ///    *  wrapped onto the next line
  ///    */
  ///
  /// The matched kind of the `TODO` (`TODO`, `FIXME`, etc.) is returned in named
  /// captures of "kind1", "kind2" (since it is not possible to reuse a name
  /// across different parts of the regex).
  static RegExp TODO_REGEX = RegExp(
    '([\\s/\\*])(((?<kind1>$_TODO_KIND_PATTERN)[^\\w\\d][^\\r\\n]*(?:\\n\\s*\\*  [^\\r\\n]*)*)'
    '|((?<kind2>$_TODO_KIND_PATTERN):?\$))',
  );

  static final _TODO_KIND_PATTERN = _codes.keys.join('|');

  Todo._() {
    throw UnimplementedError('Do not construct');
  }

  /// Returns the TodoCode for [kind], falling back to [TodoCode.todo].
  static TodoCode forKind(String kind) => _codes[kind] ?? TodoCode.todo;
}
