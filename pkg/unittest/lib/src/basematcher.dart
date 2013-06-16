// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of matcher;

/**
 * BaseMatcher is the base class for all matchers. To implement a new
 * matcher, either add a class that implements Matcher or a class that
 * extends BaseMatcher. Extending BaseMatcher has the benefit that a
 * default implementation of describeMismatch will be provided.
 */
abstract class BaseMatcher implements Matcher {
  const BaseMatcher();

  /**
   * Tests the matcher against a given [item]
   * and return true if the match succeeds; false otherwise.
   * [matchState] may be used to return additional info for
   * the use of [describeMismatch].
   */
  bool matches(item, Map matchState);

  /**
   * Creates a textual description of a matcher,
   * by appending to [mismatchDescription].
   */
  Description describe(Description mismatchDescription);

  /**
   * Generates a description of the matcher failed for a particular
   * [item], by appending the description to [mismatchDescription].
   * It does not check whether the [item] fails the match, as it is
   * only called after a failed match. There may be additional info
   * about the mismatch in [matchState].
   * The base matcher does not add anything as the actual value is
   * typically sufficient, but matchers that can add valuable info
   * should override this.
   */
  Description describeMismatch(item, Description mismatchDescription,
                               Map matchState, bool verbose) =>
    mismatchDescription;
}
