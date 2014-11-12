// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml.utils;

import 'package:source_span/source_span.dart';

/// A pair of values.
class Pair<E, F> {
  final E first;
  final F last;

  Pair(this.first, this.last);

  String toString() => '($first, $last)';
}

/// Print a warning.
///
/// If [span] is passed, associates the warning with that span.
void warn(String message, [SourceSpan span]) =>
    yamlWarningCallback(message, span);

/// A callback for emitting a warning.
///
/// [message] is the text of the warning. If [span] is passed, it's the portion
/// of the document that the warning is associated with and should be included
/// in the printed warning.
typedef YamlWarningCallback(String message, [SourceSpan span]);

/// A callback for emitting a warning.
///
/// In a very few cases, the YAML spec indicates that an implementation should
/// emit a warning. To do so, it calls this callback. The default implementation
/// prints a message using [print].
YamlWarningCallback yamlWarningCallback = (message, [span]) {
  // TODO(nweiz): Print to stderr with color when issue 6943 is fixed and
  // dart:io is available.
  if (span != null) message = span.message(message);
  print(message);
};


