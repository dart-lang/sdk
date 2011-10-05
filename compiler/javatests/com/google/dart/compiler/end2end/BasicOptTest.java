// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.end2end;

import java.util.List;

/**
 * Optimized version of {@link BasicTest}.
 */
public class BasicOptTest extends BasicTest {

  protected void runTest(List<String> srcs) throws Exception {
    runTest(srcs, OptimizationLevel.APP);
  }
}
