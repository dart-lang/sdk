// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Specify `@required` on named parameters without defaults.';

const _details = r'''
NOTE: This rule is removed in Dart 3.3.0; it is no longer functional.

**DO** specify `@required` on named parameters without a default value on which 
an `assert(param != null)` is done.

**BAD:**
```dart
m1({a}) {
  assert(a != null);
}
```

**GOOD:**
```dart
m1({@required a}) {
  assert(a != null);
}

m2({a: 1}) {
  assert(a != null);
}
```

NOTE: Only asserts at the start of the bodies will be taken into account.

''';

class AlwaysRequireNonNullNamedParameters extends LintRule {
  static const LintCode code = LintCode(
    'always_require_non_null_named_parameters',
    'Named parameters without a default value should be annotated with '
        "'@required'.",
    correctionMessage: "Try adding the '@required' annotation.",
  );

  AlwaysRequireNonNullNamedParameters()
      : super(
            name: 'always_require_non_null_named_parameters',
            description: _desc,
            details: _details,
            state: State.removed(since: dart3_3),
            categories: {LintRuleCategory.style});

  @override
  LintCode get lintCode => code;
}
