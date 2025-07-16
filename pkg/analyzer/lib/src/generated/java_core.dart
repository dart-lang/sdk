// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Inserts the given [arguments] into [pattern].
///
///     format('Hello, {0}!', ['John']) = 'Hello, John!'
///     format('{0} are you {1}ing?', ['How', 'do']) = 'How are you doing?'
///     format('{0} are you {1}ing?', ['What', 'read']) =
///         'What are you reading?'
String formatList(String pattern, List<Object?>? arguments) {
  if (arguments == null || arguments.isEmpty) {
    assert(
      !pattern.contains(RegExp(r'\{(\d+)\}')),
      'Message requires arguments, but none were provided.',
    );
    return pattern;
  }
  return pattern.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
    String indexStr = match.group(1)!;
    int index = int.parse(indexStr);
    return arguments[index].toString();
  });
}
