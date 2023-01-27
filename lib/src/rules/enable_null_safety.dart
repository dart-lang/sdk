// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Do use sound null safety.';

const _details = r'''
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

class EnableNullSafety extends LintRule implements NodeLintRule {
  static const LintCode code = LintCode(
      'enable_null_safety', 'Use sound null safety.',
      correctionMessage:
          "Try specifying a dart version greater than or equal to '2.12'.");

  EnableNullSafety()
      : super(
            name: 'enable_null_safety',
            description: _desc,
            details: _details,
            state: State.removed(since: dart2_12),
            group: Group.style);

  @override
  LintCode get lintCode => code;
}
