// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Prefer using a boolean as the assert condition.';

const _details = r'''
NOTE: This rule is removed in Dart 3.0.0; it is no longer functional.

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
  PreferBoolInAsserts()
      : super(
            name: 'prefer_bool_in_asserts',
            description: _desc,
            details: _details,
            state: State.removed(since: dart3),
            categories: {LintRuleCategory.style});

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
