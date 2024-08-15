// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Do use sound null safety.';

const _details = r'''
NOTE: This rule is removed in Dart 3.0.0; it is no longer functional.

**DO** use sound null safety, by not specifying a dart version lower than `2.12`.

**BAD:**
```dart
// @dart=2.8
a() {
}
```

**GOOD:**
```dart
b() {
}
```

''';

class EnableNullSafety extends LintRule {
  EnableNullSafety()
      : super(
            name: 'enable_null_safety',
            description: _desc,
            details: _details,
            state: State.removed(since: dart3),
            categories: {LintRuleCategory.style});

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
