// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Avoid returning null for Future.';

const _details = r'''
NOTE: This rule is removed in Dart 3.3.0; it is no longer functional.

**AVOID** returning null for Future.

It is almost always wrong to return `null` for a `Future`.  Most of the time the
developer simply forgot to put an `async` keyword on the function.
''';

class AvoidReturningNullForFuture extends LintRule {
  static const LintCode code = LintCode('avoid_returning_null_for_future',
      "Don't return 'null' when the return type is 'Future'.",
      correctionMessage:
          "Try making the function 'async', or returning 'Future.value(null)'.");

  AvoidReturningNullForFuture()
      : super(
            name: 'avoid_returning_null_for_future',
            description: _desc,
            details: _details,
            state: State.removed(since: dart3_3),
            group: Group.errors);

  @override
  LintCode get lintCode => code;
}
