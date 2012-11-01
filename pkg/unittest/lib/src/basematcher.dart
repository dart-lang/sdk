// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of matcher;

/**
 * MatchState is a simple wrapper around an arbitrary object.
 * [Matcher] [matches] methods can use this to store useful
 * information upon match failures, and this information will
 * be passed to [describeMismatch]. Each [Matcher] is responsible
 * for its own use of this state, so the state created by [matches]
 * should be consistent with that expected by [describeMismatch] in
 * the same [Matcher] class, but can vary between classes. The inner
 * state, if set, will typically be a [Map] with a number of key-value
 * pairs containing relevant state information.
 */
class MatchState {
  var state = null;

  MatchState([this.state]);
}

/**
 * BaseMatcher is the base class for all matchers. To implement a new
 * matcher, either add a class that implements from IMatcher or
 * a class that inherits from Matcher. Inheriting from Matcher has
 * the benefit that a default implementation of describeMismatch will
 * be provided.
 */
abstract class BaseMatcher implements Matcher {
  const BaseMatcher();

  /**
   * Tests the matcher against a given [item]
   * and return true if the match succeeds; false otherwise.
   * [matchState] may be used to return additional info for
   * the use of [describeMismatch].
   */
  bool matches(item, MatchState matchState);

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
   */
  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) =>
    mismatchDescription.add('was ').addDescriptionOf(item);
}
