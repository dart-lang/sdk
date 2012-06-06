// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * BaseMatcher is the base class for all matchers. To implement a new
 * matcher, either add a class that implements from IMatcher or
 * a class that inherits from Matcher. Inheriting from Matcher has
 * the benefit that a default implementation of describeMismatch will
 * be provided.
 */

class BaseMatcher implements Matcher {
  const BaseMatcher();

  /**
   * Tests the matcher against a given [item]
   * and return true if the match succeeds; false otherwise.
   */
  abstract bool matches(item);

  /**
   * Creates a textual description of a matcher,
   * by appending to [mismatchDescription].
   */
  abstract Description describe(Description mismatchDescription);

  /**
   * Generates a description of the matcher failed for a particular
   * [item], by appending the description to [mismatchDescription].
   * It does not check whether the [item] fails the match, as it is
   * only called after a failed match.
   */
  Description describeMismatch(item, Description mismatchDescription) =>
    mismatchDescription.add('was ').addDescriptionOf(item);
}
