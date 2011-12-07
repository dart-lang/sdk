// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

/**
 * Tests for binary expression optimizations.
 */
public abstract class ExprOptTest extends SnippetTestCase {

  private JavascriptBackend jsBackend = new JavascriptBackend() {
    @Override
    protected boolean shouldOptimize() {
      // We're testing the optimizer here, so turn it on explicitly.
      return true;
    }
  };

  @Override
  protected AbstractJsBackend getBackend() {
    return jsBackend;
  }

  @Override
  protected void tearDown() throws Exception {
    jsBackend = null;
    super.tearDown();
  }
}
