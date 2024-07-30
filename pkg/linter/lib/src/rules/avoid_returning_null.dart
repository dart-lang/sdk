// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc =
    r'Avoid returning null from members whose return type is bool, double, int,'
    r' or num.';

const _details = r'''
NOTE: This rule is removed in Dart 3.3.0; it is no longer functional.

**AVOID** returning null from members whose return type is bool, double, int,
or num.

Functions that return primitive types such as bool, double, int, and num are
generally expected to return non-nullable values.  Thus, returning null where a
primitive type was expected can lead to runtime exceptions.

**BAD:**
```dart
bool getBool() => null;
num getNum() => null;
int getInt() => null;
double getDouble() => null;
```

**GOOD:**
```dart
bool getBool() => false;
num getNum() => -1;
int getInt() => -1;
double getDouble() => -1.0;
```

''';

class AvoidReturningNull extends LintRule {
  static const LintCode code = LintCode(
      'avoid_returning_null',
      "Don't return 'null' when the return type is 'bool', 'double', 'int', "
          "or 'num'.",
      correctionMessage: "Try returning a sentinel value other than 'null'.");

  AvoidReturningNull()
      : super(
            name: 'avoid_returning_null',
            description: _desc,
            details: _details,
            state: State.removed(since: dart3_3),
            categories: {Category.style});

  @override
  LintCode get lintCode => code;
}
