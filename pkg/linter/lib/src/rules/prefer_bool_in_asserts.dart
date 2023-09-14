// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Prefer using a boolean as the assert condition.';

const _details = r'''
**DO** use a boolean for assert conditions.

Not using booleans in assert conditions can lead to code where it isn't clear
what the intention of the assert statement is.

**BAD:**
```dart
assert(() {
  f();
  return true;
});
```

**GOOD:**
```dart
assert(() {
  f();
  return true;
}());
```
''';

class PreferBoolInAsserts extends LintRule {
  static const LintCode code = LintCode('prefer_bool_in_asserts',
      "Use an expression that returns a 'bool' as the 'assert' condition.",
      correctionMessage:
          "Try rewriting the 'assert' condition to return a 'bool'.");

  PreferBoolInAsserts()
      : super(
            name: 'prefer_bool_in_asserts',
            description: _desc,
            details: _details,
            state: State.removed(since: dart3),
            group: Group.style);

  @override
  LintCode get lintCode => code;
}
