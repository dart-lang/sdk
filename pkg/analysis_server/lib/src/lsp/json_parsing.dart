// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

final nullLspJsonReporter = _NullLspJsonReporter();

/// Tracks a path through a JSON object during validation to allow reporting
/// validation errors with user-friendly paths to the invalid fields.
class LspJsonReporter {
  /// A list of errors collected so far.
  final List<String> errors = [];

  /// The path from the root object (usually `params`) to the current object
  /// being validated.
  final ListQueue<String> path = ListQueue<String>();

  LspJsonReporter([String initialField]) {
    if (initialField != null) {
      path.add(initialField);
    }
  }

  /// Pops the last field off the stack to become the current gield.
  void pop() => path.removeLast();

  /// Pushes the current field onto a stack to allow reporting errors in child
  /// properties.
  void push(String field) => path.add(field);

  /// Reports an error message for the field represented by [field] at [path].
  void reportError(String message) {
    errors.add('${path.join(".")} $message');
  }
}

class _NullLspJsonReporter implements LspJsonReporter {
  @override
  final errors = const <String>[];

  @override
  final path = ListQueue<String>();

  @override
  void pop() {}

  @override
  void push(String field) {}

  @override
  void reportError(String message) {}
}
