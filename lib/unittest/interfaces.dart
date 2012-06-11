// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// To decouple the reporting of errors, and allow for extensibility of
// matchers, we make use of some interfaces.

/**
 * The ErrorFormatter type is used for functions that
 * can be used to build up error reports upon [expect] failures.
 * There is one built-in implementation ([defaultErrorFormatter])
 * which is used by the default failure handler. If the failure handler
 * is replaced it may be desirable to replace the [stringDescription]
 * error formatter with another.
 */
typedef String ErrorFormatter(actual, Matcher matcher, String reason);

/**
 * Matchers build up their error messages by appending to
 * Description objects. This interface is implemented by
 * StringDescription. This interface is unlikely to need
 * other implementations, but could be useful to replace in
 * some cases - e.g. language conversion.
 */
interface Description {
  /** This is used to add arbitrary text to the description. */
  Description add(String text);

  /** This is used to add a meaningful description of a value. */
  Description addDescriptionOf(value);

  /**
   * This is used to add a description of an [Iterable] [list],
   * with appropriate [start] and [end] markers and inter-element [separator].
   */
  Description addAll(String start, String separator, String end,
                       Iterable list);
}

/**
 * [expect] Matchers must implement the Matcher interface.
 * The base Matcher class that implements this interface has
 * a generic implementation of [describeMismatch] so this does
 * not need to be provided unless a more clear description is
 * required. The other two methods ([matches] and [describe])
 * must always be provided as they are highly matcher-specific.
 */
interface Matcher {
  /** This does the matching of the actual vs expected values. */
  bool matches(item);

  /** This builds a textual description of the matcher. */
  Description describe(Description description);

  /**This builds a textual description of a specific mismatch. */
  Description describeMismatch(item, Description mismatchDescription);
}

/**
 * Failed matches are reported using a default IFailureHandler.
 * The default implementation simply throws ExpectExceptions;
 * this can be replaced by some other implementation of
 * IFailureHandler by calling configureExpectHandler.
 */
interface FailureHandler {
  /** This handles failures given a textual decription */
  void fail(String reason);

  /**
   * This handles failures given the actual [value], the [matcher]
   * and the [reason]. It will typically use these to create a
   * detailed error message (typically using an [ErrorFormatter])
   * and then call [fail].
   */
  void failMatch(actual, Matcher matcher, String reason);
}

