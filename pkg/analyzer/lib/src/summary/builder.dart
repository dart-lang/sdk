// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Format-agnostic infrastructure for building summary objects.
 */
library analyzer.src.summary.builder;

import 'dart:convert';

/**
 * Instances of this class encapsulate the necessary state to keep track of a
 * serialized summary that is in the process of being built.
 *
 * This class is intended to be passed to the constructors of the summary
 * Builder classes.
 */
class BuilderContext {
  /**
   * Finalize the serialized object represented by [ref] and return it in
   * serialized form as a buffer.
   */
  List<int> getBuffer(Object ref) {
    return JSON.encode(ref).codeUnits;
  }
}
