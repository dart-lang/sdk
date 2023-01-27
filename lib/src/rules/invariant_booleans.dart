// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc =
    r'Conditions should not unconditionally evaluate to `true` or to `false`.';

const _details = r'''
**DON'T** test for conditions that can be inferred at compile time or test the
same condition twice.

Conditional statements using a condition which cannot be anything but `false`
have the effect of making blocks of code non-functional.  If the condition
cannot evaluate to anything but `true`, the conditional statement is completely
redundant, and makes the code less readable.
It is quite likely that the code does not match the programmer's intent.
Either the condition should be removed or it should be updated so that it does
not always evaluate to `true` or `false` and does not perform redundant tests.
This rule will hint to the test conflicting with the linted one.

**BAD:**
```dart
// foo can't be both equal and not equal to bar in the same expression
if(foo == bar && something && foo != bar) {...}
```

**BAD:**
```dart
void compute(int foo) {
  if (foo == 4) {
    doSomething();
    // we know foo is equal to 4 at this point, so the next condition is always false
    if (foo > 4) {...}
    ...
  }
  ...
}
```

**BAD:**
```dart
void compute(bool foo) {
  if (foo) {
    return;
  }
  doSomething();
  // foo is always false here
  if (foo){...}
  ...
}
```

**GOOD:**
```dart
void nestedOK() {
  if (foo == bar) {
    foo = baz;
    if (foo != bar) {...}
  }
}
```

**GOOD:**
```dart
void nestedOk2() {
  if (foo == bar) {
    return;
  }

  foo = baz;
  if (foo == bar) {...} // OK
}
```

**GOOD:**
```dart
void nestedOk5() {
  if (foo != null) {
    if (bar != null) {
      return;
    }
  }

  if (bar != null) {...} // OK
}
```

''';

class InvariantBooleans extends LintRule {
  static const LintCode code = LintCode(
      'invariant_booleans', 'Condition always evaluates to the same value.',
      correctionMessage:
          'Try removing the condition or changing it to not produce the same '
          'result.');

  InvariantBooleans()
      : super(
            name: 'invariant_booleans',
            description: _desc,
            details: _details,
            // todo(pq): remove `since` once analyzer 5.5.0 is published and can
            // be unspecified.
            state: State.removed(since: dart3),
            group: Group.errors);

  @override
  LintCode get lintCode => code;
}
