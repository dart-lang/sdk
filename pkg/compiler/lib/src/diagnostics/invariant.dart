// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import 'spannable.dart';

/// Flag that can be used in assertions to assert that a code path is only
/// executed as part of development.
///
/// This flag is automatically set to true if helper methods like, [debugPrint],
/// [debugWrapPrint], [trace], and [reportHere] are called.
bool debugMode = false;

/// Assert that [debugMode] is `true` and provide [message] as part of the
/// error message.
void assertDebugMode(String message) {
  assert(
    debugMode,
    failedAt(noLocationSpannable, 'Debug mode is not enabled: $message'),
  );
}

/// Throws a [SpannableAssertionFailure].
///
/// Use this method to provide better information for assertion by calling
/// [failedAt] as the second argument to an `assert` statement:
///
///     assert(condition, failedAt(position, message));
///
/// [spannable] must be non-null and will be used to provide positional
/// information in the generated error message.
///
/// This method can also be used to throw a [SpannableAssertionFailure] outside
/// an assert:
///
///     failedAt(position, message);
///
Never failedAt(Spannable spannable, [String? message]) {
  throw SpannableAssertionFailure(spannable, message);
}
