// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Base functionality which code generated summary classes are built upon.
 */
library analyzer.src.summary.base;

/**
 * Instances of this class encapsulate the necessary state to keep track of a
 * serialized summary that is in the process of being built.
 *
 * This class is intended to be passed to the constructors of the summary
 * Builder classes.
 */
class BuilderContext {
  // Note: at the moment this is a placeholder class since the current
  // serialization format (JSON) doesn't require any state tracking.  If/when
  // we switch to a serialization format that requires state tracking, the
  // state will be stored here.
}

/**
 * Instances of this class represent data that has been read from a summary.
 */
abstract class SummaryClass {
  /**
   * Translate the data in this class into a map whose keys are the names of
   * fields and whose values are the data stored in those fields.
   *
   * Intended for testing and debugging only.
   */
  Map<String, Object> toMap();
}
