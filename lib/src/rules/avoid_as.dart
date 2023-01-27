// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Avoid using `as`.';

const _details = r'''
**AVOID** using `as`.

If you know the type is correct, use an assertion or assign to a more
narrowly-typed variable (this avoids the type check in release mode; `as` is not
compiled out in release mode).  If you don't know whether the type is
correct, check using `is` (this avoids the exception that `as` raises).

**BAD:**
```dart
(pm as Person).firstName = 'Seth';
```

**GOOD:**
```dart
if (pm is Person)
  pm.firstName = 'Seth';
```

but certainly not

**BAD:**
```dart
try {
   (pm as Person).firstName = 'Seth';
} on CastError { }
```

Note that an exception is made in the case of `dynamic` since the cast has no
performance impact.

**OK:**
```dart
HasScrollDirection scrollable = renderObject as dynamic;
```
''';

class AvoidAs extends LintRule {
  static const LintCode code = LintCode('avoid_as', "Unnecessary use of 'as'.",
      correctionMessage: "Try adding an explicit type check ('is').");

  AvoidAs()
      : super(
          name: 'avoid_as',
          description: _desc,
          details: _details,
          group: Group.style,
          state: State.removed(since: dart2_12),
        );

  @override
  LintCode get lintCode => code;
}
