// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.diagnostics.invariant;

import 'spannable.dart';

/**
 * If true, print a warning for each method that was resolved, but not
 * compiled.
 */
const bool REPORT_EXCESS_RESOLUTION = false;

/// Flag that can be used in assertions to assert that a code path is only
/// executed as part of development.
///
/// This flag is automatically set to true if helper methods like, [debugPrint],
/// [debugWrapPrint], [trace], and [reportHere] are called.
bool DEBUG_MODE = false;

/// Assert that [DEBUG_MODE] is `true` and provide [message] as part of the
/// error message.
assertDebugMode(String message) {
  assert(DEBUG_MODE,
      failedAt(NO_LOCATION_SPANNABLE, 'Debug mode is not enabled: $message'));
}

/**
 * Throws a [SpannableAssertionFailure] if [condition] is
 * [:false:]. [condition] must be either a [:bool:] or a no-arg
 * function returning a [:bool:].
 *
 * Use this method to provide better information for assertion by calling
 * [invariant] as the argument to an [:assert:] statement:
 *
 *     assert(invariant(position, isValid));
 *
 * [spannable] must be non-null and will be used to provide positional
 * information in the generated error message.
 */
bool invariant(Spannable spannable, var condition, {var message: null}) {
  // TODO(johnniwinther): Use [spannable] and [message] to provide better
  // information on assertion errors.
  if (spannable == null) {
    throw new SpannableAssertionFailure(CURRENT_ELEMENT_SPANNABLE,
        'Spannable was null for invariant. Use CURRENT_ELEMENT_SPANNABLE.');
  }
  if (condition is Function) {
    condition = condition();
    if (condition is String) {
      message = condition;
      condition = false;
    }
  }
  if (!condition) {
    if (message is Function) {
      message = message();
    }
    throw new SpannableAssertionFailure(spannable, message);
  }
  return true;
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
bool failedAt(Spannable spannable, [var message]) {
  // TODO(johnniwinther): Use [spannable] and [message] to provide better
  // information on assertion errors.
  if (spannable == null) {
    throw new SpannableAssertionFailure(
        CURRENT_ELEMENT_SPANNABLE,
        'Spannable was null for failedInvariant. '
        'Use CURRENT_ELEMENT_SPANNABLE.');
  }
  if (message is Function) {
    message = message();
  }
  throw new SpannableAssertionFailure(spannable, message);
}

typedef void InternalErrorFunction(Spannable location, String message);
