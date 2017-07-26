// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'log.dart';

final _unittestPattern = "package:unittest";
final _checkedPattern = new RegExp(r"\bchecked\b");
final _abstractErrorPattern =
    new RegExp(r"\bAbstractClassInstantiationError\b");
final _typeErrorPattern = new RegExp(r"\bTypeError\b");

void validateFile(String path, String source, [List<String> todos]) {
  check(Pattern pattern, String noteMessage, String todo) {
    if (!source.contains(pattern)) return;
    note("${bold(path)} $noteMessage.");
    if (todos != null) todos.add(todo);
  }

  check(_unittestPattern, "uses the unittest package", "Migrate off unittest.");
  check(_checkedPattern, 'mentions "checked"',
      'Fix code that mentions "checked" mode.');
  check(_abstractErrorPattern, 'mentions "AbstractClassInstantiationError"',
      "Remove code that checks for AbstractClassInstantiationError.");
  check(_typeErrorPattern, 'mentions "TypeError"',
      "Ensure code that checks for a TypeError uses 2.0 semantics.");
}
